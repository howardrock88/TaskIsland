import AppKit
import Combine
import TaskIslandCore

@MainActor
final class AppCoordinator {
    static let shared = AppCoordinator()

    private var store: TaskStore?
    private var settings: AppSettings?
    private var islandPanelController: IslandPanelController?
    private var quickAddPanelController: QuickAddPanelController?
    private var taskPanelController: TaskPanelController?
    private var statusItemController: StatusItemController?
    private var hotKeyManager: HotKeyManager?
    private var reminderNotificationScheduler: ReminderNotificationScheduler?
    private var cancellables: Set<AnyCancellable> = []
    private var didStart = false

    private init() {}

    func start(store: TaskStore, settings: AppSettings) {
        guard !didStart else { return }
        didStart = true

        self.store = store
        self.settings = settings

        let islandPanelController = IslandPanelController(store: store, settings: settings)
        let taskPanelController = TaskPanelController(store: store, settings: settings)
        let quickAddPanelController = QuickAddPanelController(store: store, settings: settings)
        let reminderNotificationScheduler = ReminderNotificationScheduler()
        let statusItemController = StatusItemController(
            store: store,
            settings: settings,
            taskPanelController: taskPanelController
        )
        let hotKeyManager = HotKeyManager {
            quickAddPanelController.show()
        }

        self.islandPanelController = islandPanelController
        self.taskPanelController = taskPanelController
        self.quickAddPanelController = quickAddPanelController
        self.statusItemController = statusItemController
        self.hotKeyManager = hotKeyManager
        self.reminderNotificationScheduler = reminderNotificationScheduler

        islandPanelController.onOpenTasks = { [weak taskPanelController, weak islandPanelController] in
            taskPanelController?.show(anchorFrame: islandPanelController?.screenFrame)
        }
        islandPanelController.onQuickAdd = { [weak quickAddPanelController] in
            quickAddPanelController?.show()
        }
        taskPanelController.onClose = { [weak islandPanelController] in
            islandPanelController?.refreshLayout()
        }

        registerHotKey()
        statusItemController.update()
        islandPanelController.setVisible(settings.showCapsule)

        settings.$showCapsule
            .sink { [weak islandPanelController] isVisible in
                islandPanelController?.setVisible(isVisible)
            }
            .store(in: &cancellables)

        settings.$capsuleYOffset
            .sink { [weak islandPanelController] _ in
                islandPanelController?.refreshLayout()
            }
            .store(in: &cancellables)

        settings.$showTitleInMenuBar
            .sink { [weak statusItemController] _ in
                statusItemController?.update()
            }
            .store(in: &cancellables)

        settings.$quickAddShortcutKeyCode
            .combineLatest(settings.$quickAddShortcutModifiersRawValue)
            .dropFirst()
            .sink { [weak self] _ in
                self?.registerHotKey()
            }
            .store(in: &cancellables)

        store.$tasks
            .sink { [weak islandPanelController, weak statusItemController, weak reminderNotificationScheduler] tasks in
                islandPanelController?.refreshLayout()
                statusItemController?.update()
                reminderNotificationScheduler?.sync(tasks: tasks)
            }
            .store(in: &cancellables)

        reminderNotificationScheduler.sync(tasks: store.tasks)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func screenParametersDidChange() {
        islandPanelController?.refreshLayout()
    }

    private func registerHotKey() {
        guard let hotKeyManager, let settings else { return }

        let didRegister = hotKeyManager.register(shortcut: settings.quickAddShortcut)
        settings.quickAddShortcutStatusMessage = didRegister ? nil : "这个快捷键可能已被其他程序占用，请换一个组合。"
    }

    func showTaskPanel() {
        taskPanelController?.show(anchorFrame: islandPanelController?.screenFrame)
    }

    func showQuickAdd() {
        quickAddPanelController?.show()
    }
}
