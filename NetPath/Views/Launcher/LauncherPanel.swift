import AppKit
import SwiftUI

final class LauncherPanel: NSPanel {
    /// Set to true when a sheet or credential prompt is active — prevents auto-dismiss
    var preventDismiss = false

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0,
                                width: Design.Launcher.width, height: 80),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        // Disable the panel's built-in shadow — it draws a rectangular shadow
        // that doesn't respect the SwiftUI rounded clip shape.
        // The shadow is handled by SwiftUI's .shadow() on LauncherView instead.
        hasShadow = false
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        animationBehavior = .utilityWindow

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - Design.Launcher.width / 2
            let y = screenFrame.midY + 100
            setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    override var canBecomeKey: Bool { true }

    override func resignKey() {
        super.resignKey()
        if !preventDismiss {
            close()
        }
    }

    override func cancelOperation(_ sender: Any?) {
        close()
    }
}
