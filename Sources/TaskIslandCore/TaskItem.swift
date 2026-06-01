import Foundation
import SwiftData

public enum TaskPriority: Int, CaseIterable, Codable, Identifiable {
    case high = 0
    case medium = 1
    case low = 2

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .high:
            return "高优先级"
        case .medium:
            return "中优先级"
        case .low:
            return "低优先级"
        }
    }

    public var shortTitle: String {
        switch self {
        case .high:
            return "高"
        case .medium:
            return "中"
        case .low:
            return "低"
        }
    }
}

public enum TaskRepeatRule: String, CaseIterable, Codable, Identifiable {
    case daily
    case weekly
    case monthly
    case yearly

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .daily:
            return "每天"
        case .weekly:
            return "每周"
        case .monthly:
            return "每月"
        case .yearly:
            return "每年"
        }
    }
}

public struct TaskSubtask: Codable, Equatable, Identifiable {
    public var id: UUID
    public var title: String
    public var isCompleted: Bool
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}

@Model
public final class TaskItem {
    @Attribute(.unique)
    public var id: UUID
    public var title: String
    public var notes: String
    public var isCompleted: Bool
    public var isCurrent: Bool
    public var createdAt: Date
    public var updatedAt: Date
    public var completedAt: Date?
    public var sortIndex: Int
    public var priorityRawValue: Int?
    public var dueAt: Date?
    public var reminderAt: Date?
    public var repeatRuleRawValue: String?
    public var tagsRawValue: String?
    public var projectName: String?
    public var estimatedMinutes: Int?
    public var todaySortIndex: Int?
    public var subtasksRawValue: String?
    public var focusStartedAt: Date?
    public var focusAccumulatedSeconds: Double?
    public var postponedAt: Date?
    public var postponeCountRawValue: Int?

    public var priority: TaskPriority {
        get {
            TaskPriority(rawValue: priorityRawValue ?? TaskPriority.medium.rawValue) ?? .medium
        }
        set {
            priorityRawValue = newValue.rawValue
            updatedAt = Date()
        }
    }

    public var repeatRule: TaskRepeatRule? {
        get {
            repeatRuleRawValue.flatMap(TaskRepeatRule.init(rawValue:))
        }
        set {
            repeatRuleRawValue = newValue?.rawValue
            updatedAt = Date()
        }
    }

    public var tags: [String] {
        get {
            (tagsRawValue ?? "")
                .split(separator: ",")
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        set {
            tagsRawValue = newValue
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: ",")
            updatedAt = Date()
        }
    }

    public var isInTodayQueue: Bool {
        todaySortIndex != nil
    }

    public var subtasks: [TaskSubtask] {
        get {
            guard let subtasksRawValue,
                  let data = subtasksRawValue.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([TaskSubtask].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            subtasksRawValue = Self.encodedSubtasks(newValue)
            updatedAt = Date()
        }
    }

    public var completedSubtaskCount: Int {
        subtasks.filter(\.isCompleted).count
    }

    public var focusSeconds: TimeInterval {
        get { focusAccumulatedSeconds ?? 0 }
        set {
            focusAccumulatedSeconds = max(newValue, 0)
            updatedAt = Date()
        }
    }

    public var postponeCount: Int {
        get { postponeCountRawValue ?? 0 }
        set {
            postponeCountRawValue = max(newValue, 0)
            updatedAt = Date()
        }
    }

    public init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        isCompleted: Bool = false,
        isCurrent: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        completedAt: Date? = nil,
        sortIndex: Int,
        priority: TaskPriority = .medium,
        dueAt: Date? = nil,
        reminderAt: Date? = nil,
        repeatRule: TaskRepeatRule? = nil,
        tags: [String] = [],
        projectName: String? = nil,
        estimatedMinutes: Int? = nil,
        todaySortIndex: Int? = nil,
        subtasks: [TaskSubtask] = [],
        focusStartedAt: Date? = nil,
        focusAccumulatedSeconds: Double = 0,
        postponedAt: Date? = nil,
        postponeCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.isCompleted = isCompleted
        self.isCurrent = isCurrent
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.sortIndex = sortIndex
        self.priorityRawValue = priority.rawValue
        self.dueAt = dueAt
        self.reminderAt = reminderAt
        self.repeatRuleRawValue = repeatRule?.rawValue
        self.tagsRawValue = tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ",")
        self.projectName = projectName
        self.estimatedMinutes = estimatedMinutes
        self.todaySortIndex = todaySortIndex
        self.subtasksRawValue = Self.encodedSubtasks(subtasks)
        self.focusStartedAt = focusStartedAt
        self.focusAccumulatedSeconds = focusAccumulatedSeconds
        self.postponedAt = postponedAt
        self.postponeCountRawValue = postponeCount
    }

    private static func encodedSubtasks(_ subtasks: [TaskSubtask]) -> String? {
        let cleaned = subtasks
            .map { subtask in
                TaskSubtask(
                    id: subtask.id,
                    title: subtask.title.trimmingCharacters(in: .whitespacesAndNewlines),
                    isCompleted: subtask.isCompleted,
                    createdAt: subtask.createdAt
                )
            }
            .filter { !$0.title.isEmpty }
        guard let data = try? JSONEncoder().encode(cleaned) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
