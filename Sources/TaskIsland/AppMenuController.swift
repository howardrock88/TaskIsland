import AppKit

@MainActor
enum AppMenuController {
    static func install() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu

        appMenu.addItem(
            withTitle: "关于任务岛",
            action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
            keyEquivalent: ""
        )
        appMenu.addItem(.separator())
        appMenu.addItem(
            withTitle: "显示任务岛",
            action: #selector(AppMenuActions.showTaskPanel),
            keyEquivalent: "1"
        )
        appMenu.addItem(
            withTitle: "快速新增",
            action: #selector(AppMenuActions.showQuickAdd),
            keyEquivalent: ""
        )
        appMenu.addItem(.separator())
        appMenu.addItem(
            withTitle: "退出任务岛",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )

        let actions = AppMenuActions.shared
        for item in appMenu.items where item.action == #selector(AppMenuActions.showTaskPanel) || item.action == #selector(AppMenuActions.showQuickAdd) {
            item.target = actions
        }

        NSApp.mainMenu = mainMenu
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
