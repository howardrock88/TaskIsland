import SwiftUI
import TaskIslandWidgetSupport
import WidgetKit

private func systemWidgetText(_ chinese: String, _ english: String) -> String {
    guard let preferredLanguage = Locale.preferredLanguages.first else {
        return english
    }

    let normalized = preferredLanguage.replacingOccurrences(of: "_", with: "-").lowercased()
    return normalized == "zh" || normalized.hasPrefix("zh-") ? chinese : english
}

private struct TaskIslandWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: TaskWidgetSnapshot
}

private struct TaskIslandTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> TaskIslandWidgetEntry {
        TaskIslandWidgetEntry(date: Date(), snapshot: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskIslandWidgetEntry) -> Void) {
        let snapshot = context.isPreview ? TaskWidgetSnapshot.preview : currentSnapshot()
        completion(TaskIslandWidgetEntry(date: Date(), snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskIslandWidgetEntry>) -> Void) {
        let entry = TaskIslandWidgetEntry(date: Date(), snapshot: currentSnapshot())
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 10, to: entry.date) ?? entry.date.addingTimeInterval(600)
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }

    private func currentSnapshot() -> TaskWidgetSnapshot {
        TaskWidgetSnapshotStore().read() ?? TaskWidgetSnapshot(
            generatedAt: Date(),
            languageCode: Locale.current.language.languageCode?.identifier ?? "en"
        )
    }
}

struct TodayOverviewWidget: Widget {
    let kind = "TaskIslandTodayOverviewWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskIslandTimelineProvider()) { entry in
            TodayOverviewWidgetView(entry: entry)
                .widgetURL(URL(string: "taskisland://show"))
        }
        .configurationDisplayName(systemWidgetText("任务岛·今日", "TaskIsland Today"))
        .description(systemWidgetText("当前任务、今日队列和红黄绿数字岛。", "Current task, today's queue, and the red-yellow-green task island."))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct FocusWidget: Widget {
    let kind = "TaskIslandFocusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskIslandTimelineProvider()) { entry in
            FocusWidgetView(entry: entry)
                .widgetURL(URL(string: "taskisland://focus"))
        }
        .configurationDisplayName(systemWidgetText("任务岛·专注", "TaskIsland Focus"))
        .description(systemWidgetText("当前专注任务、剩余时间和优先级信号。", "Focus status with the TaskIsland priority signal."))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct DailyReviewWidget: Widget {
    let kind = "TaskIslandDailyReviewWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskIslandTimelineProvider()) { entry in
            DailyReviewWidgetView(entry: entry)
                .widgetURL(URL(string: "taskisland://show?view=review"))
        }
        .configurationDisplayName(systemWidgetText("任务岛·回顾", "TaskIsland Review"))
        .description(systemWidgetText("查看今日完成情况和明日建议。", "A quiet daily review with completed tasks and tomorrow's suggestions."))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct TaskIslandWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TodayOverviewWidget()
        FocusWidget()
        DailyReviewWidget()
    }
}

private struct TodayOverviewWidgetView: View {
    private static let maximumVisibleTaskCount = 3

    @Environment(\.widgetFamily) private var family
    let entry: TaskIslandWidgetEntry

    private var snapshot: TaskWidgetSnapshot { entry.snapshot }

    var body: some View {
        TaskIslandWidgetShell(snapshot: snapshot) {
            switch family {
            case .systemSmall:
                small
            case .systemLarge:
                large
            default:
                medium
            }
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 10) {
            WidgetHeader(title: t("今天", "Today"), systemImage: "sun.max.fill", snapshot: snapshot)
            Spacer(minLength: 2)
            PrioritySignalIsland(snapshot: snapshot, signal: displayedPrioritySignal, prominence: .hero)
            Spacer(minLength: 2)
            Text(summaryText)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(primaryText)
                .lineLimit(1)
        }
    }

