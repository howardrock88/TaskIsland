import AppKit
import TaskIslandCore

@MainActor
final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let store: TaskStore
    private let settings: AppSettings
    private let taskPanelController: TaskPanelController

    var button: NSStatusBarButton? {
        statusItem.button
    }

    init(store: TaskStore, settings: AppSettings, taskPanelController: TaskPanelController) {
        self.store = store
        self.settings = settings
        self.taskPanelController = taskPanelController
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(toggleTaskPanel)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = settings.localized("任务岛", "TaskIsland")
        }
    }

    func update() {
        guard let button = statusItem.button else { return }

        let imageName = store.incompleteCount == 0 ? "checkmark.circle.fill" : "circle.dashed.inset.filled"
        button.image = NSImage(systemSymbolName: imageName, accessibilityDescription: settings.localized("任务岛", "TaskIsland"))
        button.imagePosition = .imageLeading
        button.title = statusTitle
        button.toolTip = tooltip
    }

    private var statusTitle: String {
        guard store.incompleteCount > 0 else {
            return " " + settings.localized("任务岛", "TaskIsland")
        }

        if settings.showTitleInMenuBar, let currentTask = store.currentTask {
            return " " + currentTask.title.truncated(to: 20)
        }

        return " \(store.incompleteCount)"
    }

    private var tooltip: String {
        guard store.incompleteCount > 0 else {
            return settings.localized("任务岛：暂无待办", "TaskIsland: No tasks")
        }

        return settings.localized("任务岛：\(store.incompleteCount) 个待办", "TaskIsland: \(store.incompleteCount) tasks")
    }

    @objc private func toggleTaskPanel() {
        taskPanelController.toggle(relativeTo: button)
    }
}

private extension String {
    func truncated(to maxLength: Int) -> String {
        guard count > maxLength else { return self }
        return String(prefix(maxLength - 1)) + "..."
    }
}
