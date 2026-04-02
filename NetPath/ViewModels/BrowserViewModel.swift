import SwiftUI
import SwiftData

enum ViewMode: String, Sendable {
    case list, grid
}

enum SortField: String, CaseIterable, Sendable {
    case name, dateModified, size, kind
}

struct Breadcrumb: Identifiable {
    let id = UUID()
    let label: String
    let path: UNCPath
}

@MainActor
@Observable
final class BrowserViewModel {
    var currentPath: UNCPath
    var items: [FileItem] = []
    var addressBarText: String
    var viewMode: ViewMode = .list
    var sortBy: SortField = .name
    var sortAscending: Bool = true
    var isLoading = false
    var errorMessage: String?
    var connectedAs: String = ""

    private(set) var canGoBack = false
    private(set) var canGoForward = false

    private var mountPoint: String
    private var navigationHistory: [UNCPath] = []
    private var historyIndex = -1
    private let fileService = FileSystemService()
    private let modelContext: ModelContext

    var breadcrumbs: [Breadcrumb] {
        var crumbs: [Breadcrumb] = []
        let serverPath = UNCPath(server: currentPath.server, share: nil, components: [])
        crumbs.append(Breadcrumb(label: currentPath.server, path: serverPath))
        if let share = currentPath.share {
            let sharePath = UNCPath(server: currentPath.server, share: share, components: [])
            crumbs.append(Breadcrumb(label: share, path: sharePath))
            for (i, comp) in currentPath.components.enumerated() {
                let compPath = UNCPath(
                    server: currentPath.server,
                    share: share,
                    components: Array(currentPath.components.prefix(i + 1))
                )
                crumbs.append(Breadcrumb(label: comp, path: compPath))
            }
        }
        return crumbs
    }

    /// Builds the folder tree for the sidebar — shows the path hierarchy
    /// from the share root down to the current location, plus sibling folders
    var sidebarFolders: [SidebarFolder] {
        guard let share = currentPath.share else { return [] }
        var folders: [SidebarFolder] = []

        // Share root
        let sharePath = UNCPath(server: currentPath.server, share: share, components: [])
        folders.append(SidebarFolder(name: share, uncPath: sharePath, depth: 0,
                                      isExpanded: !currentPath.components.isEmpty))

        // Each component in the current path
        for (i, comp) in currentPath.components.enumerated() {
            let compPath = UNCPath(server: currentPath.server, share: share,
                                    components: Array(currentPath.components.prefix(i + 1)))
            let isLast = i == currentPath.components.count - 1
            folders.append(SidebarFolder(name: comp, uncPath: compPath, depth: i + 1,
                                          isExpanded: !isLast))
        }

        // Current directory's subfolders
        let subFolders = items.filter(\.isDirectory).sorted { a, b in
            a.name.localizedStandardCompare(b.name) == .orderedAscending
        }
        let subDepth = currentPath.components.count + 1
        for sub in subFolders {
            let subPath = currentPath.appending(component: sub.name)
            folders.append(SidebarFolder(name: sub.name, uncPath: subPath, depth: subDepth,
                                          isExpanded: false))
        }

        return folders
    }

    var sortedItems: [FileItem] {
        items.sorted { a, b in
            if a.isDirectory != b.isDirectory { return a.isDirectory }
            let result: Bool
            switch sortBy {
            case .name:
                result = a.name.localizedStandardCompare(b.name) == .orderedAscending
            case .dateModified:
                result = (a.dateModified ?? .distantPast) > (b.dateModified ?? .distantPast)
            case .size:
                result = (a.size ?? 0) < (b.size ?? 0)
            case .kind:
                result = a.kindDescription.localizedStandardCompare(b.kindDescription) == .orderedAscending
            }
            return sortAscending ? result : !result
        }
    }

    init(mountPoint: String, uncPath: UNCPath, modelContext: ModelContext) {
        self.mountPoint = mountPoint
        self.currentPath = uncPath
        self.addressBarText = uncPath.uncString
        self.modelContext = modelContext
        pushHistory(uncPath)
        loadDirectory()
    }

    func navigateTo(path: UNCPath) {
        if historyIndex < navigationHistory.count - 1 {
            navigationHistory = Array(navigationHistory.prefix(historyIndex + 1))
        }
        pushHistory(path)
        currentPath = path
        addressBarText = path.uncString
        loadDirectory()
    }

    func navigateToAddressBar() {
        guard let path = UNCPath(from: addressBarText) else {
            errorMessage = "Invalid path"
            return
        }
        navigateTo(path: path)
    }

    func navigateIntoFolder(_ item: FileItem) {
        guard item.isDirectory else { return }
        let child = currentPath.appending(component: item.name)
        navigateTo(path: child)
    }

    func goBack() {
        guard canGoBack else { return }
        historyIndex -= 1
        let path = navigationHistory[historyIndex]
        currentPath = path
        addressBarText = path.uncString
        updateNavState()
        loadDirectory()
    }

