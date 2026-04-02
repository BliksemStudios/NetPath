import AppKit
import SwiftUI
import SwiftData

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var launcherPanel: LauncherPanel?
    private let hotkeyService = HotkeyService.shared
    private var browserWindows: [NSWindow] = []

    var modelContainer: ModelContainer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupHotkey()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyService.unregister()
    }

    // MARK: - Status Bar

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "externaldrive.connected.to.line.below",
                                   accessibilityDescription: "NetPath")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open NetPath", action: #selector(showLauncher), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit NetPath", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    // MARK: - Hotkey

    private func setupHotkey() {
        hotkeyService.onHotkeyPressed = { [weak self] in
            self?.toggleLauncher()
        }
        hotkeyService.register()
    }

    // MARK: - Launcher

    @objc func showLauncher() {
        if launcherPanel == nil {
            launcherPanel = LauncherPanel()
        }

        guard let panel = launcherPanel, let container = modelContainer else { return }

        let launcherView = LauncherView(
            onBrowse: { [weak self] mountPoint, path in
                self?.openBrowser(mountPoint: mountPoint, path: path)
            },
            onDismiss: { [weak self] in
                self?.hideLauncher()
            }
        )
        .modelContainer(container)

        panel.contentView = NSHostingView(rootView: launcherView)
        panel.makeKeyAndOrderFront(nil)

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let panelFrame = panel.frame
            let x = screenFrame.midX - panelFrame.width / 2
            let y = screenFrame.midY + 100
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    func hideLauncher() {
        launcherPanel?.close()
    }

    private func toggleLauncher() {
        if launcherPanel?.isVisible == true {
            hideLauncher()
        } else {
            showLauncher()
        }
    }

    // MARK: - Browser Window

    private func openBrowser(mountPoint: String, path: UNCPath) {
        guard let container = modelContainer else { return }

        let viewModel = BrowserViewModel(
            mountPoint: mountPoint,
            uncPath: path,
            modelContext: container.mainContext
        )

        let browserView = BrowserView(viewModel: viewModel)
            .modelContainer(container)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0,
                                width: Design.Browser.minWindowWidth,
                                height: Design.Browser.minWindowHeight),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.contentView = NSHostingView(rootView: browserView)
        window.title = path.displayPath
        window.titlebarAppearsTransparent = false
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: Design.Browser.minWindowWidth,
                                height: Design.Browser.minWindowHeight)
        window.center()
        window.makeKeyAndOrderFront(nil)

        // Activate the app so the window comes to front
        NSApp.activate(ignoringOtherApps: true)

        browserWindows.append(window)
    }

    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
