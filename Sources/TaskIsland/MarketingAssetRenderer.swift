import AppKit
import SwiftUI
import TaskIslandCore

@MainActor
enum MarketingAssetRenderer {
    private static let renderScale: CGFloat = 3

    static func renderAll() throws {
        if let icon = NSImage(contentsOfFile: "\(FileManager.default.currentDirectoryPath)/Resources/AppIcon.png") {
            NSApp.applicationIconImage = icon
        }

        let outputDirectory = URL(fileURLWithPath: outputDirectoryPath())
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        try renderCollapsedIsland(to: outputDirectory.appendingPathComponent("island-collapsed.png"))
        try renderAttentionIsland(to: outputDirectory.appendingPathComponent("island-attention.png"))
        try renderExpandedIsland(to: outputDirectory.appendingPathComponent("island-expanded.png"))
        try renderTaskPanel(to: outputDirectory.appendingPathComponent("task-panel.png"))
        try renderTaskPanel(to: outputDirectory.appendingPathComponent("task-panel-today.png"), mode: .today)
        try renderTaskPanel(to: outputDirectory.appendingPathComponent("task-panel-review.png"), mode: .review)
        try renderQuickAdd(to: outputDirectory.appendingPathComponent("quick-add.png"))
        try renderTaskDetail(to: outputDirectory.appendingPathComponent("task-detail.png"))
        try renderSettingsPanel(to: outputDirectory.appendingPathComponent("settings-display.png"), anchor: .display)
        try renderSettingsPanel(to: outputDirectory.appendingPathComponent("settings-priority-capsule.png"), anchor: .priority)
        try renderSettingsPanel(to: outputDirectory.appendingPathComponent("settings-shortcuts-data.png"), anchor: .shortcuts)
    }

    private static func renderCollapsedIsland(to url: URL) throws {
        let store = try makeStore()
        addPriorityCountTasks(to: store)

        let state = IslandViewState()
        let view = CapsuleIslandView(
            viewState: state,
            onOpenTasks: {},
            onQuickAdd: {},
            onPinToggle: {},
            onHoverChanged: { _ in }
        )
        .environmentObject(store)
        .environmentObject(makeSettings())

        try render(view, size: CGSize(width: 172, height: 30), padding: 0, to: url)
    }

    private static func renderAttentionIsland(to url: URL) throws {
        let store = try makeStore()
        guard let focusTask = store.addTaskFromMetadata(
            title: "Deepseek 文章",
            isCurrent: true,
            priority: .high,
            estimatedMinutes: 25
        ) else {
            throw RenderError.demoDataFailed
        }
        store.startFocus(focusTask, now: Date().addingTimeInterval(-1))

        let state = IslandViewState()
        state.usesAttentionSize = true
        state.attentionStartedAt = Date().addingTimeInterval(-1)

        let view = CapsuleIslandView(
            viewState: state,
            onOpenTasks: {},
            onQuickAdd: {},
            onPinToggle: {},
            onHoverChanged: { _ in }
        )
        .environmentObject(store)
        .environmentObject(makeSettings())

        try render(view, size: CGSize(width: 340, height: 52), padding: 0, to: url)
    }

    private static func renderExpandedIsland(to url: URL) throws {
        let store = try makeStore()
        try addDemoTasks(to: store, includeFocus: true)

        let state = IslandViewState()
        state.isExpanded = true
        state.showsExpandedContent = true

        let view = CapsuleIslandView(
            viewState: state,
            onOpenTasks: {},
            onQuickAdd: {},
            onPinToggle: {},
            onHoverChanged: { _ in }
        )
        .environmentObject(store)
        .environmentObject(makeSettings())

        try render(view, size: CGSize(width: 440, height: 122), padding: 0, to: url)
    }

    private static func renderTaskPanel(to url: URL, mode: TaskViewMode = .all) throws {
        let store = try makeStore()
        try addDemoTasks(to: store, includeFocus: true)
        let state = TaskPanelState()

        let view = MenuBarWindowView(panelState: state, initialTaskViewMode: mode)
            .environmentObject(store)
            .environmentObject(makeSettings())

        try render(view, size: CGSize(width: 430, height: 590), padding: 0, to: url)
    }