    func goForward() {
        guard canGoForward else { return }
        historyIndex += 1
        let path = navigationHistory[historyIndex]
        currentPath = path
        addressBarText = path.uncString
        updateNavState()
        loadDirectory()
    }

    func goUp() {
        guard let parent = currentPath.parentPath else { return }
        navigateTo(path: parent)
    }

    func toggleViewMode() {
        viewMode = viewMode == .list ? .grid : .list
    }

    func toggleSort(_ field: SortField) {
        if sortBy == field {
            sortAscending.toggle()
        } else {
            sortBy = field
            sortAscending = true
        }
    }

    func openFile(_ item: FileItem) {
        NSWorkspace.shared.open(item.path)
    }

    func copyUNCPath(_ item: FileItem) {
        let itemPath = currentPath.appending(component: item.name)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(itemPath.uncString, forType: .string)
    }

    func copySMBURL(_ item: FileItem) {
        let itemPath = currentPath.appending(component: item.name)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(itemPath.smbURL.absoluteString, forType: .string)
    }

    func revealInFinder(_ item: FileItem) {
        NSWorkspace.shared.activateFileViewerSelecting([item.path])
    }

    func openWith(_ item: FileItem) {
        // Open the "Open With" panel via NSWorkspace
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.prompt = "Open With"
        if panel.runModal() == .OK, let appURL = panel.url {
            NSWorkspace.shared.open([item.path], withApplicationAt: appURL,
                                     configuration: NSWorkspace.OpenConfiguration())
        }
    }

    func getFileInfo(_ item: FileItem) {
        // Use NSWorkspace to show the Finder Get Info window
        NSWorkspace.shared.activateFileViewerSelecting([item.path])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let source = """
            tell application "Finder"
                activate
                open information window of (POSIX file "\(item.path.path)" as alias)
            end tell
            """
            var error: NSDictionary?
            NSAppleScript(source: source)?.executeAndReturnError(&error)
        }
    }

    func copyFileName(_ item: FileItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.name, forType: .string)
    }

    func copyRelativePath(_ item: FileItem) {
        let relative = currentPath.components.joined(separator: "\\") +
            (currentPath.components.isEmpty ? "" : "\\") + item.name
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(relative, forType: .string)
    }

    func moveToTrash(_ item: FileItem) {
        do {
            try FileManager.default.trashItem(at: item.path, resultingItemURL: nil)
            loadDirectory()
        } catch {
            errorMessage = "Could not move to trash: \(error.localizedDescription)"
        }
    }

    func newFolder() {
        var localPath = URL(fileURLWithPath: mountPoint)
        for component in currentPath.components {
            localPath.appendPathComponent(component)
        }
        let newFolderURL = localPath.appendingPathComponent("untitled folder")
        do {
            try FileManager.default.createDirectory(at: newFolderURL, withIntermediateDirectories: false)
            loadDirectory()
        } catch {
            errorMessage = "Could not create folder: \(error.localizedDescription)"
        }
    }

    func copyFileToClipboard(_ item: FileItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([item.path as NSURL])
    }

    func pasteFromClipboard() {
        guard let urls = NSPasteboard.general.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
              !urls.isEmpty else { return }

        var localPath = URL(fileURLWithPath: mountPoint)
        for component in currentPath.components {
            localPath.appendPathComponent(component)
        }

        for sourceURL in urls {
            let destURL = localPath.appendingPathComponent(sourceURL.lastPathComponent)
            do {
                try FileManager.default.copyItem(at: sourceURL, to: destURL)
            } catch {
                errorMessage = "Paste failed: \(error.localizedDescription)"
                return
            }
        }
        loadDirectory()
    }

    var canPaste: Bool {
        guard let types = NSPasteboard.general.types else { return false }
        return types.contains(.fileURL)
    }

    func openCurrentDirectoryInFinder() {
        var localPath = URL(fileURLWithPath: mountPoint)
        for component in currentPath.components {
            localPath.appendPathComponent(component)
        }
        NSWorkspace.shared.open(localPath)
    }

    func refresh() {
        loadDirectory()
    }

    func copyCurrentDirectoryUNC() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(currentPath.uncString, forType: .string)
    }

    private func pushHistory(_ path: UNCPath) {
        navigationHistory.append(path)
        historyIndex = navigationHistory.count - 1
        updateNavState()
    }

    private func updateNavState() {
        canGoBack = historyIndex > 0
        canGoForward = historyIndex < navigationHistory.count - 1
    }

    private func loadDirectory() {
        isLoading = true
        errorMessage = nil

        var localPath = URL(fileURLWithPath: mountPoint)
        for component in currentPath.components {
            localPath.appendPathComponent(component)
        }

        let settings = AppSettings.fetch(from: modelContext)
        let showHidden = settings.showHiddenFiles

        do {
            items = try fileService.listDirectory(at: localPath, showHidden: showHidden)
            isLoading = false
        } catch {
            items = []
            errorMessage = "Could not read directory: \(error.localizedDescription)"
            isLoading = false
        }
    }
}
