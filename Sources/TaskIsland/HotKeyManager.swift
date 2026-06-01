import Carbon
import Foundation

private let taskIslandHotKeySignature = OSType(0x5449534B)
private let taskIslandHotKeyID = UInt32(1)

@MainActor
final class HotKeyManager {
    private let onPressed: @MainActor () -> Void
    private var eventHandlerRef: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?

    init(onPressed: @escaping @MainActor () -> Void) {
        self.onPressed = onPressed
    }

    @discardableResult
    func register(shortcut: TaskIslandShortcut) -> Bool {
        unregister()

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return noErr }

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
                      hotKeyID.signature == taskIslandHotKeySignature,
                      hotKeyID.id == taskIslandHotKeyID
                else {
                    return noErr
                }

                let managerAddress = UInt(bitPattern: userData)
                DispatchQueue.main.async {
                    guard let managerPointer = UnsafeRawPointer(bitPattern: managerAddress) else {
                        return
                    }
                    let manager = Unmanaged<HotKeyManager>
                        .fromOpaque(managerPointer)
                        .takeUnretainedValue()
                    manager.onPressed()
                }

                return noErr
            },
            1,
            &eventType,
            selfPointer,
            &eventHandlerRef
        )

        let hotKeyID = EventHotKeyID(signature: taskIslandHotKeySignature, id: taskIslandHotKeyID)
        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status != noErr {
            unregister()
            return false
        }

        return true
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }

}