    private static func renderQuickAdd(to url: URL) throws {
        let view = QuickAddView(
            initialTitle: "明天 10点 发周报 #工作 !高 /30m",
            initialPriority: .high,
            shouldAutoFocus: false,
            onSubmit: { _, _ in },
            onCancel: {}
        )
        .environmentObject(makeSettings())

        try render(view, size: CGSize(width: 500, height: 156), padding: 0, to: url)
    }

    private static func renderTaskDetail(to url: URL) throws {
        let store = try makeStore()
        let now = Date()
        guard let task = store.addTaskFromMetadata(
            title: "Deepseek 文章",
            notes: "补充文章结构、引用链接和发布前检查。",
            isCurrent: true,
            priority: .high,
            dueAt: Calendar.current.date(byAdding: .hour, value: 4, to: now),
            reminderAt: Calendar.current.date(byAdding: .hour, value: 3, to: now),
            repeatRule: .weekly,
            tags: ["AI", "研究"],
            projectName: "写作",
            estimatedMinutes: 25,
            todaySortIndex: 0
        ) else {
            throw RenderError.demoDataFailed
        }

        let view = TaskRowView(task: task, initiallyShowingDetails: true)
            .environmentObject(store)
            .environmentObject(makeSettings())
            .frame(width: 430, alignment: .top)
            .frame(width: 430, height: 220, alignment: .top)
            .clipped()

        try render(view, size: CGSize(width: 430, height: 220), padding: 0, to: url)
    }

    private static func renderSettingsPanel(to url: URL, anchor: TaskPanelSettingsAnchor) throws {
        let store = try makeStore()
        try addDemoTasks(to: store, includeFocus: true)
        let state = TaskPanelState()
        let settings = makeSettings()
        settings.capsuleTransparencyPercent = 32

        let view = MenuBarWindowView(
            panelState: state,
            initialShowingSettings: true,
            initialSettingsAnchor: anchor
        )
        .environmentObject(store)
        .environmentObject(settings)

        try render(
            view,
            size: CGSize(width: 430, height: 590),
            padding: 0,
            scrollFraction: settingsScrollFraction(for: anchor),
            to: url
        )
    }

