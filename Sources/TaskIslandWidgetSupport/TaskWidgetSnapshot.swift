import Foundation

public enum TaskWidgetPriority: String, Codable, CaseIterable, Identifiable, Sendable {
    case high
    case medium
    case low

    public var id: String { rawValue }
}

public struct TaskWidgetPrioritySignal: Codable, Equatable, Sendable {
    public var high: Int
    public var medium: Int
    public var low: Int

    public init(high: Int = 0, medium: Int = 0, low: Int = 0) {
        self.high = max(high, 0)
        self.medium = max(medium, 0)
        self.low = max(low, 0)
    }

    public var total: Int {
        high + medium + low
    }
}

public struct TaskWidgetTask: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var priority: TaskWidgetPriority
    public var isCurrent: Bool
    public var isFocusing: Bool
    public var dueAt: Date?
    public var dueDateIncludesTime: Bool?
    public var estimatedMinutes: Int?
    public var focusStartedAt: Date?
    public var focusAccumulatedSeconds: TimeInterval
    public var focusTargetMinutes: Int

    public init(
        id: UUID,
        title: String,
        priority: TaskWidgetPriority,
        isCurrent: Bool = false,
        isFocusing: Bool = false,
        dueAt: Date? = nil,
        dueDateIncludesTime: Bool? = nil,
        estimatedMinutes: Int? = nil,
        focusStartedAt: Date? = nil,
        focusAccumulatedSeconds: TimeInterval = 0,
        focusTargetMinutes: Int = 25
    ) {
        self.id = id
        self.title = title
        self.priority = priority
        self.isCurrent = isCurrent
        self.isFocusing = isFocusing
        self.dueAt = dueAt
        self.dueDateIncludesTime = dueDateIncludesTime
        self.estimatedMinutes = estimatedMinutes
        self.focusStartedAt = focusStartedAt
        self.focusAccumulatedSeconds = max(focusAccumulatedSeconds, 0)
        self.focusTargetMinutes = max(focusTargetMinutes, 1)
    }

    public func focusElapsedSeconds(now: Date = Date()) -> TimeInterval {
        guard let focusStartedAt else { return focusAccumulatedSeconds }
        return max(focusAccumulatedSeconds + now.timeIntervalSince(focusStartedAt), 0)
    }

    public func focusRemainingSeconds(now: Date = Date()) -> TimeInterval {
        let target = TimeInterval(focusTargetMinutes * 60)
        return max(target - focusElapsedSeconds(now: now), 0)
    }
}

public struct TaskWidgetReview: Codable, Equatable, Sendable {
    public var completedTodayCount: Int
    public var postponedTodayCount: Int
    public var tomorrowCount: Int
    public var focusSeconds: TimeInterval
    public var completedToday: [TaskWidgetTask]
    public var suggestedTomorrow: [TaskWidgetTask]

    public init(
        completedTodayCount: Int = 0,
        postponedTodayCount: Int = 0,
        tomorrowCount: Int = 0,
        focusSeconds: TimeInterval = 0,
        completedToday: [TaskWidgetTask] = [],
        suggestedTomorrow: [TaskWidgetTask] = []
    ) {
        self.completedTodayCount = max(completedTodayCount, 0)
        self.postponedTodayCount = max(postponedTodayCount, 0)
        self.tomorrowCount = max(tomorrowCount, 0)
        self.focusSeconds = max(focusSeconds, 0)
        self.completedToday = completedToday
        self.suggestedTomorrow = suggestedTomorrow
    }
}

public struct TaskWidgetDeadlineSummary: Codable, Equatable, Sendable {
    public var todayDueCount: Int
    public var overdueCount: Int
    public var nearestTodayTimedDueAt: Date?
    public var nextFutureDueAt: Date?
    public var nextFutureDueDateIncludesTime: Bool

    public init(
        todayDueCount: Int = 0,
        overdueCount: Int = 0,
        nearestTodayTimedDueAt: Date? = nil,
        nextFutureDueAt: Date? = nil,
        nextFutureDueDateIncludesTime: Bool = false
    ) {
        self.todayDueCount = max(todayDueCount, 0)
        self.overdueCount = max(overdueCount, 0)
        self.nearestTodayTimedDueAt = nearestTodayTimedDueAt
        self.nextFutureDueAt = nextFutureDueAt
        self.nextFutureDueDateIncludesTime = nextFutureDueDateIncludesTime
    }
}

public struct TaskWidgetPalette: Codable, Equatable, Sendable {
    public var glassTintHex: String
    public var textColorHex: String?
    public var highPriorityHex: String
    public var mediumPriorityHex: String
    public var lowPriorityHex: String
    public var isDarkGlassMode: Bool

    public init(
        glassTintHex: String = "#DDF7FF",
        textColorHex: String? = nil,
        highPriorityHex: String = "#FF4057",
        mediumPriorityHex: String = "#FFB82E",
        lowPriorityHex: String = "#36C96B",
        isDarkGlassMode: Bool = false
    ) {
        self.glassTintHex = glassTintHex
        self.textColorHex = textColorHex?.isEmpty == false ? textColorHex : nil
        self.highPriorityHex = highPriorityHex
        self.mediumPriorityHex = mediumPriorityHex
        self.lowPriorityHex = lowPriorityHex
        self.isDarkGlassMode = isDarkGlassMode
    }

