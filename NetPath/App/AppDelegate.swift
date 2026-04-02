import AppKit
import SwiftUI
import SwiftData

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var launcherPanel: LauncherPanel?
    private let hotkeyService = HotkeyService.shared
    private var browserWindows: [NSWindow] = []

    private static let lastPathKey = "lastBrowsedPath"

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

        let lastSessionItem = NSMenuItem(title: "Open Last Session", action: #selector(openLastSession), keyEquivalent: "L")
        lastSessionItem.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(lastSessionItem)

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
        hotkeyService.onLastSessionPressed = { [weak self] in
            self?.openLastSession()
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

        // Wrap the hosting view in a container that provides shadow + corner masking.
        // The container draws the shadow (not clipped), the inner view clips corners.
        let hostingView = NSHostingView(rootView: launcherView)

        let containerView = NSView()
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = .clear
        containerView.layer?.shadowColor = NSColor.black.cgColor
        containerView.layer?.shadowOpacity = 0.3
        containerView.layer?.shadowRadius = 20
        containerView.layer?.shadowOffset = CGSize(width: 0, height: -8)

        hostingView.wantsLayer = true
        hostingView.layer?.cornerRadius = Design.Launcher.cornerRadius
        hostingView.layer?.masksToBounds = true

        containerView.addSubview(hostingView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: containerView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        ])

        panel.contentView = containerView
        panel.makeKeyAndOrderFront(nil)

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let panelFrame = panel.frame
            let x = screenFrame.midX - panelFrame.width / 2
            let y = screenFrame.midY + 100
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        NSApp.activate(ignoringOtherApps: true)
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

    // MARK: - Last Session

    @objc private func openLastSession() {
        guard let lastPath = UserDefaults.standard.string(forKey: Self.lastPathKey),
              let path = UNCPath(from: lastPath) else {
            // No last session — just open the launcher
            showLauncher()
            return
        }

        // Connect and open browser
        Task {
            let xpc = XPCClient.shared
            do {
                let result = try await xpc.mount(path: path, username: nil, password: nil)
                openBrowser(mountPoint: result.mountPoint, path: path)
            } catch {
                // Mount failed — open launcher with the path pre-filled
                showLauncher()
                // User will see the launcher and can type/paste the path
            }
        }
    }

    // MARK: - Browser Window

    private func openBrowser(mountPoint: String, path: UNCPath) {
        guard let container = modelContainer else { return }

        // Save as last browsed path
        UserDefaults.standard.set(path.uncString, forKey: Self.lastPathKey)

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
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        let hostingView = NSHostingView(rootView: browserView)
        window.contentView = hostingView
        window.title = path.displayPath
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: Design.Browser.minWindowWidth,
                                height: Design.Browser.minWindowHeight)

        // Ensure content clips to window's rounded corners
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.masksToBounds = true
        window.center()
        window.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)

        browserWindows.append(window)
    }

    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
