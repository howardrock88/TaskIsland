import AppKit

@MainActor
enum AppMenuController {
    static func install(settings: AppSettings? = nil) {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu

        appMenu.addItem(
            withTitle: localized("关于任务岛", "About TaskIsland", settings: settings),
            action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
            keyEquivalent: ""
        )
        appMenu.addItem(.separator())
        appMenu.addItem(
            withTitle: localized("显示任务岛", "Show TaskIsland", settings: settings),
            action: #selector(AppMenuActions.showTaskPanel),
            keyEquivalent: "1"
        )
        appMenu.addItem(
            withTitle: localized("快速新增", "Quick Add", settings: settings),
            action: #selector(AppMenuActions.showQuickAdd),
            keyEquivalent: ""
        )
        appMenu.addItem(.separator())
        appMenu.addItem(
            withTitle: localized("退出任务岛", "Quit TaskIsland", settings: settings),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )

        let actions = AppMenuActions.shared
        for item in appMenu.items where item.action == #selector(AppMenuActions.showTaskPanel) || item.action == #selector(AppMenuActions.showQuickAdd) {
            item.target = actions
        }

        NSApp.mainMenu = mainMenu
    }

    private static func localized(_ chinese: String, _ english: String, settings: AppSettings?) -> String {
        settings?.localized(chinese, english) ?? chinese
    }
}

@MainActor
final class AppMenuActions: NSObject {
    static let shared = AppMenuActions()

    @objc func showTaskPanel() {
        AppCoordinator.shared.showTaskPanel()
    }

    @objc func showQuickAdd() {
        AppCoordinator.shared.showQuickAdd()
    }
}
