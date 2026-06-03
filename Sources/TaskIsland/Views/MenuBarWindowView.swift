import AppKit
import SwiftUI
import TaskIslandCore
import UniformTypeIdentifiers

struct MenuBarWindowView: View {
    @EnvironmentObject private var store: TaskStore
    @EnvironmentObject private var settings: AppSettings
    @FocusState private var isAddFieldFocused: Bool
    @State private var newTaskTitle = ""
    @State private var selectedPriority: TaskPriority = .medium
    @State private var isShowingSettings = false
    @State private var taskViewMode: TaskViewMode = .all
    @State private var importExportMessage: String?
    @State private var searchText = ""
    @State private var selectedExportFormat: TaskExportFormat = .json
    @State private var isReminderBusy = false
    @State private var isCompletedSectionExpanded = false

    @ObservedObject var panelState: TaskPanelState
    private let remindersBridge = AppleRemindersBridge()
    private let initialSettingsAnchor: TaskPanelSettingsAnchor?

    let onDismiss: () -> Void
    let onPinChanged: (Bool) -> Void
    let onDragChanged: (CGSize) -> Void
    let onDragEnded: () -> Void

    init(
        panelState: TaskPanelState,
        initialShowingSettings: Bool = false,
        initialTaskViewMode: TaskViewMode = .all,
        initialSettingsAnchor: TaskPanelSettingsAnchor? = nil,
        onDismiss: @escaping () -> Void = {},
        onPinChanged: @escaping (Bool) -> Void = { _ in },
        onDragChanged: @escaping (CGSize) -> Void = { _ in },
        onDragEnded: @escaping () -> Void = {}
    ) {
        self.panelState = panelState
        self.initialSettingsAnchor = initialSettingsAnchor
        self.onDismiss = onDismiss
        self.onPinChanged = onPinChanged
        self.onDragChanged = onDragChanged
        self.onDragEnded = onDragEnded
        _isShowingSettings = State(initialValue: initialShowingSettings)
        _taskViewMode = State(initialValue: initialTaskViewMode)
    }

    var body: some View {
        ZStack {
            if isShowingSettings {
                settingsPanel
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else {
                taskPanel
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: isShowingSettings)
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .taskIslandGlass(in: panelShape)
        .background(panelTint)
        .clipShape(panelShape)
        .overlay {
            darkPanelShade
                .allowsHitTesting(false)
        }
        .overlay {
            panelHighlights
                .allowsHitTesting(false)
        }
        .overlay(panelStroke)
        .shadow(color: .black.opacity(0.18), radius: 30, x: 0, y: 22)
        .shadow(color: .white.opacity(0.18), radius: 2, x: 0, y: -1)
        .preferredColorScheme(settings.darkGlassMode ? .dark : nil)
        .onAppear {
            isAddFieldFocused = !isShowingSettings
        }
        .onChange(of: isShowingSettings) { _, newValue in
            isAddFieldFocused = !newValue
        }
    }

    private var taskPanel: some View {
        VStack(spacing: 12) {
            header
            addTaskField
            focusSummaryCard
            taskViewPicker
            searchField
            taskList
        }
    }

    private var settingsPanel: some View {
        VStack(spacing: 12) {
            settingsHeader

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        settingsDisplaySection
                            .id(TaskPanelSettingsAnchor.display)
                        settingsFocusSection
                            .id(TaskPanelSettingsAnchor.focus)
                        settingsPrioritySection
                            .id(TaskPanelSettingsAnchor.priority)
                        settingsCapsuleSection
                            .id(TaskPanelSettingsAnchor.capsule)
                        settingsShortcutSection
                            .id(TaskPanelSettingsAnchor.shortcuts)
                        settingsActionsSection
                            .id(TaskPanelSettingsAnchor.actions)
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: .infinity)
                .onAppear {
                    guard initialSettingsAnchor != nil else { return }
                    DispatchQueue.main.async {
                        scrollToInitialSettingsAnchor(proxy)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                        scrollToInitialSettingsAnchor(proxy)
                    }
                }
            }
        }
    }

    private func scrollToInitialSettingsAnchor(_ proxy: ScrollViewProxy) {
        guard let initialSettingsAnchor else { return }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            proxy.scrollTo(initialSettingsAnchor, anchor: .top)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            taskHeaderTitle
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .gesture(panelDragGesture)

            Spacer(minLength: 8)

            pinButton

            Button {
                isShowingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(GlassIconButtonStyle())
            .help("设置")

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(GlassIconButtonStyle())
            .help("隐藏面板")
        }
        .padding(.horizontal, 2)
    }

