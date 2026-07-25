import Foundation

public enum TaskAttentionRecommender {
    public static let defaultLimit = 2
    public static let minimumScore = 30

    public static func recommendations(
        from tasks: [TaskItem],
        excluding excludedIDs: Set<UUID> = [],
        now: Date = Date(),
        calendar: Calendar = .current,
        limit: Int = defaultLimit
    ) -> [TaskItem] {
        guard limit > 0 else { return [] }

        return tasks
            .filter { task in
                !task.isCompleted
                    && !task.isInTodayQueue
                    && !excludedIDs.contains(task.id)
                    && score(for: task, now: now, calendar: calendar) >= minimumScore
            }
            .sorted { lhs, rhs in
                let lhsScore = score(for: lhs, now: now, calendar: calendar)
                let rhsScore = score(for: rhs, now: now, calendar: calendar)
                if lhsScore != rhsScore { return lhsScore > rhsScore }

                let lhsDueAt = lhs.dueAt ?? .distantFuture
                let rhsDueAt = rhs.dueAt ?? .distantFuture
                if lhsDueAt != rhsDueAt { return lhsDueAt < rhsDueAt }

                if lhs.priority != rhs.priority {
                    return lhs.priority.rawValue < rhs.priority.rawValue
                }
                if lhs.postponeCount != rhs.postponeCount {
                    return lhs.postponeCount > rhs.postponeCount
                }
                return lhs.sortIndex < rhs.sortIndex
            }
            .prefix(limit)
            .map { $0 }
    }

    public static func score(
        for task: TaskItem,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        guard !task.isCompleted else { return 0 }

        let priorityScore: Int
        switch task.priority {
        case .high:
            priorityScore = 30
        case .medium:
            priorityScore = 15
        case .low:
            priorityScore = 0
        }

        let urgencyScore: Int
        if let dueAt = task.dueAt {
            if dueAt < now {
                urgencyScore = 60
            } else if calendar.isDate(dueAt, inSameDayAs: now) {
                urgencyScore = 45
            } else if calendar.isDateInTomorrow(dueAt) {
                urgencyScore = 30
            } else if dueAt.timeIntervalSince(now) <= 3 * 24 * 60 * 60 {
                urgencyScore = 15
            } else {
                urgencyScore = 0
            }
        } else {
            urgencyScore = 0
        }

        let postponementScore = min(task.postponeCount, 3) * 8
        return priorityScore + urgencyScore + postponementScore
    }
}
