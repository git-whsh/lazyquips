import Carbon
import Foundation
import Combine

enum HotKeyRegistrationStatus: Equatable {
    case available
    case unavailable
}

final class HotKeyRegistrationStatusStore: ObservableObject {
    @Published private(set) var status: HotKeyRegistrationStatus

    init(status: HotKeyRegistrationStatus = .unavailable) {
        self.status = status
    }

    func update(isAvailable: Bool) {
        status = isAvailable ? .available : .unavailable
    }
}

protocol HotKeyRegistering: AnyObject {
    @discardableResult
    func start() -> Bool

    @discardableResult
    func restart() -> Bool

    func stop()
}

final class HotKeyController: HotKeyRegistering {
    static let shortcutKeyCode = UInt32(kVK_ANSI_C)
    static let shortcutModifiers = UInt32(cmdKey | shiftKey)

    private static let hotKeyID = EventHotKeyID(signature: 0x4C424E53, id: 1)
    private static let eventHandler: EventHandlerUPP = { _, event, userData in
        guard let event, let userData else {
            return noErr
        }

        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        guard status == noErr,
              hotKeyID.signature == HotKeyController.hotKeyID.signature,
              hotKeyID.id == HotKeyController.hotKeyID.id
        else {
            return status
        }

        let controller = Unmanaged<HotKeyController>.fromOpaque(userData).takeUnretainedValue()
        DispatchQueue.main.async {
            controller.onPressed()
        }

        return noErr
    }

    private let onPressed: () -> Void
    private var eventHotKey: EventHotKeyRef?
    private var installedEventHandler: EventHandlerRef?

    init(onPressed: @escaping () -> Void) {
        self.onPressed = onPressed
    }

    @discardableResult
    func start() -> Bool {
        guard eventHotKey == nil else {
            return true
        }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            Self.eventHandler,
            1,
            &eventType,
            userData,
            &installedEventHandler
        )

        guard handlerStatus == noErr else {
            installedEventHandler = nil
            return false
        }

        let hotKeyID = Self.hotKeyID
        let registerStatus = RegisterEventHotKey(
            Self.shortcutKeyCode,
            Self.shortcutModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &eventHotKey
        )

        guard registerStatus == noErr else {
            stop()
            return false
        }

        return true
    }

    @discardableResult
    func restart() -> Bool {
        stop()
        return start()
    }

    func stop() {
        if let eventHotKey {
            UnregisterEventHotKey(eventHotKey)
            self.eventHotKey = nil
        }

        if let installedEventHandler {
            RemoveEventHandler(installedEventHandler)
            self.installedEventHandler = nil
        }
    }

    deinit {
        stop()
    }
}
