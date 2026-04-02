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

    func refresh() {
        loadDirectory()
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