    private var settingsHeader: some View {
        HStack(spacing: 12) {
            Button {
                isShowingSettings = false
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(GlassIconButtonStyle())
            .help("返回任务")

            settingsHeaderTitle
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .gesture(panelDragGesture)

            Spacer(minLength: 8)

            pinButton

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(GlassIconButtonStyle())
            .help("隐藏面板")
        }
        .padding(.horizontal, 2)
    }

    private var taskHeaderTitle: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.52), lineWidth: 1)
                    }

                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 23, height: 23)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text("任务岛")
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)

                Text(headerSubtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .contentShape(Rectangle())
        .help("拖动面板")
    }

    private var settingsHeaderTitle: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("设置")
                .font(.system(size: 16, weight: .semibold))
                .lineLimit(1)

            Text("任务岛偏好")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .contentShape(Rectangle())
        .help("拖动面板")
    }

    private var panelDragGesture: some Gesture {
        DragGesture(minimumDistance: 3)
            .onChanged { value in
                onDragChanged(value.translation)
            }
            .onEnded { _ in
                onDragEnded()
            }
    }

    private var addTaskField: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus")
                .foregroundStyle(.secondary)

            TextField("明天 10点 发周报 #工作 !高 /30m", text: $newTaskTitle)
                .textFieldStyle(.plain)
                .focused($isAddFieldFocused)
                .onSubmit(addTask)

            priorityPicker

            Button {
                addTask()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 20))
            }
            .buttonStyle(.plain)
            .disabled(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .help("新增任务")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(glassSection(cornerRadius: 16))
    }

    private var pinButton: some View {
        Button {
            panelState.isPinned.toggle()
            onPinChanged(panelState.isPinned)
        } label: {
            Image(systemName: panelState.isPinned ? "pin.fill" : "pin")
                .font(.system(size: 12, weight: .bold))
                .frame(width: 30, height: 30)
        }
        .buttonStyle(GlassIconButtonStyle(isActive: panelState.isPinned))
        .help(panelState.isPinned ? "取消固定面板" : "固定面板")
    }

    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if taskViewMode == .review {
                    dailyReviewPanel
                } else if taskViewMode == .all {
                    if displayedTasks.isEmpty && displayedCompletedTasks.isEmpty {
                        emptyTasksView
                    } else {
                        ForEach(TaskPriority.allCases) { priority in
                            prioritySection(priority)
                        }
                        if !displayedCompletedTasks.isEmpty {
                            completedSection(tasks: displayedCompletedTasks, isExpanded: isCompletedSectionExpanded || isSearching)
                        }
                    }
                } else if displayedTasks.isEmpty {
                    emptyTasksView
                } else if taskViewMode == .today {
                    todaySection
                } else if taskViewMode == .completed {
                    completedSection(tasks: displayedCompletedTasks, isExpanded: true)
                } else if taskViewMode == .tags {
                    tagSections
                } else if taskViewMode == .projects {
                    projectSections
                } else {
                    flatTaskSection(title: taskViewMode.title, systemImage: taskViewMode.systemImage, tasks: displayedTasks)
                }

                if taskViewMode != .all, taskViewMode != .completed, !displayedCompletedTasks.isEmpty {
                    completedSection(tasks: displayedCompletedTasks, isExpanded: isCompletedSectionExpanded || isSearching)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxHeight: .infinity)
    }

    private var taskViewPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TaskViewMode.allCases) { mode in
                    Button {
                        taskViewMode = mode
                    } label: {
                        Label(mode.title, systemImage: mode.systemImage)
                            .frame(minWidth: 58)
                    }
                    .buttonStyle(SegmentedGlassButtonStyle(isSelected: taskViewMode == mode))
                }
            }
        }
    }

    private var displayedTasks: [TaskItem] {
        let tasks: [TaskItem]
        switch taskViewMode {
        case .today:
            tasks = store.todayTasks
        case .suggested:
            tasks = store.suggestedTodayTasks()
        case .high:
            tasks = store.incompleteTasks(for: .high)
        case .upcoming:
            tasks = store.upcomingTasks
        case .noDate:
            tasks = store.incompleteTasks.filter { $0.dueAt == nil }
        case .all:
            tasks = store.incompleteTasks
        case .completed:
            tasks = store.completedTasks
        case .tags, .projects:
            tasks = store.incompleteTasks
        case .review:
            tasks = []
        }
        return filtered(tasks)
    }

    private var displayedCompletedTasks: [TaskItem] {
        filtered(store.completedTasks)
    }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("搜索标题、备注、标签或项目", text: $searchText)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("清空搜索")
            }
        }
        .font(.system(size: 12.5, weight: .medium))
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(glassSection(cornerRadius: 14))
    }

    private var focusSummaryCard: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let focusTask = store.activeFocusTask ?? store.currentTask
            let isActivelyFocusing = focusTask?.focusStartedAt != nil
            HStack(spacing: 10) {
                Image(systemName: isActivelyFocusing ? "timer.circle.fill" : "smallcircle.filled.circle")
                    .foregroundStyle(isActivelyFocusing ? Color.accentColor : .secondary)
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 26, height: 26)
                    .background(.ultraThinMaterial, in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(focusTask?.title ?? "暂无当前任务")
                            .font(.system(size: 12.5, weight: .semibold))
                            .lineLimit(1)

                        if focusTask != nil {
                            Text(isActivelyFocusing ? "专注中" : "当前任务")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(isActivelyFocusing ? Color.accentColor : .secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                    }
                    Text(focusSummarySubtitle(task: focusTask, now: timeline.date))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                if let focusTask {
                    HStack(spacing: 6) {
                        focusControlButton(
                            systemName: focusTask.focusStartedAt == nil ? "play.fill" : "pause.fill",
                            help: focusTask.focusStartedAt == nil ? "开始专注" : "暂停专注",
                            isActive: focusTask.focusStartedAt != nil
                        ) {
                            store.toggleFocus(focusTask)
                        }

                        if focusTask.focusStartedAt != nil || focusTask.focusSeconds > 0 {
                            focusControlButton(
                                systemName: "stop.fill",
                                help: "停止专注"
                            ) {
                                store.stopFocus(focusTask)
                            }
                        }
                    }
                    .fixedSize(horizontal: true, vertical: false)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(glassSection(cornerRadius: 16))
        }
    }

    private func focusControlButton(
        systemName: String,
        help: String,
        isActive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11.5, weight: .bold))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(GlassIconButtonStyle(isActive: isActive))
        .help(help)
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(.orange)
                Text("今天")
                    .font(.system(size: 12, weight: .semibold))
                Text("\(store.todayTasks.count)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 2)

            ForEach(store.todayTasks, id: \.id) { task in
                TaskRowView(task: task)
                    .environmentObject(store)
                    .environmentObject(settings)
            }
        }
    }

    @ViewBuilder
    private func prioritySection(_ priority: TaskPriority) -> some View {
        let tasks = filtered(store.incompleteTasks(for: priority))
        if !tasks.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 7) {
                    Circle()
                        .fill(priority.tintColor(settings: settings))
                        .frame(width: 8, height: 8)
                    Text(priority.title)
                        .font(.system(size: 12, weight: .semibold))
                    Text("\(tasks.count)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 2)

                ForEach(tasks, id: \.id) { task in
                    TaskRowView(task: task)
                        .environmentObject(store)
                        .environmentObject(settings)
                }
            }
        }
    }

    private func flatTaskSection(title: String, systemImage: String, tasks: [TaskItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                Text("\(tasks.count)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 2)

            ForEach(tasks, id: \.id) { task in
                TaskRowView(task: task)
                    .environmentObject(store)
                    .environmentObject(settings)
            }
        }
    }

    private func completedSection(tasks: [TaskItem], isExpanded: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                isCompletedSectionExpanded.toggle()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(.secondary)
                    Text("已完成")
                        .font(.system(size: 12, weight: .semibold))
                    Text("\(tasks.count)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(isExpanded ? "收起" : "展开")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(taskViewMode == .completed || isSearching)
            .help(isExpanded ? "收起已完成任务" : "展开已完成任务")
            .padding(.horizontal, 2)

            if isExpanded {
                ForEach(tasks, id: \.id) { task in
                    CompletedTaskRow(task: task)
                        .environmentObject(store)
                }
            }
        }
    }

    private var tagSections: some View {
        VStack(spacing: 12) {
            if store.allTags.isEmpty {
                emptyTasksView
            } else {
                ForEach(store.allTags, id: \.self) { tag in
                    let tasks = filtered(store.incompleteTasks(tagged: tag))
                    if !tasks.isEmpty {
                        flatTaskSection(title: "#\(tag)", systemImage: "tag", tasks: tasks)
                    }
                }
            }
        }
    }

    private var projectSections: some View {
        VStack(spacing: 12) {
            if store.allProjects.isEmpty {
                emptyTasksView
            } else {
                ForEach(store.allProjects, id: \.self) { project in
                    let tasks = filtered(store.incompleteTasks(inProject: project))
                    if !tasks.isEmpty {
                        flatTaskSection(title: project, systemImage: "tray", tasks: tasks)
                    }
                }
            }
        }
    }

    private var dailyReviewPanel: some View {
        let review = store.dailyReview()
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                reviewMetric("完成", value: "\(review.completedToday.count)", systemImage: "checkmark.circle.fill", tint: .green)
                reviewMetric("专注", value: formattedDuration(review.focusSeconds), systemImage: "timer", tint: .blue)
                reviewMetric("推迟", value: "\(review.postponedToday.count)", systemImage: "clock.arrow.circlepath", tint: .orange)
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("今天完成", systemImage: "checklist.checked")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                if review.completedToday.isEmpty {
                    reviewEmptyText("还没有完成记录。")
                } else {
                    ForEach(review.completedToday.prefix(4), id: \.id) { task in
                        reviewTaskLine(task.title, systemImage: "checkmark")
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("明天建议关注", systemImage: "calendar.badge.clock")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                if review.tomorrowTasks.isEmpty {
                    reviewEmptyText("明天暂时没有安排。")
                } else {
                    ForEach(review.tomorrowTasks.prefix(4), id: \.id) { task in
                        reviewTaskLine(task.title, systemImage: "arrow.right")
                    }
                }
            }
        }
        .padding(13)
        .background(glassSection(cornerRadius: 18))
    }

    private var settingsDisplaySection: some View {
        settingsGroup(title: "显示", systemImage: "sparkles") {
            Toggle("显示悬浮岛", isOn: $settings.showCapsule)
            Divider()
                .opacity(0.26)
            Toggle("菜单栏标题", isOn: $settings.showTitleInMenuBar)
            Divider()
                .opacity(0.26)
            Toggle("暗夜模式", isOn: $settings.darkGlassMode)
        }
    }

    private var settingsCapsuleSection: some View {
        settingsGroup(title: "悬浮岛", systemImage: "capsule") {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Text("顶部间距")
                    Slider(value: capsuleYOffsetBinding, in: 0...80, step: 1)
                    Text("\(Int(settings.capsuleYOffset))")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .frame(width: 36, alignment: .trailing)
                }

                Divider()
                    .opacity(0.26)

                HStack(spacing: 12) {
                    Text("透明度")
                    Slider(value: capsuleTransparencyBinding, in: 0...100, step: 1)
                    Text("\(Int(settings.capsuleTransparencyPercent))%")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .frame(width: 36, alignment: .trailing)
                }

                Divider()
                    .opacity(0.26)

                HStack(spacing: 12) {
                    Text("背景颜色")
                    Spacer()
                    ColorPicker("", selection: capsuleBackgroundColorBinding, supportsOpacity: false)
                        .labelsHidden()
                        .frame(width: 42)
                        .help("修改悬浮窗玻璃底色")
                    Button("恢复默认") {
                        settings.capsuleBackgroundColorHex = AppSettings.defaultCapsuleBackgroundColorHex
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }

                Divider()
                    .opacity(0.26)

                HStack(spacing: 12) {
                    Text("文字颜色")
                    Spacer()
                    ColorPicker("", selection: capsuleTextColorBinding, supportsOpacity: false)
                        .labelsHidden()
                        .frame(width: 42)
                        .help("修改悬浮岛里的文字和图标颜色")
                    Button("自动") {
                        settings.capsuleTextColorHex = AppSettings.automaticCapsuleTextColorHex
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var settingsPrioritySection: some View {
        settingsGroup(title: "优先级颜色", systemImage: "paintpalette") {
            VStack(spacing: 10) {
                ForEach(TaskPriority.allCases) { priority in
                    priorityColorRow(priority)
                }

                Divider()
                    .opacity(0.26)

                HStack {
                    Text("颜色会同步到悬浮岛和任务列表")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("恢复默认") {
                        settings.resetPriorityColors()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
                .font(.system(size: 12, weight: .medium))
            }
        }
    }

    private var settingsFocusSection: some View {
        settingsGroup(title: "专注", systemImage: "timer") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Text("默认时长")
                    Slider(value: defaultFocusMinutesBinding, in: 5...180, step: 5)
                    Text("\(settings.defaultFocusMinutesInt) 分钟")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .frame(width: 58, alignment: .trailing)
                }

                HStack(spacing: 8) {
                    ForEach([15, 25, 45, 60], id: \.self) { minutes in
                        Button("\(minutes) 分钟") {
                            settings.defaultFocusMinutes = Double(minutes)
                        }
                        .buttonStyle(CompactGlassButtonStyle())
                    }
                    Spacer()
                }

                Text("任务没有单独设置时，会使用这个默认时长。单个任务可在任务详情里修改。")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var settingsShortcutSection: some View {
        settingsGroup(title: "快捷键", systemImage: "keyboard") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("快速新增")
                    Spacer()
                    Text(settings.quickAddShortcut.displayName)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .monospaced()
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 10) {
                    shortcutModifierMenu
                    shortcutKeyMenu

                    Spacer()

                    Button("恢复默认") {
                        settings.resetQuickAddShortcut()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }

                Text(settings.quickAddShortcutStatusMessage ?? "修改后立即生效。单独的 Command 组合容易触发系统菜单，这里只提供更适合全局快捷键的组合。")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(settings.quickAddShortcutStatusMessage == nil ? .secondary : Color.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var settingsActionsSection: some View {
        settingsGroup(title: "操作", systemImage: "slider.horizontal.3") {
            VStack(alignment: .leading, spacing: 10) {
                Picker("导出格式", selection: $selectedExportFormat) {
                    ForEach(TaskExportFormat.allCases) { format in
                        Text(format.title).tag(format)
                    }
                }
                .pickerStyle(.segmented)

                HStack(spacing: 10) {
                    Button {
                        store.reloadTasks()
                    } label: {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(CompactGlassButtonStyle())

                    Button {
                        exportTasks()
                    } label: {
                        Label("导出", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(CompactGlassButtonStyle())

                    Button {
                        importTasks()
                    } label: {
                        Label("导入", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(CompactGlassButtonStyle())

                    Spacer()
                }

                HStack(spacing: 10) {
                    Button {
                        Task { await importReminders() }
                    } label: {
                        Label("导入提醒", systemImage: "bell.badge")
                    }
                    .buttonStyle(CompactGlassButtonStyle())
                    .disabled(isReminderBusy)

                    Button {
                        Task { await exportReminders() }
                    } label: {
                        Label("导出提醒", systemImage: "bell.and.waves.left.and.right")
                    }
                    .buttonStyle(CompactGlassButtonStyle())
                    .disabled(isReminderBusy)

                    Spacer()
                }

                HStack(spacing: 10) {
                    Button {
                        onDismiss()
                    } label: {
                        Label("隐藏", systemImage: "minus")
                    }
                    .buttonStyle(CompactGlassButtonStyle())

                    Button {
                        NSApp.terminate(nil)
                    } label: {
                        Label("退出", systemImage: "power")
                    }
                    .buttonStyle(CompactGlassButtonStyle())

                    Spacer()
                }

                if let importExportMessage {
                    Text(importExportMessage)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }

    private func settingsGroup<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            content()
                .font(.system(size: 13))
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(glassSection(cornerRadius: 18))
    }

    private func addTask() {
        guard store.addTask(title: newTaskTitle, priority: selectedPriority) != nil else { return }
        newTaskTitle = ""
    }

    private func exportTasks() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "任务岛导出.\(selectedExportFormat.fileExtension)"
        panel.allowedContentTypes = contentTypes(for: selectedExportFormat)
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try store.exportTasks(to: url, format: selectedExportFormat)
            importExportMessage = "已导出到 \(url.lastPathComponent)"
        } catch {
            importExportMessage = "导出失败：\(error.localizedDescription)"
        }
    }

    private func importTasks() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json, .commaSeparatedText]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let count = try store.importTasks(from: url)
            importExportMessage = "已导入 \(count) 个新任务"
        } catch {
            importExportMessage = "导入失败：\(error.localizedDescription)"
        }
    }

    private func importReminders() async {
        isReminderBusy = true
        defer { isReminderBusy = false }
        do {
            let count = try await remindersBridge.importIncompleteReminders(into: store)
            importExportMessage = "已从提醒事项导入 \(count) 个任务"
        } catch {
            importExportMessage = "提醒事项导入失败：\(error.localizedDescription)"
        }
    }

    private func exportReminders() async {
        isReminderBusy = true
        defer { isReminderBusy = false }
        do {
            let count = try await remindersBridge.exportIncompleteTasks(from: store)
            importExportMessage = "已导出 \(count) 个任务到提醒事项"
        } catch {
            importExportMessage = "提醒事项导出失败：\(error.localizedDescription)"
        }
    }

    private func contentTypes(for format: TaskExportFormat) -> [UTType] {
        switch format {
        case .json:
            return [.json]
        case .markdown:
            return [UTType(filenameExtension: "md") ?? .plainText]
        case .csv:
            return [.commaSeparatedText]
        }
    }

    private var priorityPicker: some View {
        Menu {
            ForEach(TaskPriority.allCases) { priority in
                Button {
                    selectedPriority = priority
                } label: {
                    Label(priority.title, systemImage: priority.symbolName)
                }
            }
        } label: {
            HStack(spacing: 5) {
                Circle()
                    .fill(selectedPriority.tintColor(settings: settings))
                    .frame(width: 7, height: 7)
                Text(selectedPriority.shortTitle)
                    .font(.system(size: 11, weight: .semibold))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .stroke(selectedPriority.tintColor(settings: settings).opacity(0.32), lineWidth: 1)
        }
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .help("选择优先级")
    }

    private var shortcutModifierMenu: some View {
        Menu {
            ForEach(TaskIslandShortcut.modifierChoices) { choice in
                Button {
                    settings.quickAddShortcutModifiersRawValue = choice.rawValue
                } label: {
                    Label(choice.displayName, systemImage: settings.quickAddShortcutModifiersRawValue == choice.rawValue ? "checkmark" : "")
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "command")
                Text(TaskIslandShortcut.modifierDisplayName(rawValue: settings.quickAddShortcutModifiersRawValue))
            }
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.30), lineWidth: 1)
            }
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .help("选择修饰键")
    }

    private var shortcutKeyMenu: some View {
        Menu {
            ForEach(TaskIslandShortcut.keyChoices) { choice in
                Button {
                    settings.quickAddShortcutKeyCode = choice.keyCode
                } label: {
                    Label(choice.displayName, systemImage: settings.quickAddShortcutKeyCode == choice.keyCode ? "checkmark" : "")
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "keyboard")
                Text(TaskIslandShortcut.keyDisplayName(keyCode: settings.quickAddShortcutKeyCode))
            }
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.30), lineWidth: 1)
            }
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .help("选择按键")
    }

    private var capsuleYOffsetBinding: Binding<Double> {
        Binding(
            get: { settings.capsuleYOffset },
            set: { newValue in
                settings.hasCapsuleCustomPosition = false
                settings.capsuleYOffset = newValue
            }
        )
    }

    private var capsuleTransparencyBinding: Binding<Double> {
        Binding(
            get: { settings.capsuleTransparencyPercent },
            set: { newValue in
                settings.capsuleTransparencyPercent = AppSettings.clampedTransparency(newValue)
            }
        )
    }

    private var defaultFocusMinutesBinding: Binding<Double> {
        Binding(
            get: { settings.defaultFocusMinutes },
            set: { newValue in
                settings.defaultFocusMinutes = AppSettings.clampedFocusMinutes(newValue)
            }
        )
    }

    private var capsuleBackgroundColorBinding: Binding<Color> {
        Binding(
            get: {
                Color(taskIslandHex: settings.capsuleBackgroundColorHex)
                    ?? Color(taskIslandHex: AppSettings.defaultCapsuleBackgroundColorHex)
                    ?? .cyan
            },
            set: { newColor in
                settings.capsuleBackgroundColorHex = newColor.taskIslandHexString
                    ?? AppSettings.defaultCapsuleBackgroundColorHex
            }
        )
    }

    private var capsuleTextColorBinding: Binding<Color> {
        Binding(
            get: { capsuleTextColorForPicker },
            set: { newColor in
                settings.capsuleTextColorHex = newColor.taskIslandHexString
                    ?? AppSettings.automaticCapsuleTextColorHex
            }
        )
    }

    private var capsuleTextColorForPicker: Color {
        Color(taskIslandHex: settings.capsuleTextColorHex)
            ?? (settings.darkGlassMode ? Color.white : Color(red: 0.06, green: 0.20, blue: 0.24))
    }

    private var headerSubtitle: String {
        let count = store.incompleteCount
        if count == 0 {
            return "暂无待办"
        }
        if store.todayTasks.count > 0 {
            return "今天 \(store.todayTasks.count) 个 / 全部 \(count) 个"
        }
        if count == 1 {
            return "1 个待办"
        }
        return "\(count) 个待办"
    }

    private var taskCountBadge: some View {
        Text("\(store.incompleteCount)")
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .monospacedDigit()
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.35), lineWidth: 1)
            }
    }

    private func overviewPill(_ priority: TaskPriority) -> some View {
        let count = store.priorityCounts[priority, default: 0]
        let tint = priority.tintColor(settings: settings)
        return HStack(spacing: 6) {
            Circle()
                .fill(tint)
                .frame(width: 8, height: 8)
            Text(priority.shortTitle)
                .font(.system(size: 11, weight: .semibold))
            Text("\(count)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .stroke(tint.opacity(count > 0 ? 0.34 : 0.14), lineWidth: 1)
        }
    }

    private func priorityColorRow(_ priority: TaskPriority) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(priority.tintColor(settings: settings))
                .frame(width: 10, height: 10)
                .shadow(color: priority.tintColor(settings: settings).opacity(0.45), radius: 4)

            Text(priority.title)
                .font(.system(size: 13, weight: .medium))

            Spacer()

            ColorPicker("", selection: priorityColorBinding(priority), supportsOpacity: false)
                .labelsHidden()
                .frame(width: 42)
                .help("修改\(priority.title)颜色")
        }
        .padding(.vertical, 2)
    }

    private func priorityColorBinding(_ priority: TaskPriority) -> Binding<Color> {
        Binding(
            get: {
                Color(taskIslandHex: settings.priorityColorHex(for: priority)) ?? priority.defaultTintColor
            },
            set: { newColor in
                settings.setPriorityColorHex(
                    newColor.taskIslandHexString ?? priority.defaultColorHex,
                    for: priority
                )
            }
        )
    }

    private var emptyTasksView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.green)

            Text("暂无待办")
                .font(.system(size: 14, weight: .semibold))

            Text(emptyTasksSubtitle)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 138)
        .background(glassSection(cornerRadius: 18))
    }

    private var emptyTasksSubtitle: String {
        if taskViewMode == .today, !store.incompleteTasks.isEmpty {
            return "今天队列为空，可以到全部里点“加入今天”。"
        }
        if taskViewMode == .tags {
            return "输入任务时加 #标签，就会出现在这里。"
        }
        if taskViewMode == .projects {
            return "输入任务时加 +项目，就会出现在这里。"
        }
        return "现在很安静。"
    }

    private func filtered(_ tasks: [TaskItem]) -> [TaskItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return tasks }

        return tasks.filter { task in
            task.title.localizedCaseInsensitiveContains(query)
                || task.notes.localizedCaseInsensitiveContains(query)
                || task.tags.contains { $0.localizedCaseInsensitiveContains(query) }
                || (task.projectName?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    private func focusSummarySubtitle(task: TaskItem?, now: Date) -> String {
        guard let task else { return "添加一个任务后就可以开始专注。" }

        if task.focusStartedAt == nil {
            let accumulated = store.focusSeconds(for: task, now: now)
            if accumulated > 0 {
                return "已专注 \(formattedDuration(accumulated))，可继续这一轮。"
            }
            return "用于顶部快捷专注，一键开始 \(focusTargetMinutes(for: task)) 分钟。"
        }

        return "专注中，剩余 \(formattedDuration(store.focusRemainingSeconds(for: task, now: now, defaultMinutes: settings.defaultFocusMinutesInt)))。"
    }

    private func focusTargetMinutes(for task: TaskItem) -> Int {
        store.focusTargetMinutes(for: task, defaultMinutes: settings.defaultFocusMinutesInt)
    }

    private func reviewMetric(_ title: String, value: String, systemImage: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private func reviewTaskLine(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.system(size: 12.5, weight: .medium))
                .lineLimit(1)
            Spacer(minLength: 4)
        }
    }

    private func reviewEmptyText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 2)
    }

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let totalSeconds = max(Int(seconds.rounded()), 0)
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60
        if minutes >= 60 {
            return "\(minutes / 60)时\(minutes % 60)分"
        }
        return "\(minutes):\(String(format: "%02d", remainingSeconds))"
    }

    private var panelShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
    }

    private var panelTint: some View {
        panelShape
            .fill(
                LinearGradient(
                    colors: panelTintColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var panelHighlights: some View {
        ZStack {
            panelShape
                .fill(
                    LinearGradient(
                        colors: panelHighlightColors,
                        startPoint: .topLeading,
                        endPoint: UnitPoint(x: 0.72, y: 0.62)
                    )
                )
                .blendMode(.plusLighter)
                .opacity(0.72)

            panelShape
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(settings.darkGlassMode ? 0.14 : 0.20),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadius: 18,
                        endRadius: 270
                    )
                )
                .blendMode(.plusLighter)

            panelShape
                .stroke(.white.opacity(settings.darkGlassMode ? 0.16 : 0.22), lineWidth: 4)
                .blur(radius: 5)
                .padding(2)
                .opacity(settings.darkGlassMode ? 0.34 : 0.42)
        }
        .clipShape(panelShape)
    }

    @ViewBuilder
    private var darkPanelShade: some View {
        if settings.darkGlassMode {
            panelShape
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.30),
                            Color(red: 0.02, green: 0.05, blue: 0.08).opacity(0.26),
                            Color.black.opacity(0.38)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(panelShape)
        }
    }

    private var panelStroke: some View {
        panelShape
            .stroke(
                LinearGradient(
                    colors: panelStrokeColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }

    private func glassSection(cornerRadius: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return shape
            .fill(.ultraThinMaterial)
            .overlay {
                shape
                    .fill(
                        LinearGradient(
                            colors: sectionTintColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                shape
                    .stroke(.white.opacity(settings.darkGlassMode ? 0.20 : 0.38), lineWidth: 1)
            }
    }

    private var panelTintColors: [Color] {
        if settings.darkGlassMode {
            return [
                Color.black.opacity(0.34),
                Color(red: 0.08, green: 0.13, blue: 0.19).opacity(0.34),
                Color(red: 0.12, green: 0.28, blue: 0.34).opacity(0.18),
                Color(red: 0.16, green: 0.13, blue: 0.24).opacity(0.18)
            ]
        }

        return [
            Color.white.opacity(0.13),
            Color(red: 0.57, green: 0.90, blue: 1.0).opacity(0.09),
            Color(red: 0.70, green: 1.0, blue: 0.70).opacity(0.06),
            Color(red: 1.0, green: 0.82, blue: 0.96).opacity(0.05)
        ]
    }

    private var panelHighlightColors: [Color] {
        if settings.darkGlassMode {
            return [
                .white.opacity(0.15),
                Color(red: 0.48, green: 0.88, blue: 1.0).opacity(0.08),
                .clear
            ]
        }

        return [
            .white.opacity(0.34),
            .white.opacity(0.09),
            .clear
        ]
    }

    private var panelStrokeColors: [Color] {
        if settings.darkGlassMode {
            return [
                .white.opacity(0.42),
                Color(red: 0.44, green: 0.86, blue: 1.0).opacity(0.26),
                .white.opacity(0.10)
            ]
        }

        return [
            .white.opacity(0.78),
            Color(red: 0.70, green: 0.94, blue: 1.0).opacity(0.35),
            .white.opacity(0.20)
        ]
    }

    private var sectionTintColors: [Color] {
        if settings.darkGlassMode {
            return [
                Color.black.opacity(0.20),
                .white.opacity(0.030),
                Color(red: 0.22, green: 0.56, blue: 0.76).opacity(0.035)
            ]
        }

        return [
            .white.opacity(0.12),
            .white.opacity(0.035),
            Color(red: 0.55, green: 0.92, blue: 1.0).opacity(0.035)
        ]
    }
}

enum TaskViewMode: String, CaseIterable, Identifiable {
    case all
    case today
    case suggested
    case high
    case upcoming
    case noDate
    case tags
    case projects
    case completed
    case review

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today:
            return "今天"
        case .suggested:
            return "建议"
        case .high:
            return "高优"
        case .upcoming:
            return "即将"
        case .noDate:
            return "无日期"
        case .tags:
            return "标签"
        case .projects:
            return "项目"
        case .all:
            return "全部"
        case .completed:
            return "完成"
        case .review:
            return "回顾"
        }
    }

    var systemImage: String {
        switch self {
        case .today:
            return "sun.max"
        case .suggested:
            return "sparkles"
        case .high:
            return "flag.fill"
        case .upcoming:
            return "calendar"
        case .noDate:
            return "calendar.badge.exclamationmark"
        case .tags:
            return "tag"
        case .projects:
            return "tray"
        case .all:
            return "tray.full"
        case .completed:
            return "checkmark.circle"
        case .review:
            return "chart.bar"
        }
    }
}

enum TaskPanelSettingsAnchor: Hashable {
    case display
    case focus
    case priority
    case capsule
    case shortcuts
    case actions
}

private struct CompletedTaskRow: View {
    @EnvironmentObject private var store: TaskStore
    let task: TaskItem

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.green)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(.secondary)
                    .strikethrough(true)
                    .lineLimit(1)

                if let completedAt = task.completedAt {
                    Text(completedText(completedAt))
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer(minLength: 8)

            Button {
                store.delete(task)
            } label: {
                Image(systemName: "trash")
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(GlassIconButtonStyle())
            .help("删除任务")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.white.opacity(0.20), lineWidth: 1)
        }
    }

    private func completedText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = Calendar.current.isDateInToday(date) ? "今天 HH:mm" : "M月d日 HH:mm"
        return formatter.string(from: date)
    }
}

private struct GlassIconButtonStyle: ButtonStyle {
    var isActive = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isActive ? Color.accentColor : .primary)
            .background(.ultraThinMaterial, in: Circle())
            .background(isActive ? Color.accentColor.opacity(0.16) : Color.clear, in: Circle())
            .overlay {
                Circle()
                    .stroke(
                        isActive
                            ? Color.accentColor.opacity(configuration.isPressed ? 0.30 : 0.46)
                            : .white.opacity(configuration.isPressed ? 0.22 : 0.44),
                        lineWidth: 1
                    )
            }
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct SegmentedGlassButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(isSelected ? .primary : .secondary)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color.white.opacity(0.035)))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.white.opacity(isSelected ? 0.42 : 0.18), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.14), value: isSelected)
            .animation(.easeInOut(duration: 0.10), value: configuration.isPressed)
    }
}

private struct FilledGlassButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                tint.opacity(configuration.isPressed ? 0.30 : 0.42),
                                Color.white.opacity(configuration.isPressed ? 0.14 : 0.24)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.42), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct CompactGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(.white.opacity(configuration.isPressed ? 0.22 : 0.34), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}
