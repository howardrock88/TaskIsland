import EventKit
import Foundation
import TaskIslandCore

@MainActor
final class AppleRemindersBridge {
    private let eventStore = EKEventStore()
    private let calendarTitle = "任务岛"
    private let taskIdentifierPrefix = "TaskIsland-ID:"

    func importIncompleteReminders(into store: TaskStore) async throws -> Int {
        try await ensureRemindersAccess()
        let reminders = await fetchIncompleteReminderSnapshots()
        var importedCount = 0

        for reminder in reminders where !reminder.isCompleted {
            let title = reminder.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { continue }
            let dueAt = reminder.dueAt
            let alreadyExists = store.tasks.contains { task in
                task.title.localizedCaseInsensitiveCompare(title) == .orderedSame
                    && sameOptionalDay(task.dueAt, dueAt)
            }
            guard !alreadyExists else { continue }

            if store.addTaskFromMetadata(
                title: title,
                notes: reminder.notes ?? "",
                priority: taskPriority(from: reminder.priority),
                dueAt: dueAt,
                reminderAt: reminder.reminderAt,
                tags: [reminder.calendarTitle].filter { !$0.isEmpty },
                projectName: reminder.calendarTitle == calendarTitle ? nil : reminder.calendarTitle,
                todaySortIndex: dueAt.map { Calendar.current.isDateInToday($0) ? 0 : nil } ?? nil
            ) != nil {
                importedCount += 1
            }
        }

        return importedCount
    }

    func exportIncompleteTasks(from store: TaskStore) async throws -> Int {
        try await ensureRemindersAccess()
        let calendar = try reminderCalendar()
        let existingIdentifiers = try await existingTaskIslandIdentifiers(in: calendar)
        var exportedCount = 0

        for task in store.incompleteTasks where !existingIdentifiers.contains(task.id.uuidString) {
            let reminder = EKReminder(eventStore: eventStore)
            reminder.calendar = calendar
            reminder.title = task.title
            reminder.notes = reminderNotes(for: task)
            reminder.priority = reminderPriority(from: task.priority)

            if let dueAt = task.dueAt {
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueAt)
                reminder.dueDateComponents = components
            }
            if let reminderAt = task.reminderAt ?? task.dueAt {
                reminder.addAlarm(EKAlarm(absoluteDate: reminderAt))
            }

            try save(reminder)
            exportedCount += 1
        }

        return exportedCount
    }

    private func ensureRemindersAccess() async throws {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        switch status {
        case .fullAccess, .authorized:
            return
        case .notDetermined:
            let granted = try await requestAccess()
            if granted { return }
            throw AppleRemindersBridgeError.accessDenied
        default:
            throw AppleRemindersBridgeError.accessDenied
        }
    }

    private func requestAccess() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            if #available(macOS 14.0, *) {
                eventStore.requestFullAccessToReminders { granted, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            } else {
                eventStore.requestAccess(to: .reminder) { granted, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
    }

    private func fetchIncompleteReminderSnapshots(calendars: [EKCalendar]? = nil) async -> [ReminderSnapshot] {
        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: nil,
            ending: nil,
            calendars: calendars
        )
        return await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                let snapshots = (reminders ?? []).map { reminder in
                    ReminderSnapshot(
                        title: reminder.title,
                        notes: reminder.notes,
                        calendarTitle: reminder.calendar?.title ?? "",
                        priority: Int(reminder.priority),
                        dueAt: reminder.dueDateComponents.flatMap { Calendar.current.date(from: $0) },
                        reminderAt: reminder.alarms?.compactMap(\.absoluteDate).first,
                        isCompleted: reminder.isCompleted
                    )
                }
                continuation.resume(returning: snapshots)
            }
        }
    }

    private func reminderCalendar() throws -> EKCalendar {
        if let existing = eventStore.calendars(for: .reminder).first(where: { $0.title == calendarTitle }) {
            return existing
        }
        if let defaultCalendar = eventStore.defaultCalendarForNewReminders() {
            let calendar = EKCalendar(for: .reminder, eventStore: eventStore)
            calendar.title = calendarTitle
            calendar.source = defaultCalendar.source
            try save(calendar)
            return calendar
        }
        throw AppleRemindersBridgeError.noReminderList
    }

    private func existingTaskIslandIdentifiers(in calendar: EKCalendar) async throws -> Set<String> {
        let reminders = await fetchIncompleteReminderSnapshots(calendars: [calendar])
        return Set(reminders.compactMap { reminder in
            identifier(in: reminder.notes ?? "")
        })
    }

    private func save(_ calendar: EKCalendar) throws {
        try eventStore.saveCalendar(calendar, commit: true)
    }

    private func save(_ reminder: EKReminder) throws {
        try eventStore.save(reminder, commit: true)
    }

    private func reminderNotes(for task: TaskItem) -> String {
        var lines: [String] = []
        if !task.notes.isEmpty {
            lines.append(task.notes)
            lines.append("")
        }
        lines.append("\(taskIdentifierPrefix)\(task.id.uuidString)")
        if !task.tags.isEmpty {
            lines.append("标签：\(task.tags.map { "#\($0)" }.joined(separator: " "))")
        }
        if let estimatedMinutes = task.estimatedMinutes {
            lines.append("预计：\(estimatedMinutes) 分钟")
        }
        return lines.joined(separator: "\n")
    }

    private func identifier(in notes: String) -> String? {
        notes
            .split(separator: "\n")
            .first { $0.hasPrefix(taskIdentifierPrefix) }
            .map { String($0.dropFirst(taskIdentifierPrefix.count)) }
    }

    private func taskPriority(from reminderPriority: Int) -> TaskPriority {
        switch reminderPriority {
        case 1...4:
            return .high
        case 6...9:
            return .low
        default:
            return .medium
        }
    }

    private func reminderPriority(from taskPriority: TaskPriority) -> Int {
        switch taskPriority {
        case .high:
            return 1
        case .medium:
            return 5
        case .low:
            return 9
        }
    }

    private func sameOptionalDay(_ lhs: Date?, _ rhs: Date?) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case let (.some(lhs), .some(rhs)):
            return Calendar.current.isDate(lhs, inSameDayAs: rhs)
        default:
            return false
        }
    }
}

private enum AppleRemindersBridgeError: LocalizedError {
    case accessDenied
    case noReminderList
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "没有获得提醒事项权限"
        case .noReminderList:
            return "没有可用的提醒事项清单"
        case .saveFailed:
            return "无法写入提醒事项"
        }
    }
}

private struct ReminderSnapshot: Sendable {
    let title: String
    let notes: String?
    let calendarTitle: String
    let priority: Int
    let dueAt: Date?
    let reminderAt: Date?
    let isCompleted: Bool
}
