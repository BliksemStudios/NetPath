import AppKit
import Carbon.HIToolbox

@MainActor
final class HotkeyService: ObservableObject {
    static let shared = HotkeyService()

    @Published var isRegistered = false

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var hotKeyRef: EventHotKeyRef?
    private var lastSessionHotKeyRef: EventHotKeyRef?

    var onHotkeyPressed: (() -> Void)?
    var onLastSessionPressed: (() -> Void)?

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

        // Carbon hotkeys — work globally without Accessibility permission
        registerCarbonHotkeys()

        // Local NSEvent monitor for when app has focus
        let expectedKey = keyCode
        let expectedMods = modifierFlags.intersection(.deviceIndependentFlagsMask)

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if event.keyCode == expectedKey && mods == expectedMods {
                Task { @MainActor in self?.onHotkeyPressed?() }
                return nil
            }
            // ⌘⇧L for last session (keyCode 37 = L)
            if event.keyCode == 37 && mods == [.command, .shift] {
                Task { @MainActor in self?.onLastSessionPressed?() }
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
        unregisterCarbonHotkeys()
        isRegistered = false
    }

    func updateHotkey(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        UserDefaults.standard.set(Int(keyCode), forKey: AppConstants.UserDefaultsKeys.hotkeyKeyCode)
        UserDefaults.standard.set(Int(modifiers.rawValue), forKey: AppConstants.UserDefaultsKeys.hotkeyModifiers)
        register()
    }

    // MARK: - Carbon Hot Keys

    private func registerCarbonHotkeys() {
        // Hotkey 1: Open launcher (⌘⇧\)
        let launcherID = EventHotKeyID(signature: OSType(0x4E505448), id: 1) // "NPTH" id:1
        var ref1: EventHotKeyRef?
        let status1 = RegisterEventHotKey(
            UInt32(keyCode),
            carbonModifiers(from: modifierFlags),
            launcherID,
            GetApplicationEventTarget(), 0, &ref1)
        if status1 == noErr { hotKeyRef = ref1 }

        // Hotkey 2: Open last session (⌘⇧L)
        let lastSessionID = EventHotKeyID(signature: OSType(0x4E505448), id: 2) // "NPTH" id:2
        var ref2: EventHotKeyRef?
        let status2 = RegisterEventHotKey(
            UInt32(37), // keyCode for L
            UInt32(cmdKey | shiftKey),
            lastSessionID,
            GetApplicationEventTarget(), 0, &ref2)
        if status2 == noErr { lastSessionHotKeyRef = ref2 }

        if status1 == noErr || status2 == noErr {
            installCarbonHandler()
        }
    }

    private func unregisterCarbonHotkeys() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let ref = lastSessionHotKeyRef {
            UnregisterEventHotKey(ref)
            lastSessionHotKeyRef = nil
        }
    }

    private func installCarbonHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))

        HotkeyService._sharedInstance = self

        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ -> OSStatus in
            var hotKeyID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID),
                              nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)

            Task { @MainActor in
                switch hotKeyID.id {
                case 1: HotkeyService._sharedInstance?.onHotkeyPressed?()
                case 2: HotkeyService._sharedInstance?.onLastSessionPressed?()
                default: break
                }
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
