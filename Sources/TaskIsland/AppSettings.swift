import Combine
import Foundation
import TaskIslandCore

enum AppLanguage: String, CaseIterable, Identifiable {
    case chinese = "zh-Hans"
    case english = "en"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chinese:
            return "中文"
        case .english:
            return "English"
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    @Published var showCapsule: Bool {
        didSet { defaults.set(showCapsule, forKey: Keys.showCapsule) }
    }

    @Published var showTitleInMenuBar: Bool {
        didSet { defaults.set(showTitleInMenuBar, forKey: Keys.showTitleInMenuBar) }
    }

    @Published var darkGlassMode: Bool {
        didSet { defaults.set(darkGlassMode, forKey: Keys.darkGlassMode) }
    }

    @Published var appLanguage: AppLanguage {
        didSet { defaults.set(appLanguage.rawValue, forKey: Keys.appLanguage) }
    }

    @Published var defaultFocusMinutes: Double {
        didSet { defaults.set(Self.clampedFocusMinutes(defaultFocusMinutes), forKey: Keys.defaultFocusMinutes) }
    }

    @Published var quickAddShortcutKeyCode: Int {
        didSet { defaults.set(quickAddShortcutKeyCode, forKey: Keys.quickAddShortcutKeyCode) }
    }

    @Published var quickAddShortcutModifiersRawValue: Int {
        didSet { defaults.set(quickAddShortcutModifiersRawValue, forKey: Keys.quickAddShortcutModifiersRawValue) }
    }

    @Published var quickAddShortcutStatusMessage: String?

    @Published var highPriorityColorHex: String {
        didSet { defaults.set(highPriorityColorHex, forKey: Keys.highPriorityColorHex) }
    }

    @Published var mediumPriorityColorHex: String {
        didSet { defaults.set(mediumPriorityColorHex, forKey: Keys.mediumPriorityColorHex) }
    }

    @Published var lowPriorityColorHex: String {
        didSet { defaults.set(lowPriorityColorHex, forKey: Keys.lowPriorityColorHex) }
    }

    @Published var capsuleYOffset: Double {
        didSet { defaults.set(capsuleYOffset, forKey: Keys.capsuleYOffset) }
    }

    @Published var capsuleTransparencyPercent: Double {
        didSet { defaults.set(Self.clampedTransparency(capsuleTransparencyPercent), forKey: Keys.capsuleTransparencyPercent) }
    }

    @Published var capsuleBackgroundColorHex: String {
        didSet { defaults.set(capsuleBackgroundColorHex, forKey: Keys.capsuleBackgroundColorHex) }
    }

    @Published var capsuleTextColorHex: String {
        didSet { defaults.set(capsuleTextColorHex, forKey: Keys.capsuleTextColorHex) }
    }

    @Published var hasCapsuleCustomPosition: Bool {
        didSet { defaults.set(hasCapsuleCustomPosition, forKey: Keys.hasCapsuleCustomPosition) }
    }

    @Published var capsuleAnchorX: Double {
        didSet { defaults.set(capsuleAnchorX, forKey: Keys.capsuleAnchorX) }
    }

