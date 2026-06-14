import Foundation
import TaskIslandCore
@preconcurrency import UserNotifications

@MainActor
final class ReminderNotificationScheduler {
    private let identifierPrefix = "taskisland-reminder-"
    private let settings: AppSettings
    private var inAppReminderTasks: [String: Task<Void, Never>] = [:]

    var onReminderDue: ((UUID) -> Void)?

    init(settings: AppSettings) {
        self.settings = settings
    }

    deinit {
        for task in inAppReminderTasks.values {
            task.cancel()
        }
    }

    func sync(tasks: [TaskItem]) {
        let snapshots = tasks.compactMap { task -> NotificationSnapshot? in
            guard !task.isCompleted,
                  let reminderAt = task.reminderAt ?? task.dueAt,
                  reminderAt > Date() else {
                return nil
            }

            return NotificationSnapshot(
                taskID: task.id,
                identifier: "\(identifierPrefix)\(task.id.uuidString)",
                title: task.title,
                body: notificationBody(for: task),
                reminderAt: reminderAt
            )
        }

        syncInAppReminders(snapshots)

        let notificationTitle = settings.localized("任务岛提醒", "TaskIsland Reminder")
        let center = UNUserNotificationCenter.current()
        guard !snapshots.isEmpty else {
            center.getPendingNotificationRequests { [identifierPrefix] requests in
                let staleIdentifiers = requests
                    .map(\.identifier)
                    .filter { $0.hasPrefix(identifierPrefix) }
                if !staleIdentifiers.isEmpty {
                    center.removePendingNotificationRequests(withIdentifiers: staleIdentifiers)
                }
            }
            return
        }

        center.requestAuthorization(options: [.alert, .sound]) { [identifierPrefix] granted, _ in
            center.getPendingNotificationRequests { requests in
                let staleIdentifiers = requests
                    .map(\.identifier)
                    .filter { $0.hasPrefix(identifierPrefix) }
                if !staleIdentifiers.isEmpty {
                    center.removePendingNotificationRequests(withIdentifiers: staleIdentifiers)
                }

                guard granted else { return }
                for snapshot in snapshots {
                    let content = UNMutableNotificationContent()
                    content.title = notificationTitle
                    content.body = snapshot.body.isEmpty ? snapshot.title : "\(snapshot.title)\n\(snapshot.body)"
                    content.sound = .default

                    let interval = max(snapshot.reminderAt.timeIntervalSinceNow, 1)
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
                    let request = UNNotificationRequest(
                        identifier: snapshot.identifier,
                        content: content,
                        trigger: trigger
                    )
                    center.add(request)
                }
            }
        }
    }

    private func notificationBody(for task: TaskItem) -> String {
        var parts: [String] = [task.priority.localizedTitle(settings: settings)]
        if let projectName = task.projectName, !projectName.isEmpty {
            parts.append(projectName)
        }
        if !task.tags.isEmpty {
            parts.append(task.tags.map { "#\($0)" }.joined(separator: " "))
        }
        return parts.joined(separator: " · ")
    }

    private func syncInAppReminders(_ snapshots: [NotificationSnapshot]) {
        for task in inAppReminderTasks.values {
            task.cancel()
        }
        inAppReminderTasks.removeAll()

        for snapshot in snapshots {
            let interval = max(snapshot.reminderAt.timeIntervalSinceNow, 1)
            inAppReminderTasks[snapshot.identifier] = Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self?.inAppReminderTasks[snapshot.identifier] = nil
                    self?.onReminderDue?(snapshot.taskID)
                }
            }
        }
    }
}

private struct NotificationSnapshot: Sendable {
    let taskID: UUID
    let identifier: String
    let title: String
    let body: String
    let reminderAt: Date
}