    private static func render<V: View>(
        _ view: V,
        size: CGSize,
        padding: CGFloat,
        scrollFraction: CGFloat? = nil,
        to url: URL
    ) throws {
        let canvasSize = CGSize(width: size.width + padding * 2, height: size.height + padding * 2)
        let content = view
            .frame(width: size.width, height: size.height)
            .padding(padding)
            .frame(width: canvasSize.width, height: canvasSize.height)
            .background(Color.clear)

        let hostingView = NSHostingView(rootView: content)
        hostingView.frame = NSRect(origin: .zero, size: canvasSize)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: canvasSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.backgroundColor = .clear
        window.isOpaque = false
        window.contentView = hostingView
        window.displayIfNeeded()
        hostingView.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.55))
        if let scrollFraction {
            scrollFirstScrollView(in: hostingView, to: scrollFraction)
            hostingView.layoutSubtreeIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.12))
        }

        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(canvasSize.width * renderScale),
            pixelsHigh: Int(canvasSize.height * renderScale),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            window.close()
            throw RenderError.imageRenderingFailed(url.lastPathComponent)
        }
        bitmap.size = canvasSize
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmap)
        window.close()

        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw RenderError.pngEncodingFailed(url.lastPathComponent)
        }
        try data.write(to: url, options: .atomic)
    }

    private static func settingsScrollFraction(for anchor: TaskPanelSettingsAnchor) -> CGFloat? {
        switch anchor {
        case .display, .focus:
            return 0
        case .priority, .capsule:
            return 0.58
        case .shortcuts, .actions:
            return 1
        }
    }

    private static func scrollFirstScrollView(in view: NSView, to fraction: CGFloat) {
        guard let scrollView = firstScrollView(in: view), let documentView = scrollView.documentView else { return }
        let maxOffset = max(documentView.bounds.height - scrollView.contentView.bounds.height, 0)
        let yOffset = max(0, min(maxOffset, maxOffset * fraction))
        scrollView.contentView.scroll(to: NSPoint(x: 0, y: yOffset))
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }

    private static func firstScrollView(in view: NSView) -> NSScrollView? {
        if let scrollView = view as? NSScrollView {
            return scrollView
        }

        for subview in view.subviews {
            if let scrollView = firstScrollView(in: subview) {
                return scrollView
            }
        }

        return nil
    }

    private static func makeStore() throws -> TaskStore {
        try TaskStore(inMemory: true)
    }

    private static func makeSettings() -> AppSettings {
        let suiteName = "TaskIslandMarketingAssets-\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return AppSettings()
        }
        defaults.removePersistentDomain(forName: suiteName)
        let settings = AppSettings(defaults: defaults)
        settings.darkGlassMode = false
        settings.defaultFocusMinutes = 25
        settings.capsuleTransparencyPercent = 28
        settings.capsuleBackgroundColorHex = AppSettings.defaultCapsuleBackgroundColorHex
        settings.capsuleTextColorHex = AppSettings.automaticCapsuleTextColorHex
        settings.resetPriorityColors()
        return settings
    }

    private static func addPriorityCountTasks(to store: TaskStore) {
        for index in 1...2 {
            store.addTaskFromMetadata(title: "高优先级 \(index)", priority: .high)
        }
        for index in 1...5 {
            store.addTaskFromMetadata(title: "中优先级 \(index)", priority: .medium)
        }
        for index in 1...3 {
            store.addTaskFromMetadata(title: "低优先级 \(index)", priority: .low)
        }
    }

    private static func addDemoTasks(to store: TaskStore, includeFocus: Bool) throws {
        let now = Date()
        guard let focusTask = store.addTaskFromMetadata(
            title: "Deepseek 文章",
            isCurrent: true,
            priority: .high,
            dueAt: Calendar.current.date(byAdding: .hour, value: 4, to: now),
            estimatedMinutes: 25,
            todaySortIndex: 0
        ) else {
            throw RenderError.demoDataFailed
        }

        store.addTaskFromMetadata(
            title: "产品宣传图",
            priority: .high,
            dueAt: Calendar.current.date(byAdding: .hour, value: 6, to: now),
            estimatedMinutes: 30,
            todaySortIndex: 1
        )
        store.addTaskFromMetadata(
            title: "同步 Apple 提醒事项",
            priority: .medium,
            dueAt: Calendar.current.date(byAdding: .day, value: 1, to: now),
            estimatedMinutes: 15
        )
        store.addTaskFromMetadata(
            title: "导出 Markdown 备份",
            priority: .low
        )
        store.addTaskFromMetadata(
            title: "整理图标细节",
            isCompleted: true,
            completedAt: now.addingTimeInterval(-1_800),
            priority: .medium,
            tags: ["设计"],
            estimatedMinutes: 20
        )

        if includeFocus {
            store.startFocus(focusTask, now: now.addingTimeInterval(-1))
        } else {
            store.setCurrent(focusTask)
        }
    }

    private static func outputDirectoryPath() -> String {
        let arguments = CommandLine.arguments
        guard let index = arguments.firstIndex(of: "--marketing-output"),
              arguments.indices.contains(index + 1) else {
            return "assets/ui-snapshots"
        }
        return arguments[index + 1]
    }
}

private enum RenderError: Error, LocalizedError {
    case demoDataFailed
    case imageRenderingFailed(String)
    case pngEncodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .demoDataFailed:
            return "无法创建宣传素材示例任务。"
        case let .imageRenderingFailed(name):
            return "无法渲染 \(name)。"
        case let .pngEncodingFailed(name):
            return "无法保存 \(name)。"
        }
    }
}