    private var medium: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                WidgetHeader(title: t("今天", "Today"), systemImage: "sun.max.fill", snapshot: snapshot)
                Spacer(minLength: 8)
                PrioritySignalIsland(snapshot: snapshot, signal: displayedPrioritySignal, prominence: .compact)
            }
            WidgetTaskList(snapshot: snapshot, tasks: visibleTasks, emptyText: t("今天很清爽", "All clear today"))
        }
    }

    private var large: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top) {
                WidgetHeader(title: t("今日概览", "Today Overview"), systemImage: "list.bullet.rectangle", snapshot: snapshot)
                Spacer(minLength: 8)
                PrioritySignalIsland(snapshot: snapshot, signal: displayedPrioritySignal, prominence: .regular)
            }
            HStack(spacing: 8) {
                ReviewMetric(snapshot: snapshot, title: t("完成", "Done"), value: "\(snapshot.review.completedTodayCount)", systemImage: "checkmark.circle.fill", tint: .green)
                ReviewMetric(snapshot: snapshot, title: t("今日", "Today"), value: "\(snapshot.todayTotalCount)", systemImage: "sun.max.fill", tint: .orange)
            }
            WidgetTaskList(snapshot: snapshot, tasks: visibleTasks, emptyText: t("今天很清爽", "All clear today"))
        }
    }

    private var primaryTask: TaskWidgetTask? {
        snapshot.currentTask ?? snapshot.focusTask ?? snapshot.todayTasks.first ?? snapshot.suggestedTasks.first
    }

    private var summaryText: String {
        if snapshot.todayTotalCount == 0 {
            return t("今天很清爽", "All clear today")
        }
        return t("今天 \(snapshot.todayTotalCount) 个", "\(snapshot.todayTotalCount) tasks today")
    }

    private var displayedPrioritySignal: TaskWidgetPrioritySignal {
        guard !snapshot.todayTasks.isEmpty else {
            return snapshot.prioritySignal
        }

        return snapshot.todayTasks.reduce(into: TaskWidgetPrioritySignal()) { signal, task in
            switch task.priority {
            case .high:
                signal.high += 1
            case .medium:
                signal.medium += 1
            case .low:
                signal.low += 1
            }
        }
    }

    private var visibleTasks: [TaskWidgetTask] {
        let tasks = snapshot.todayTasks.isEmpty ? snapshot.suggestedTasks : snapshot.todayTasks
        guard let primaryTask else {
            return Array(tasks.prefix(Self.maximumVisibleTaskCount))
        }
        let remainingTasks = tasks.filter { $0.id != primaryTask.id }
        return [primaryTask] + remainingTasks.prefix(Self.maximumVisibleTaskCount - 1)
    }

    private var primaryText: Color { snapshot.primaryTextColor }
    private func t(_ chinese: String, _ english: String) -> String { snapshot.text(chinese, english) }
}

private struct FocusWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TaskIslandWidgetEntry

    private var snapshot: TaskWidgetSnapshot { entry.snapshot }
    private var task: TaskWidgetTask? { snapshot.focusTask ?? snapshot.currentTask ?? snapshot.todayTasks.first }

    var body: some View {
        TaskIslandWidgetShell(snapshot: snapshot) {
            switch family {
            case .systemSmall:
                small
            case .systemLarge:
                large
            default:
                medium
            }
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 8) {
            WidgetHeader(title: t("专注", "Focus"), systemImage: "timer", snapshot: snapshot)
            Spacer(minLength: 2)
            if let task {
                PriorityLamp(snapshot: snapshot, priority: task.priority, size: 13, glow: true)
                Text(task.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(snapshot.primaryTextColor)
                    .lineLimit(2)
                Text(focusTimeText(task))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(snapshot.primaryTextColor)
                    .lineLimit(1)
            } else {
                EmptyWidgetState(snapshot: snapshot, title: t("暂无当前任务", "No current task"), subtitle: t("打开任务岛开始专注", "Open TaskIsland to focus"))
            }
        }
    }

    private var medium: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    WidgetHeader(title: t("专注", "Focus"), systemImage: "timer", snapshot: snapshot)
                    Spacer(minLength: 8)
                    PrioritySignalIsland(snapshot: snapshot, prominence: .mini)
                }
                CurrentTaskCard(snapshot: snapshot, task: task, mode: .focus)
                Text(t("点击回到任务岛继续处理", "Tap to continue in TaskIsland"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(snapshot.secondaryTextColor)
                    .lineLimit(1)
            }

            FocusTimeBadge(snapshot: snapshot, task: task)
        }
    }

    private var large: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top) {
                WidgetHeader(title: t("专注状态", "Focus Status"), systemImage: "timer.circle.fill", snapshot: snapshot)
                Spacer(minLength: 8)
                PrioritySignalIsland(snapshot: snapshot, prominence: .regular)
            }
            HStack(spacing: 12) {
                CurrentTaskCard(snapshot: snapshot, task: task, mode: .focus)
                FocusTimeBadge(snapshot: snapshot, task: task)
            }
            HStack(spacing: 8) {
                ReviewMetric(snapshot: snapshot, title: t("今日专注", "Focus"), value: formattedDuration(snapshot.review.focusSeconds), systemImage: "timer", tint: .blue)
                ReviewMetric(snapshot: snapshot, title: t("待办", "Tasks"), value: "\(snapshot.prioritySignal.total)", systemImage: "circle.grid.cross", tint: snapshot.paletteColor(.medium))
            }
            WidgetTaskList(snapshot: snapshot, tasks: Array(snapshot.suggestedTasks.prefix(3)), emptyText: t("暂无建议任务", "No suggested tasks"))
        }
    }

    private func focusTimeText(_ task: TaskWidgetTask) -> String {
        if task.isFocusing {
            return formattedDuration(task.focusRemainingSeconds(now: entry.date))
        }
        let elapsed = task.focusElapsedSeconds(now: entry.date)
        return elapsed > 0 ? formattedDuration(elapsed) : "\(task.focusTargetMinutes)m"
    }

    private func t(_ chinese: String, _ english: String) -> String { snapshot.text(chinese, english) }
}

