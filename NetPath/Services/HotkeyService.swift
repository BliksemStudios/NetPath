import AppKit
import Carbon.HIToolbox

@MainActor
final class HotkeyService: ObservableObject {
    static let shared = HotkeyService()

    @Published var isRegistered = false

    private var globalMonitor: Any?
    private var localMonitor: Any?

    var onHotkeyPressed: (() -> Void)?

    private var keyCode: UInt16 {
        UInt16(UserDefaults.standard.integer(forKey: AppConstants.UserDefaultsKeys.hotkeyKeyCode))
            .nonZero ?? AppConstants.Defaults.hotkeyKeyCode
    }

    private var modifierFlags: NSEvent.ModifierFlags {
        let raw = UserDefaults.standard.integer(forKey: AppConstants.UserDefaultsKeys.hotkeyModifiers)
        if raw == 0 { return AppConstants.Defaults.hotkeyModifiers }
        return NSEvent.ModifierFlags(rawValue: UInt(raw))
    }

    private init() {}

    func register() {
        unregister()

        let expectedKey = keyCode
        let expectedMods = modifierFlags.intersection(.deviceIndependentFlagsMask)

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == expectedKey &&
               event.modifierFlags.intersection(.deviceIndependentFlagsMask) == expectedMods {
                Task { @MainActor in
                    self?.onHotkeyPressed?()
                }
            }
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == expectedKey &&
               event.modifierFlags.intersection(.deviceIndependentFlagsMask) == expectedMods {
                Task { @MainActor in
                    self?.onHotkeyPressed?()
                }
                return nil
            }
            return event
        }

        isRegistered = true
    }

    func unregister() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        isRegistered = false
    }

    func updateHotkey(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        UserDefaults.standard.set(Int(keyCode), forKey: AppConstants.UserDefaultsKeys.hotkeyKeyCode)
        UserDefaults.standard.set(Int(modifiers.rawValue), forKey: AppConstants.UserDefaultsKeys.hotkeyModifiers)
        register()
    }
}

private extension UInt16 {
    var nonZero: UInt16? {
        self == 0 ? nil : self
    }
}
