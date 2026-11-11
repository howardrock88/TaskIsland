import Foundation
import TaskIslandCore

extension TaskPriority {
    @MainActor
    func localizedTitle(settings: AppSettings) -> String {
        switch self {
        case .high:
            return settings.localized("高优先级", "High Priority")
        case .medium:
            return settings.localized("中优先级", "Medium Priority")
        case .low:
            return settings.localized("低优先级", "Low Priority")
        }
    }

    @MainActor
    func localizedShortTitle(settings: AppSettings) -> String {
        switch self {
        case .high:
            return settings.localized("高", "High")
        case .medium:
            return settings.localized("中", "Med")
        case .low:
            return settings.localized("低", "Low")
        }
    }
}

extension TaskRepeatRule {
    @MainActor
    func localizedTitle(settings: AppSettings) -> String {
        switch self {
        case .daily:
            return settings.localized("每天", "Daily")
        case .weekly:
            return settings.localized("每周", "Weekly")
        case .monthly:
            return settings.localized("每月", "Monthly")
        case .yearly:
            return settings.localized("每年", "Yearly")
        }
    }
}

extension TaskPostponeOption {
    @MainActor
    func localizedTitle(settings: AppSettings) -> String {
        switch self {
        case .fifteenMinutes:
            return settings.localized("15 分钟后", "In 15 min")
        case .laterToday:
            return settings.localized("今天晚点", "Later today")
        case .tomorrow:
            return settings.localized("明天", "Tomorrow")
        case .thisWeek:
            return settings.localized("本周", "This week")
        }
    }
}

extension TaskExportFormat {
    @MainActor
    func localizedTitle(settings: AppSettings) -> String {
        switch self {
        case .json:
            return settings.localized("JSON 备份", "JSON Backup")
        case .markdown:
            return "Markdown"
        case .csv:
            return settings.localized("CSV 表格", "CSV Table")
        }
    }
}
