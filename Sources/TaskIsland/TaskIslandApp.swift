import AppKit
import TaskIslandCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var store: TaskStore?
    private var settings: AppSettings?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        AppMenuController.install()

        do {
            let store = try TaskStore()
            let settings = AppSettings()
            self.store = store
            self.settings = settings
            AppCoordinator.shared.start(store: store, settings: settings)
        } catch {
            let alert = NSAlert()
            alert.messageText = "任务岛无法启动"
            alert.informativeText = error.localizedDescription
            alert.runModal()
            NSApp.terminate(nil)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        AppCoordinator.shared.showTaskPanel()
        return true
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            handleShortcutURL(url)
        }
    }

    private func handleShortcutURL(_ url: URL) {
        guard url.scheme == "taskisland" else { return }

        let action = url.host ?? url.pathComponents.dropFirst().first ?? ""
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []

        switch action.lowercased() {
        case "add", "new":
            let title = queryItems.value(named: "title") ?? queryItems.value(named: "text") ?? ""
            let notes = queryItems.value(named: "notes") ?? ""
            let priority = TaskPriority(shortcutValue: queryItems.value(named: "priority")) ?? .medium
            store?.addTask(title: title, notes: notes, priority: priority)
        case "focus", "start":
            if let currentTask = store?.currentTask {
                store?.startFocus(currentTask)
            }
        case "complete", "done":
            if let currentTask = store?.currentTask {
                store?.complete(currentTask)
            }
        case "show":
            AppCoordinator.shared.showTaskPanel()
        default:
            break
        }
    }
}

private extension Array where Element == URLQueryItem {
    func value(named name: String) -> String? {
        first { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }?.value
    }
}

private extension TaskPriority {
    init?(shortcutValue: String?) {
        guard let value = shortcutValue?.lowercased() else { return nil }
        if value.contains("高") || value.contains("high") || value == "p1" || value == "1" {
            self = .high
        } else if value.contains("低") || value.contains("low") || value == "p3" || value == "3" {
            self = .low
        } else if value.contains("中") || value.contains("medium") || value == "p2" || value == "2" {
            self = .medium
        } else {
            return nil
        }
    }
}
