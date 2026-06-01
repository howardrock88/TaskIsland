import Foundation
import TaskIslandCore
@preconcurrency import UserNotifications

@MainActor
final class ReminderNotificationScheduler {
    private let identifierPrefix = "taskisland-reminder-"

    func sync(tasks: [TaskItem]) {
        let snapshots = tasks.compactMap { task -> NotificationSnapshot? in
            guard !task.isCompleted,
                  let reminderAt = task.reminderAt ?? task.dueAt,
                  reminderAt > Date() else {
                return nil
            }

            return NotificationSnapshot(
                identifier: "\(identifierPrefix)\(task.id.uuidString)",
                title: task.title,
                body: notificationBody(for: task),
                reminderAt: reminderAt
            )
        }

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
                    content.title = "任务岛提醒"
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
        var parts: [String] = [task.priority.title]
        if let projectName = task.projectName, !projectName.isEmpty {
            parts.append(projectName)
        }
        if !task.tags.isEmpty {
            parts.append(task.tags.map { "#\($0)" }.joined(separator: " "))
        }
        return parts.joined(separator: " · ")
    }
}

private struct NotificationSnapshot: Sendable {
    let identifier: String
    let title: String
    let body: String
    let reminderAt: Date
}