private struct DailyReviewWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TaskIslandWidgetEntry

    private var snapshot: TaskWidgetSnapshot { entry.snapshot }

    var body: some View {
        TaskIslandWidgetShell(snapshot: snapshot) {
            switch family {
            case .systemSmall:
                small
            case .systemLarge:
                large
            default:
                medium
            }
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 10) {
            WidgetHeader(title: t("回顾", "Review"), systemImage: "checklist.checked", snapshot: snapshot)
            Spacer(minLength: 2)
            PrioritySignalIsland(snapshot: snapshot, prominence: .compact)
            Spacer(minLength: 2)
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("\(snapshot.review.completedTodayCount)")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text(t("已完成", "done"))
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(snapshot.primaryTextColor)
            Text(formattedDuration(snapshot.review.focusSeconds))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(snapshot.secondaryTextColor)
                .lineLimit(1)
        }
    }

    private var medium: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                WidgetHeader(title: t("每日回顾", "Daily Review"), systemImage: "checklist.checked", snapshot: snapshot)
                Spacer(minLength: 8)
                PrioritySignalIsland(snapshot: snapshot, prominence: .compact)
            }
            HStack(spacing: 8) {
                ReviewMetric(snapshot: snapshot, title: t("完成", "Done"), value: "\(snapshot.review.completedTodayCount)", systemImage: "checkmark.circle.fill", tint: .green)
                ReviewMetric(snapshot: snapshot, title: t("专注", "Focus"), value: formattedDuration(snapshot.review.focusSeconds), systemImage: "timer", tint: .blue)
                ReviewMetric(snapshot: snapshot, title: t("推迟", "Later"), value: "\(snapshot.review.postponedTodayCount)", systemImage: "clock.arrow.circlepath", tint: .orange)
            }
            WidgetTaskList(snapshot: snapshot, tasks: Array(snapshot.review.completedToday.prefix(2)), emptyText: t("还没有完成记录", "No completed tasks yet"))
        }
    }

    private var large: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top) {
                WidgetHeader(title: t("每日回顾", "Daily Review"), systemImage: "checklist.checked", snapshot: snapshot)
                Spacer(minLength: 8)
                PrioritySignalIsland(snapshot: snapshot, prominence: .regular)
            }
            HStack(spacing: 8) {
                ReviewMetric(snapshot: snapshot, title: t("完成", "Done"), value: "\(snapshot.review.completedTodayCount)", systemImage: "checkmark.circle.fill", tint: .green)
                ReviewMetric(snapshot: snapshot, title: t("专注", "Focus"), value: formattedDuration(snapshot.review.focusSeconds), systemImage: "timer", tint: .blue)
                ReviewMetric(snapshot: snapshot, title: t("推迟", "Later"), value: "\(snapshot.review.postponedTodayCount)", systemImage: "clock.arrow.circlepath", tint: .orange)
            }
            HStack(alignment: .top, spacing: 10) {
                WidgetTaskList(snapshot: snapshot, title: t("今天完成", "Completed"), tasks: Array(snapshot.review.completedToday.prefix(4)), emptyText: t("暂无完成", "None yet"))
                WidgetTaskList(snapshot: snapshot, title: t("明天建议", "Tomorrow"), tasks: Array(snapshot.review.suggestedTomorrow.prefix(3)), emptyText: t("暂无安排", "Nothing scheduled"))
            }
        }
    }

    private func t(_ chinese: String, _ english: String) -> String { snapshot.text(chinese, english) }
}