    public func colorHex(for priority: TaskWidgetPriority) -> String {
        switch priority {
        case .high:
            return highPriorityHex
        case .medium:
            return mediumPriorityHex
        case .low:
            return lowPriorityHex
        }
    }
}

public struct TaskWidgetSnapshot: Codable, Equatable, Sendable {
    public var generatedAt: Date
    public var languageCode: String
    public var palette: TaskWidgetPalette
    public var prioritySignal: TaskWidgetPrioritySignal
    public var currentTask: TaskWidgetTask?
    public var focusTask: TaskWidgetTask?
    public var todayTasks: [TaskWidgetTask]
    public var suggestedTasks: [TaskWidgetTask]
    public var review: TaskWidgetReview
    public var deadlineSummary: TaskWidgetDeadlineSummary?

    public init(
        generatedAt: Date = Date(),
        languageCode: String = "en",
        palette: TaskWidgetPalette = TaskWidgetPalette(),
        prioritySignal: TaskWidgetPrioritySignal = TaskWidgetPrioritySignal(),
        currentTask: TaskWidgetTask? = nil,
        focusTask: TaskWidgetTask? = nil,
        todayTasks: [TaskWidgetTask] = [],
        suggestedTasks: [TaskWidgetTask] = [],
        review: TaskWidgetReview = TaskWidgetReview(),
        deadlineSummary: TaskWidgetDeadlineSummary? = nil
    ) {
        self.generatedAt = generatedAt
        self.languageCode = languageCode
        self.palette = palette
        self.prioritySignal = prioritySignal
        self.currentTask = currentTask
        self.focusTask = focusTask
        self.todayTasks = todayTasks
        self.suggestedTasks = suggestedTasks
        self.review = review
        self.deadlineSummary = deadlineSummary
    }

    public var isEnglish: Bool {
        languageCode.lowercased().hasPrefix("en")
    }

    public var todayTotalCount: Int {
        todayTasks.count
    }

    public var hasAnyTask: Bool {
        prioritySignal.total > 0 || currentTask != nil || focusTask != nil || !todayTasks.isEmpty
    }

    public static let preview = TaskWidgetSnapshot(
        languageCode: "en",
        prioritySignal: TaskWidgetPrioritySignal(high: 2, medium: 1, low: 4),
        currentTask: TaskWidgetTask(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID(),
            title: "Deepseek article",
            priority: .high,
            isCurrent: true,
            focusStartedAt: Date().addingTimeInterval(-600),
            focusAccumulatedSeconds: 0,
            focusTargetMinutes: 25
        ),
        focusTask: TaskWidgetTask(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID(),
            title: "Deepseek article",
            priority: .high,
            isCurrent: true,
            isFocusing: true,
            focusStartedAt: Date().addingTimeInterval(-600),
            focusTargetMinutes: 25
        ),
        todayTasks: [
            TaskWidgetTask(id: UUID(), title: "Deepseek article", priority: .high, isCurrent: true, isFocusing: true, focusStartedAt: Date().addingTimeInterval(-600), focusTargetMinutes: 25),
            TaskWidgetTask(id: UUID(), title: "Product promo image", priority: .high, dueAt: Date().addingTimeInterval(3600), estimatedMinutes: 30),
            TaskWidgetTask(id: UUID(), title: "Review project notes", priority: .medium, dueAt: Date().addingTimeInterval(7200), estimatedMinutes: 15),
            TaskWidgetTask(id: UUID(), title: "Export Markdown backup", priority: .low)
        ],
        suggestedTasks: [
            TaskWidgetTask(id: UUID(), title: "Write launch checklist", priority: .medium),
            TaskWidgetTask(id: UUID(), title: "Prepare screenshots", priority: .low)
        ],
        review: TaskWidgetReview(
            completedTodayCount: 3,
            postponedTodayCount: 1,
            tomorrowCount: 2,
            focusSeconds: 45 * 60,
            completedToday: [
                TaskWidgetTask(id: UUID(), title: "Fix App Store icon", priority: .high),
                TaskWidgetTask(id: UUID(), title: "Upload build", priority: .medium)
            ],
            suggestedTomorrow: [
                TaskWidgetTask(id: UUID(), title: "Review App Store metadata", priority: .medium),
                TaskWidgetTask(id: UUID(), title: "Plan widget rollout", priority: .low)
            ]
        ),
        deadlineSummary: TaskWidgetDeadlineSummary(
            todayDueCount: 3,
            overdueCount: 1,
            nearestTodayTimedDueAt: Date().addingTimeInterval(3_600),
            nextFutureDueAt: Date().addingTimeInterval(24 * 3_600),
            nextFutureDueDateIncludesTime: true
        )
    )
}
