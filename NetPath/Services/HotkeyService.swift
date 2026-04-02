import AppKit
import Carbon.HIToolbox

@MainActor
final class HotkeyService: ObservableObject {
    static let shared = HotkeyService()

    @Published var isRegistered = false

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var hotKeyRef: EventHotKeyRef?

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

        // Try Carbon hotkey first — works without Accessibility permission
        registerCarbonHotkey()

        // Also register NSEvent monitors as fallback for when app has focus
        let expectedKey = keyCode
        let expectedMods = modifierFlags.intersection(.deviceIndependentFlagsMask)

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

        // Global monitor needs Accessibility — register but don't fail if it doesn't work
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == expectedKey &&
               event.modifierFlags.intersection(.deviceIndependentFlagsMask) == expectedMods {
                Task { @MainActor in
                    self?.onHotkeyPressed?()
                }
            }
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
        unregisterCarbonHotkey()
        isRegistered = false
    }

    func updateHotkey(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        UserDefaults.standard.set(Int(keyCode), forKey: AppConstants.UserDefaultsKeys.hotkeyKeyCode)
        UserDefaults.standard.set(Int(modifiers.rawValue), forKey: AppConstants.UserDefaultsKeys.hotkeyModifiers)
        register()
    }

    // MARK: - Carbon Hot Key (works globally without Accessibility permission)

    private func registerCarbonHotkey() {
        let carbonMods = carbonModifiers(from: modifierFlags)
        let hotKeyID = EventHotKeyID(signature: OSType(0x4E505448), // "NPTH"
                                      id: 1)

        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(UInt32(keyCode), carbonMods, hotKeyID,
                                          GetApplicationEventTarget(), 0, &ref)
        if status == noErr {
            hotKeyRef = ref
            installCarbonHandler()
        }
    }

    private func unregisterCarbonHotkey() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }

    private func installCarbonHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))

        // Store self in a global for the C callback
        HotkeyService._sharedInstance = self

        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ -> OSStatus in
            Task { @MainActor in
                HotkeyService._sharedInstance?.onHotkeyPressed?()
            }
            return noErr
        }, 1, &eventType, nil, nil)
    }

    nonisolated(unsafe) private static var _sharedInstance: HotkeyService?

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var mods: UInt32 = 0
        if flags.contains(.command) { mods |= UInt32(cmdKey) }
        if flags.contains(.shift) { mods |= UInt32(shiftKey) }
        if flags.contains(.option) { mods |= UInt32(optionKey) }
        if flags.contains(.control) { mods |= UInt32(controlKey) }
        return mods
    }
}

private extension UInt16 {
    var nonZero: UInt16? {
        self == 0 ? nil : self
    }
}
