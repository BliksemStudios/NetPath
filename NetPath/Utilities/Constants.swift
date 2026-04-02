import SwiftUI

enum Design {
    static let electricBlue = Color(red: 0, green: 0.4, blue: 1) // #0066FF

    enum Colors {
        static let accent = Design.electricBlue
        static let connectedGreen = Color(red: 0.3, green: 0.69, blue: 0.31)
        static let errorRed = Color(red: 0.93, green: 0.26, blue: 0.21)
        static let mutedText = Color.secondary
        static let separator = Color(white: 1, opacity: 0.06)
        static let hoverHighlight = Design.electricBlue.opacity(0.08)
        static let selectedHighlight = Design.electricBlue.opacity(0.15)
    }

    enum Fonts {
        static let pathMono = Font.system(size: 14, design: .monospaced)
        static let pathMonoLarge = Font.system(size: 18, design: .monospaced)
        static let pathMonoSmall = Font.system(size: 12, design: .monospaced)
        static let sectionHeader = Font.system(size: 10, weight: .semibold)
        static let statusBar = Font.system(size: 11)
    }

    enum Launcher {
        static let width: CGFloat = 680
        static let cornerRadius: CGFloat = 12
        static let inputPadding: CGFloat = 16
    }

    enum Browser {
        static let sidebarWidth: CGFloat = 200
        static let minWindowWidth: CGFloat = 800
        static let minWindowHeight: CGFloat = 500
        static let addressBarHeight: CGFloat = 44
        static let statusBarHeight: CGFloat = 28
        static let rowHeight: CGFloat = 28
    }

    static let fastSpring = Animation.spring(response: 0.25, dampingFraction: 0.9)
    static let subtleFade = Animation.easeInOut(duration: 0.15)
}

enum AppConstants {
    static let serviceName = "com.bliksem.netpath"
    static let helperMachService = "com.bliksem.netpath.helper"
    static let keychainService = "com.bliksem.netpath"

    enum Defaults {
        static let maxHistoryItems = 100
        static let idleTimeoutMinutes = 30
        static let defaultViewMode = "list"
        static let hotkeyKeyCode: UInt16 = 42 // backslash key
        static let hotkeyModifiers: NSEvent.ModifierFlags = [.command, .shift]
    }

    enum UserDefaultsKeys {
        static let hotkeyKeyCode = "hotkeyKeyCode"
        static let hotkeyModifiers = "hotkeyModifiers"
        static let launchAtLogin = "launchAtLogin"
    }
}