private struct TaskIslandWidgetShell<Content: View>: View {
    let snapshot: TaskWidgetSnapshot
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            content
                .padding(14)
        }
        .containerBackground(for: .widget) {
            WidgetBackground(snapshot: snapshot)
        }
    }
}

private struct WidgetBackground: View {
    let snapshot: TaskWidgetSnapshot

    var body: some View {
        let tint = snapshot.glassTintColor
        ZStack {
            tint.opacity(snapshot.palette.isDarkGlassMode ? 0.24 : 0.34)
            LinearGradient(
                colors: [
                    Color.white.opacity(snapshot.palette.isDarkGlassMode ? 0.045 : 0.16),
                    tint.opacity(snapshot.palette.isDarkGlassMode ? 0.10 : 0.20),
                    Color.black.opacity(snapshot.palette.isDarkGlassMode ? 0.20 : 0.035)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

private enum SignalProminence {
    case mini
    case compact
    case regular
    case hero

    var dotSize: CGFloat {
        switch self {
        case .mini: return 7
        case .compact: return 8
        case .regular: return 9
        case .hero: return 13
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .mini: return 10
        case .compact: return 12
        case .regular: return 13
        case .hero: return 24
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .mini: return 8
        case .compact: return 10
        case .regular: return 12
        case .hero: return 15
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .mini: return 5
        case .compact: return 6
        case .regular: return 7
        case .hero: return 11
        }
    }

    var spacing: CGFloat {
        switch self {
        case .mini: return 7
        case .compact: return 10
        case .regular: return 12
        case .hero: return 13
        }
    }
}

private struct PrioritySignalIsland: View {
    let snapshot: TaskWidgetSnapshot
    var signal: TaskWidgetPrioritySignal? = nil
    let prominence: SignalProminence

    private var displayedSignal: TaskWidgetPrioritySignal {
        signal ?? snapshot.prioritySignal
    }

    var body: some View {
        HStack(spacing: prominence.spacing) {
            signal(priority: .high, count: displayedSignal.high)
            signal(priority: .medium, count: displayedSignal.medium)
            signal(priority: .low, count: displayedSignal.low)
        }
        .padding(.horizontal, prominence.horizontalPadding)
        .padding(.vertical, prominence.verticalPadding)
        .background {
            Capsule(style: .continuous)
                .fill(snapshot.glassTintColor.opacity(snapshot.palette.isDarkGlassMode ? 0.22 : 0.28))
                .overlay {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(snapshot.palette.isDarkGlassMode ? 0.055 : 0.20))
                }
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(snapshot.palette.isDarkGlassMode ? 0.18 : 0.46), lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(snapshot.palette.isDarkGlassMode ? 0.22 : 0.12), radius: 8, x: 0, y: 5)
        }
        .accessibilityLabel(snapshot.text(
            "高优 \(displayedSignal.high)，中优 \(displayedSignal.medium)，低优 \(displayedSignal.low)",
            "High \(displayedSignal.high), medium \(displayedSignal.medium), low \(displayedSignal.low)"
        ))
    }

    private func signal(priority: TaskWidgetPriority, count: Int) -> some View {
        HStack(spacing: max(prominence.dotSize * 0.42, 4)) {
            PriorityLamp(snapshot: snapshot, priority: priority, size: prominence.dotSize, glow: count > 0)
                .opacity(count > 0 ? 1 : 0.32)
            Text("\(count)")
                .font(.system(size: prominence.fontSize, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(snapshot.primaryTextColor.opacity(count > 0 ? 1 : 0.58))
                .contentTransition(.numericText())
        }
    }
}

private struct PriorityLamp: View {
    let snapshot: TaskWidgetSnapshot
    let priority: TaskWidgetPriority
    let size: CGFloat
    var glow: Bool = false

    var body: some View {
        Circle()
            .fill(snapshot.paletteColor(priority))
            .frame(width: size, height: size)
            .shadow(color: snapshot.paletteColor(priority).opacity(glow ? 0.46 : 0), radius: glow ? size * 0.48 : 0)
            .overlay {
                Circle()
                    .stroke(Color.white.opacity(snapshot.palette.isDarkGlassMode ? 0.26 : 0.50), lineWidth: max(size * 0.08, 0.75))
            }
    }
}

private enum CurrentTaskCardMode {
    case today
    case focus
}

private struct CurrentTaskCard: View {
    let snapshot: TaskWidgetSnapshot
    let task: TaskWidgetTask?
    let mode: CurrentTaskCardMode

    var body: some View {
        Group {
            if let task {
                HStack(spacing: 9) {
                    PriorityLamp(snapshot: snapshot, priority: task.priority, size: 10, glow: true)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(task.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(snapshot.primaryTextColor)
                            .lineLimit(1)

                        if let subtitle = subtitle(for: task) {
                            Text(subtitle)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(snapshot.secondaryTextColor)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 8)

                    Image(systemName: task.isFocusing ? "pause.fill" : "smallcircle.filled.circle")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(task.isFocusing ? Color.blue : snapshot.secondaryTextColor)
                }
            } else {
                EmptyWidgetState(snapshot: snapshot, title: snapshot.text("暂无当前任务", "No current task"), subtitle: snapshot.text("打开任务岛开始使用", "Open TaskIsland to start"))
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background(WidgetGlassCard(snapshot: snapshot, cornerRadius: 15))
    }

    private func subtitle(for task: TaskWidgetTask) -> String? {
        if mode == .focus {
            if task.isFocusing {
                return snapshot.text("专注中，剩 \(formattedDuration(task.focusRemainingSeconds()))", "Focusing, \(formattedDuration(task.focusRemainingSeconds())) left")
            }
            return snapshot.text("点击回到任务岛开始专注", "Tap to focus in TaskIsland")
        }

        if task.isFocusing {
            return snapshot.text("专注中", "Focusing")
        }
        if task.isCurrent {
            return snapshot.text("当前任务", "Current")
        }
        if snapshot.todayTasks.contains(where: { $0.id == task.id }) {
            return task.dueAt.map { formattedDate($0, snapshot: snapshot) } ?? snapshot.text("今日任务", "Today task")
        }
        return task.dueAt.map { formattedDate($0, snapshot: snapshot) }
    }
}

private struct FocusTimeBadge: View {
    let snapshot: TaskWidgetSnapshot
    let task: TaskWidgetTask?

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: task?.isFocusing == true ? "timer.circle.fill" : "timer")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(task?.isFocusing == true ? Color.blue : snapshot.secondaryTextColor)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(snapshot.primaryTextColor)
                .minimumScaleFactor(0.72)
                .lineLimit(1)

            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(snapshot.secondaryTextColor)
                .lineLimit(1)
        }
        .frame(minWidth: 68, maxWidth: 86, minHeight: 82)
        .padding(.horizontal, 8)
        .padding(.vertical, 9)
        .background(WidgetGlassCard(snapshot: snapshot, cornerRadius: 18))
    }

    private var value: String {
        guard let task else { return "--" }
        if task.isFocusing {
            return formattedDuration(task.focusRemainingSeconds())
        }
        let elapsed = task.focusElapsedSeconds()
        return elapsed > 0 ? formattedDuration(elapsed) : "\(task.focusTargetMinutes)m"
    }

    private var label: String {
        guard let task else { return snapshot.text("暂无", "None") }
        return task.isFocusing ? snapshot.text("剩余", "left") : snapshot.text("目标", "target")
    }
}

private struct WidgetTaskList: View {
    let snapshot: TaskWidgetSnapshot
    var title: String?
    let tasks: [TaskWidgetTask]
    let emptyText: String

    init(snapshot: TaskWidgetSnapshot, title: String? = nil, tasks: [TaskWidgetTask], emptyText: String) {
        self.snapshot = snapshot
        self.title = title
        self.tasks = tasks
        self.emptyText = emptyText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let title {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(snapshot.secondaryTextColor)
                    .lineLimit(1)
            }

            if tasks.isEmpty {
                Text(emptyText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(snapshot.secondaryTextColor)
                    .lineLimit(1)
                    .padding(.vertical, 4)
            } else {
                ForEach(tasks) { task in
                    HStack(spacing: 7) {
                        PriorityLamp(snapshot: snapshot, priority: task.priority, size: 8, glow: task.isCurrent || task.isFocusing)
                        Text(task.title)
                            .font(.system(size: 12, weight: task.isCurrent ? .semibold : .medium))
                            .foregroundStyle(snapshot.primaryTextColor)
                            .lineLimit(1)
                        Spacer(minLength: 6)
                        if task.isFocusing {
                            Image(systemName: "timer")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.blue)
                        } else if let dueAt = task.dueAt {
                            Text(formattedDate(dueAt, snapshot: snapshot))
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(snapshot.secondaryTextColor)
                                .lineLimit(1)
                        }
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(WidgetGlassCard(snapshot: snapshot, cornerRadius: 12, isSubtle: true))
                }
            }
        }
    }
}

private struct WidgetHeader: View {
    let title: String
    let systemImage: String
    let snapshot: TaskWidgetSnapshot

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(snapshot.primaryTextColor)
            .lineLimit(1)
            .labelStyle(.titleAndIcon)
    }
}

private struct ReviewMetric: View {
    let snapshot: TaskWidgetSnapshot
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 18, height: 18)
                .background(Color.white.opacity(snapshot.palette.isDarkGlassMode ? 0.09 : 0.22), in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(snapshot.primaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(title)
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(snapshot.secondaryTextColor)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WidgetGlassCard(snapshot: snapshot, cornerRadius: 13))
    }
}

private struct EmptyWidgetState: View {
    let snapshot: TaskWidgetSnapshot
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(snapshot.primaryTextColor)
                .lineLimit(1)
            Text(subtitle)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(snapshot.secondaryTextColor)
                .lineLimit(2)
        }
    }
}

private struct WidgetGlassCard: View {
    let snapshot: TaskWidgetSnapshot
    let cornerRadius: CGFloat
    var isSubtle = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        shape
            .fill(Color.white.opacity(snapshot.palette.isDarkGlassMode ? (isSubtle ? 0.055 : 0.075) : (isSubtle ? 0.28 : 0.38)))
            .overlay {
                shape
                    .fill(snapshot.glassTintColor.opacity(snapshot.palette.isDarkGlassMode ? 0.045 : 0.10))
            }
            .overlay {
                shape
                    .stroke(Color.white.opacity(snapshot.palette.isDarkGlassMode ? 0.11 : 0.42), lineWidth: 1)
            }
    }
}

