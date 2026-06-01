import Carbon
import Foundation

struct TaskIslandShortcut: Equatable {
    let keyCode: UInt32
    let modifiers: UInt32

    var displayName: String {
        "\(Self.modifierDisplayName(rawValue: Int(modifiers))) + \(Self.keyDisplayName(keyCode: Int(keyCode)))"
    }

    static let defaultQuickAdd = TaskIslandShortcut(
        keyCode: UInt32(kVK_ANSI_N),
        modifiers: UInt32(controlKey | optionKey)
    )

    static let modifierChoices: [ShortcutModifierChoice] = [
        ShortcutModifierChoice(rawValue: Int(optionKey), displayName: "Option"),
        ShortcutModifierChoice(rawValue: Int(controlKey), displayName: "Control"),
        ShortcutModifierChoice(rawValue: Int(controlKey | optionKey), displayName: "Control + Option"),
        ShortcutModifierChoice(rawValue: Int(cmdKey | optionKey), displayName: "Command + Option"),
        ShortcutModifierChoice(rawValue: Int(cmdKey | controlKey), displayName: "Command + Control"),
        ShortcutModifierChoice(rawValue: Int(shiftKey | optionKey), displayName: "Shift + Option"),
        ShortcutModifierChoice(rawValue: Int(shiftKey | cmdKey), displayName: "Shift + Command")
    ]

    static let keyChoices: [ShortcutKeyChoice] = [
        ShortcutKeyChoice(keyCode: Int(kVK_ANSI_A), displayName: "A"),
        ShortcutKeyChoice(keyCode: Int(kVK_ANSI_B), displayName: "B"),
        ShortcutKeyChoice(keyCode: Int(kVK_ANSI_C), displayName: "C"),
        ShortcutKeyChoice(keyCode: Int(kVK_ANSI_D), displayName: "D"),
        ShortcutKeyChoice(keyCode: Int(kVK_ANSI_E), displayName: "E"),
        ShortcutKeyChoice(keyCode: Int(kVK_ANSI_F), displayName: "F"),
        ShortcutKeyChoice(keyCode: Int(kVK_ANSI_G), displayName: "G"),
        ShortcutKeyChoice(keyCode: Int(kVK_ANSI_H), displayName: "H"),
        ShortcutKeyChoice(keyCode: Int(kVK_ANSI_I), displayName: "I"),
        ShortcutKeyChoice(keyCode: Int(kVK_ANSI_J), displayName: "J"),
        ShortcutKeyChoice(keyCode: Int(kVK_ANSI_K), displayName: "K"),
        ShortcutKeyChoice(keyCode: Int(kVK_ANSI_L), displayName: "L"),
        ShortcutKeyChoice(keyCode: Int(kVK_ANSI_M), displayName: "M"),
        ShortcutKeyChoice(keyCode: Int(kVK_ANSI_N), displayName: "N"),
        ShortcutKeyChoice(keyCode: Int(kVK_ANSI_O), displayName: "O"),
        ShortcutKeyChoice(keyCode: Int(kVK_ANSI_P), displayName: "P"),
        ShortcutKeyChoice(keyCode: Int(kVK_ANSI_Q), displayName: "Q"),
        ShortcutKeyChoice(keyCode: Int(kVK_ANSI_R), displayName: "R"),
        ShortcutKeyChoice(keyCode: Int(kVK_ANSI_S), displayName: "S"),
        ShortcutKeyChoice(keyCode: Int(kVK_ANSI_T), displayName: "T"),
        ShortcutKeyChoice(keyCode: Int(kVK_ANSI_U), displayName: "U"),
        ShortcutKeyChoice(keyCode: Int(kVK_ANSI_V), displayName: "V"),
        ShortcutKeyChoice(keyCode: Int(kVK_ANSI_W), displayName: "W"),
        ShortcutKeyChoice(keyCode: Int(kVK_ANSI_X), displayName: "X"),
        ShortcutKeyChoice(keyCode: Int(kVK_ANSI_Y), displayName: "Y"),
        ShortcutKeyChoice(keyCode: Int(kVK_ANSI_Z), displayName: "Z"),
        ShortcutKeyChoice(keyCode: Int(kVK_Space), displayName: "空格")
    ]

    static func modifierDisplayName(rawValue: Int) -> String {
        modifierChoices.first { $0.rawValue == rawValue }?.displayName ?? "自定义"
    }

    static func keyDisplayName(keyCode: Int) -> String {
        keyChoices.first { $0.keyCode == keyCode }?.displayName ?? "按键 \(keyCode)"
    }

    static func sanitized(keyCode: Int, modifiersRawValue: Int) -> TaskIslandShortcut {
        let shortcut = TaskIslandShortcut(
            keyCode: UInt32(max(keyCode, 0)),
            modifiers: UInt32(max(modifiersRawValue, 0))
        )
        guard shortcut.isAllowed else { return defaultQuickAdd }
        return shortcut
    }

    var isAllowed: Bool {
        let rawModifiers = Int(modifiers)
        guard Self.keyChoices.contains(where: { $0.keyCode == Int(keyCode) }) else {
            return false
        }
        guard Self.modifierChoices.contains(where: { $0.rawValue == rawModifiers }) else {
            return false
        }

        return true
    }
}

struct ShortcutModifierChoice: Identifiable, Hashable {
    let rawValue: Int
    let displayName: String

    var id: Int { rawValue }
}

struct ShortcutKeyChoice: Identifiable, Hashable {
    let keyCode: Int
    let displayName: String

    var id: Int { keyCode }
}