    @Published var capsuleTopY: Double {
        didSet { defaults.set(capsuleTopY, forKey: Keys.capsuleTopY) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        showCapsule = defaults.object(forKey: Keys.showCapsule) as? Bool ?? true
        showTitleInMenuBar = defaults.object(forKey: Keys.showTitleInMenuBar) as? Bool ?? true
        darkGlassMode = defaults.object(forKey: Keys.darkGlassMode) as? Bool ?? false
        let savedLanguage = defaults.object(forKey: Keys.appLanguage) as? String
        appLanguage = AppLanguage(rawValue: savedLanguage ?? "") ?? Self.bundledDefaultLanguage()
        defaultFocusMinutes = Self.clampedFocusMinutes(
            defaults.object(forKey: Keys.defaultFocusMinutes) as? Double ?? Self.standardFocusMinutes
        )
        let savedShortcut = TaskIslandShortcut.sanitized(
            keyCode: defaults.object(forKey: Keys.quickAddShortcutKeyCode) as? Int ?? Int(TaskIslandShortcut.defaultQuickAdd.keyCode),
            modifiersRawValue: defaults.object(forKey: Keys.quickAddShortcutModifiersRawValue) as? Int ?? Int(TaskIslandShortcut.defaultQuickAdd.modifiers)
        )
        quickAddShortcutKeyCode = Int(savedShortcut.keyCode)
        quickAddShortcutModifiersRawValue = Int(savedShortcut.modifiers)
        defaults.set(Int(savedShortcut.keyCode), forKey: Keys.quickAddShortcutKeyCode)
        defaults.set(Int(savedShortcut.modifiers), forKey: Keys.quickAddShortcutModifiersRawValue)
        quickAddShortcutStatusMessage = nil
        highPriorityColorHex = defaults.object(forKey: Keys.highPriorityColorHex) as? String ?? TaskPriority.high.defaultColorHex
        mediumPriorityColorHex = defaults.object(forKey: Keys.mediumPriorityColorHex) as? String ?? TaskPriority.medium.defaultColorHex
        lowPriorityColorHex = defaults.object(forKey: Keys.lowPriorityColorHex) as? String ?? TaskPriority.low.defaultColorHex

        if defaults.bool(forKey: Keys.didMigrateTopAlignedOffset) {
            capsuleYOffset = defaults.object(forKey: Keys.capsuleYOffset) as? Double ?? 0
        } else {
            capsuleYOffset = 0
            defaults.set(0, forKey: Keys.capsuleYOffset)
            defaults.set(true, forKey: Keys.didMigrateTopAlignedOffset)
        }

        if defaults.bool(forKey: Keys.didMigrateTransparencySemantic) {
            capsuleTransparencyPercent = Self.clampedTransparency(
                defaults.object(forKey: Keys.capsuleTransparencyPercent) as? Double ?? 28
            )
        } else {
            let oldOpacityPercent = defaults.object(forKey: Keys.capsuleOpacityPercent) as? Double ?? 72
            let migratedTransparency = 100 - Self.clampedTransparency(oldOpacityPercent)
            capsuleTransparencyPercent = Self.clampedTransparency(migratedTransparency)
            defaults.set(Self.clampedTransparency(migratedTransparency), forKey: Keys.capsuleTransparencyPercent)
            defaults.set(true, forKey: Keys.didMigrateTransparencySemantic)
        }
        capsuleBackgroundColorHex = defaults.object(forKey: Keys.capsuleBackgroundColorHex) as? String ?? Self.defaultCapsuleBackgroundColorHex
        capsuleTextColorHex = defaults.object(forKey: Keys.capsuleTextColorHex) as? String ?? Self.automaticCapsuleTextColorHex
        hasCapsuleCustomPosition = defaults.object(forKey: Keys.hasCapsuleCustomPosition) as? Bool ?? false
        capsuleAnchorX = defaults.object(forKey: Keys.capsuleAnchorX) as? Double ?? 0
        capsuleTopY = defaults.object(forKey: Keys.capsuleTopY) as? Double ?? 0
    }

    func priorityColorHex(for priority: TaskPriority) -> String {
        switch priority {
        case .high:
            return highPriorityColorHex
        case .medium:
            return mediumPriorityColorHex
        case .low:
            return lowPriorityColorHex
        }
    }

    func setPriorityColorHex(_ hex: String, for priority: TaskPriority) {
        switch priority {
        case .high:
            highPriorityColorHex = hex
        case .medium:
            mediumPriorityColorHex = hex
        case .low:
            lowPriorityColorHex = hex
        }
    }

    func resetPriorityColors() {
        highPriorityColorHex = TaskPriority.high.defaultColorHex
        mediumPriorityColorHex = TaskPriority.medium.defaultColorHex
        lowPriorityColorHex = TaskPriority.low.defaultColorHex
    }

    static let defaultCapsuleBackgroundColorHex = "#DDF7FF"
    static let automaticCapsuleTextColorHex = ""
    static let standardFocusMinutes = 25.0

    private static func bundledDefaultLanguage(bundle: Bundle = .main) -> AppLanguage {
        guard let rawValue = bundle.object(forInfoDictionaryKey: "TaskIslandDefaultLanguage") as? String else {
            return .chinese
        }

        switch rawValue.lowercased() {
        case "en", "en-us":
            return .english
        case "zh-hans", "zh_cn", "zh-cn":
            return .chinese
        default:
            return .chinese
        }
    }

    var isEnglish: Bool {
        appLanguage == .english
    }

    var locale: Locale {
        Locale(identifier: isEnglish ? "en_US" : "zh_CN")
    }

    func localized(_ chinese: String, _ english: String) -> String {
        isEnglish ? english : chinese
    }

    var defaultFocusMinutesInt: Int {
        Self.focusMinutesInt(defaultFocusMinutes)
    }

    var quickAddShortcut: TaskIslandShortcut {
        TaskIslandShortcut(
            keyCode: UInt32(max(quickAddShortcutKeyCode, 0)),
            modifiers: UInt32(max(quickAddShortcutModifiersRawValue, 0))
        )
    }

    func resetQuickAddShortcut() {
        quickAddShortcutKeyCode = Int(TaskIslandShortcut.defaultQuickAdd.keyCode)
        quickAddShortcutModifiersRawValue = Int(TaskIslandShortcut.defaultQuickAdd.modifiers)
    }

    static func clampedTransparency(_ value: Double) -> Double {
        min(max(value, 0), 100)
    }

    static func clampedFocusMinutes(_ value: Double) -> Double {
        min(max(value, 5), 180)
    }

    static func focusMinutesInt(_ value: Double) -> Int {
        Int(clampedFocusMinutes(value).rounded())
    }

    private enum Keys {
        static let showCapsule = "showCapsule"
        static let showTitleInMenuBar = "showTitleInMenuBar"
        static let darkGlassMode = "darkGlassMode"
        static let appLanguage = "appLanguage"
        static let defaultFocusMinutes = "defaultFocusMinutes"
        static let quickAddShortcutKeyCode = "quickAddShortcutKeyCode"
        static let quickAddShortcutModifiersRawValue = "quickAddShortcutModifiersRawValue"
        static let highPriorityColorHex = "highPriorityColorHex"
        static let mediumPriorityColorHex = "mediumPriorityColorHex"
        static let lowPriorityColorHex = "lowPriorityColorHex"
        static let capsuleYOffset = "capsuleYOffset"
        static let capsuleOpacityPercent = "capsuleOpacityPercent"
        static let capsuleTransparencyPercent = "capsuleTransparencyPercent"
        static let capsuleBackgroundColorHex = "capsuleBackgroundColorHex"
        static let capsuleTextColorHex = "capsuleTextColorHex"
        static let didMigrateTransparencySemantic = "didMigrateTransparencySemantic"
        static let didMigrateTopAlignedOffset = "didMigrateTopAlignedOffset"
        static let hasCapsuleCustomPosition = "hasCapsuleCustomPosition"
        static let capsuleAnchorX = "capsuleAnchorX"
        static let capsuleTopY = "capsuleTopY"
    }
}