private func formattedDuration(_ seconds: TimeInterval) -> String {
    let totalSeconds = max(Int(seconds.rounded()), 0)
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    if hours > 0 {
        return "\(hours)h \(minutes)m"
    }
    return "\(max(minutes, totalSeconds > 0 ? 1 : 0))m"
}

private func formattedDate(_ date: Date, snapshot: TaskWidgetSnapshot) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: snapshot.isEnglish ? "en_US" : "zh_CN")
    formatter.dateFormat = snapshot.isEnglish ? "MMM d" : "M/d"
    if Calendar.current.isDateInToday(date) {
        return snapshot.text("今天", "Today")
    }
    if Calendar.current.isDateInTomorrow(date) {
        return snapshot.text("明天", "Tomorrow")
    }
    return formatter.string(from: date)
}

private extension TaskWidgetSnapshot {
    func text(_ chinese: String, _ english: String) -> String {
        isEnglish ? english : chinese
    }

    var glassTintColor: Color {
        Color(taskIslandHex: palette.glassTintHex) ?? Color(red: 0.78, green: 0.94, blue: 1.0)
    }

    var primaryTextColor: Color {
        Color(taskIslandHex: palette.textColorHex ?? "")
            ?? (palette.isDarkGlassMode ? Color.white : Color(red: 0.06, green: 0.20, blue: 0.24))
    }

    var secondaryTextColor: Color {
        primaryTextColor.opacity(palette.isDarkGlassMode ? 0.72 : 0.62)
    }

    func paletteColor(_ priority: TaskWidgetPriority) -> Color {
        Color(taskIslandHex: palette.colorHex(for: priority)) ?? .accentColor
    }
}

private extension Color {
    init?(taskIslandHex hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if sanitized.hasPrefix("#") {
            sanitized.removeFirst()
        }

        guard sanitized.count == 6,
              let value = Int(sanitized, radix: 16) else {
            return nil
        }

        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }
}
