import Combine
import Foundation
import SwiftData

public enum TaskPostponeOption: CaseIterable, Identifiable {
    case fifteenMinutes
    case laterToday
    case tomorrow
    case thisWeek

    public var id: String {
        switch self {
        case .fifteenMinutes:
            return "fifteenMinutes"
        case .laterToday:
            return "laterToday"
        case .tomorrow:
            return "tomorrow"
        case .thisWeek:
            return "thisWeek"
        }
    }

    public var title: String {
        switch self {
        case .fifteenMinutes:
            return "15 分钟后"
        case .laterToday:
            return "今天晚点"
        case .tomorrow:
            return "明天"
        case .thisWeek:
            return "本周"
        }
    }
}

public struct TaskDailyReview {
    public let completedToday: [TaskItem]
    public let postponedToday: [TaskItem]
    public let tomorrowTasks: [TaskItem]
    public let focusSeconds: TimeInterval
}

public enum TaskExportFormat: String, CaseIterable, Identifiable {
    case json
    case markdown
    case csv

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .json:
            return "JSON 备份"
        case .markdown:
            return "Markdown"
        case .csv:
            return "CSV 表格"
        }
    }

    public var fileExtension: String {
        switch self {
        case .json:
            return "json"
        case .markdown:
            return "md"
        case .csv:
            return "csv"
        }
    }

    public static func preferred(for url: URL) -> TaskExportFormat {
        switch url.pathExtension.lowercased() {
        case "md", "markdown":
            return .markdown
        case "csv":
            return .csv
        default:
            return .json
        }
    }
}

@MainActor
public final class TaskStore: ObservableObject {
    public let container: ModelContainer

    @Published public private(set) var tasks: [TaskItem] = []
    @Published public private(set) var lastError: String?

    private let context: ModelContext

    public init(inMemory: Bool = false) throws {
        let schema = Schema([TaskItem.self])
        let configuration = ModelConfiguration(
            "TaskIsland",
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )

        container = try ModelContainer(for: schema, configurations: [configuration])
        context = ModelContext(container)
        context.autosaveEnabled = true

        reloadTasks()
        if !inMemory {
            migrateLegacyJSONIfNeeded()
        }
        normalizeCurrentTask()
    }

    public var incompleteTasks: [TaskItem] {
        sorted(tasks.filter { !$0.isCompleted })
    }

    public var prioritizedIncompleteTasks: [TaskItem] {
        sortedByPriority(tasks.filter { !$0.isCompleted })
    }

    public var completedTasks: [TaskItem] {
        sorted(tasks.filter(\.isCompleted))
    }

    public var todayTasks: [TaskItem] {
        sortedToday(tasks.filter { !$0.isCompleted && $0.isInTodayQueue })
    }

    public var currentTask: TaskItem? {
        incompleteTasks.first(where: \.isCurrent)
    }

    public var incompleteCount: Int {
        incompleteTasks.count
    }

    public var priorityCounts: [TaskPriority: Int] {
        Dictionary(grouping: incompleteTasks, by: \.priority)
            .mapValues(\.count)
    }

    public var focusPriorityCounts: [TaskPriority: Int] {
        let focusTasks = todayTasks.isEmpty ? incompleteTasks : todayTasks
        return Dictionary(grouping: focusTasks, by: \.priority)
            .mapValues(\.count)
    }

    public var activeFocusTask: TaskItem? {
        incompleteTasks.first { $0.focusStartedAt != nil }
    }

    public var todayCompletedTasks: [TaskItem] {
        let calendar = Calendar.current
        return completedTasks.filter { task in
            guard let completedAt = task.completedAt else { return false }
            return calendar.isDateInToday(completedAt)
        }
    }

    public var upcomingTasks: [TaskItem] {
        incompleteTasks
            .filter { $0.dueAt != nil }
            .sorted { lhs, rhs in
                guard let lhsDue = lhs.dueAt, let rhsDue = rhs.dueAt else { return lhs.dueAt != nil }
                if lhsDue != rhsDue { return lhsDue < rhsDue }
                return lhs.priority.rawValue < rhs.priority.rawValue
            }
    }

    public func suggestedTodayTasks(limit: Int = 5, now: Date = Date()) -> [TaskItem] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now
        let tasks = incompleteTasks.sorted { lhs, rhs in
            let lhsScore = suggestionScore(lhs, now: now, endOfToday: endOfToday)
            let rhsScore = suggestionScore(rhs, now: now, endOfToday: endOfToday)
            if lhsScore != rhsScore {
                return lhsScore > rhsScore
            }
            if let lhsDue = lhs.dueAt, let rhsDue = rhs.dueAt, lhsDue != rhsDue {
                return lhsDue < rhsDue
            }
            return lhs.sortIndex < rhs.sortIndex
        }
        return Array(tasks.prefix(limit))
    }

    public var allTags: [String] {
        Array(Set(tasks.flatMap(\.tags))).sorted {
            $0.localizedStandardCompare($1) == .orderedAscending
        }
    }

    public var allProjects: [String] {
        Array(Set(tasks.compactMap { task in
            let project = task.projectName?.trimmingCharacters(in: .whitespacesAndNewlines)
            return project?.isEmpty == false ? project : nil
        })).sorted {
            $0.localizedStandardCompare($1) == .orderedAscending
        }
    }

    public var menuBarTitle: String {
        guard let currentTask else {
            return incompleteTasks.isEmpty ? "已完成" : "暂无当前任务"
        }
        return currentTask.title
    }

    @discardableResult
    public func addTask(
        title rawTitle: String,
        notes: String = "",
        priority: TaskPriority = .medium
    ) -> TaskItem? {
        let parsedInput = TaskQuickAddParser.parse(rawTitle, fallbackPriority: priority)
        let title = parsedInput.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return nil }

        let item = TaskItem(
            title: title,
            notes: notes,
            isCurrent: false,
            sortIndex: nextSortIndex(),
            priority: parsedInput.priority,
            dueAt: parsedInput.dueAt,
            reminderAt: parsedInput.reminderAt,
            repeatRule: parsedInput.repeatRule,
            tags: parsedInput.tags,
            projectName: parsedInput.projectName,
            estimatedMinutes: parsedInput.estimatedMinutes,
            todaySortIndex: parsedInput.isToday ? nextTodaySortIndex() : nil
        )

        if item.isCurrent {
            clearCurrentFlags()
        }

        context.insert(item)
        commitAndReload()
        return item
    }

    @discardableResult
    public func addTaskFromMetadata(
        title rawTitle: String,
        notes: String = "",
        isCompleted: Bool = false,
        isCurrent: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        completedAt: Date? = nil,
        priority: TaskPriority = .medium,
        dueAt: Date? = nil,
        reminderAt: Date? = nil,
        repeatRule: TaskRepeatRule? = nil,
        tags: [String] = [],
        projectName: String? = nil,
        estimatedMinutes: Int? = nil,
        todaySortIndex: Int? = nil,
        subtasks: [TaskSubtask] = []
    ) -> TaskItem? {
        let title = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return nil }

        let item = TaskItem(
            title: title,
            notes: notes,
            isCompleted: isCompleted,
            isCurrent: isCurrent && !isCompleted,
            createdAt: createdAt,
            updatedAt: updatedAt,
            completedAt: completedAt,
            sortIndex: nextSortIndex(),
            priority: priority,
            dueAt: dueAt,
            reminderAt: reminderAt,
            repeatRule: repeatRule,
            tags: tags,
            projectName: projectName,
            estimatedMinutes: estimatedMinutes,
            todaySortIndex: todaySortIndex
        )
        item.subtasks = subtasks
        item.updatedAt = updatedAt

        if item.isCurrent {
            clearCurrentFlags()
        }

        context.insert(item)
        commitAndReload()
        normalizeCurrentTask()
        return item
    }

    public func incompleteTasks(for priority: TaskPriority) -> [TaskItem] {
        sorted(incompleteTasks.filter { $0.priority == priority })
    }

    public func incompleteTasks(tagged tag: String) -> [TaskItem] {
        sortedByPriority(incompleteTasks.filter { task in
            task.tags.contains { $0.localizedCaseInsensitiveCompare(tag) == .orderedSame }
        })
    }

    public func incompleteTasks(inProject projectName: String) -> [TaskItem] {
        sortedByPriority(incompleteTasks.filter { task in
            task.projectName?.localizedCaseInsensitiveCompare(projectName) == .orderedSame
        })
    }

    public func tasks(matching query: String) -> [TaskItem] {
        let cleaned = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return incompleteTasks }

        return sortedByPriority(incompleteTasks.filter { task in
            task.title.localizedCaseInsensitiveContains(cleaned)
                || task.notes.localizedCaseInsensitiveContains(cleaned)
                || task.tags.contains { $0.localizedCaseInsensitiveContains(cleaned) }
                || (task.projectName?.localizedCaseInsensitiveContains(cleaned) ?? false)
        })
    }

    public func previewTasks(limit: Int = 3) -> [TaskItem] {
        if todayTasks.isEmpty {
            return Array(prioritizedIncompleteTasks.prefix(limit))
        }

        return Array(todayTasks.prefix(limit))
    }

    public func complete(_ task: TaskItem, now: Date = Date()) {
        guard !task.isCompleted else { return }

        let nextRecurringTask = makeNextRecurringTask(from: task)
        stopFocusClock(task, now: now)
        task.isCompleted = true
        task.isCurrent = false
        task.completedAt = now
        task.updatedAt = now

        if let nextRecurringTask {
            context.insert(nextRecurringTask)
        }

        commitAndReload()
        normalizeCurrentTask()
    }

    public func delete(_ task: TaskItem) {
        context.delete(task)
        commitAndReload()
        normalizeCurrentTask()
    }

    public func setCurrent(_ task: TaskItem) {
        guard !task.isCompleted else { return }

        clearCurrentFlags()
        task.isCurrent = true
        task.updatedAt = Date()
        commitAndReload()
    }

    public func setPriority(_ task: TaskItem, priority: TaskPriority) {
        guard task.priority != priority else { return }

        task.priority = priority
        commitAndReload()
    }

    public func setDueDate(_ task: TaskItem, dueAt: Date?, reminderAt: Date? = nil) {
        task.dueAt = dueAt
        task.reminderAt = reminderAt
        task.updatedAt = Date()
        if let dueAt, Calendar.current.isDateInToday(dueAt), task.todaySortIndex == nil {
            task.todaySortIndex = nextTodaySortIndex()
        }
        commitAndReload()
    }

    public func setTodayQueue(_ task: TaskItem, isInTodayQueue: Bool) {
        if isInTodayQueue {
            task.todaySortIndex = task.todaySortIndex ?? nextTodaySortIndex()
        } else {
            task.todaySortIndex = nil
        }
        task.updatedAt = Date()
        commitAndReload()
    }

    public func updateNotes(_ task: TaskItem, notes: String) {
        task.notes = notes
        task.updatedAt = Date()
        commitAndReload()
    }

    public func setRepeatRule(_ task: TaskItem, repeatRule: TaskRepeatRule?) {
        task.repeatRule = repeatRule
        task.updatedAt = Date()
        commitAndReload()
    }

    public func setProjectName(_ task: TaskItem, projectName: String?) {
        let cleaned = projectName?.trimmingCharacters(in: .whitespacesAndNewlines)
        task.projectName = cleaned?.isEmpty == false ? cleaned : nil
        task.updatedAt = Date()
        commitAndReload()
    }

    public func setTags(_ task: TaskItem, tags: [String]) {
        task.tags = tags
        task.updatedAt = Date()
        commitAndReload()
    }

    public func setEstimatedMinutes(_ task: TaskItem, estimatedMinutes: Int?) {
        task.estimatedMinutes = estimatedMinutes
        task.updatedAt = Date()
        commitAndReload()
    }

    public func startFocus(_ task: TaskItem, now: Date = Date()) {
        guard !task.isCompleted else { return }

        for activeTask in incompleteTasks where activeTask.focusStartedAt != nil && activeTask.id != task.id {
            stopFocusClock(activeTask, now: now)
        }

        clearCurrentFlags()
        task.isCurrent = true
        task.focusStartedAt = task.focusStartedAt ?? now
        task.updatedAt = now
        commitAndReload()
    }

    public func pauseFocus(_ task: TaskItem, now: Date = Date()) {
        stopFocusClock(task, now: now)
        commitAndReload()
    }

    public func toggleFocus(_ task: TaskItem, now: Date = Date()) {
        if task.focusStartedAt == nil {
            startFocus(task, now: now)
        } else {
            pauseFocus(task, now: now)
        }
    }

    public func focusSeconds(for task: TaskItem, now: Date = Date()) -> TimeInterval {
        let accumulated = task.focusSeconds
        guard let startedAt = task.focusStartedAt else { return accumulated }
        return accumulated + max(now.timeIntervalSince(startedAt), 0)
    }

    public func focusTargetMinutes(for task: TaskItem, defaultMinutes: Int = 25) -> Int {
        max(task.estimatedMinutes ?? defaultMinutes, 1)
    }

    public func focusRemainingSeconds(for task: TaskItem, now: Date = Date(), defaultMinutes: Int = 25) -> TimeInterval {
        let target = TimeInterval(focusTargetMinutes(for: task, defaultMinutes: defaultMinutes) * 60)
        return max(target - focusSeconds(for: task, now: now), 0)
    }

    public func addSubtask(_ title: String, to task: TaskItem) {
        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedTitle.isEmpty else { return }

        var subtasks = task.subtasks
        subtasks.append(TaskSubtask(title: cleanedTitle))
        task.subtasks = subtasks
        task.updatedAt = Date()
        commitAndReload()
    }

    public func toggleSubtask(_ subtask: TaskSubtask, in task: TaskItem) {
        var subtasks = task.subtasks
        guard let index = subtasks.firstIndex(where: { $0.id == subtask.id }) else { return }

        subtasks[index].isCompleted.toggle()
        task.subtasks = subtasks
        task.updatedAt = Date()
        commitAndReload()
    }

    public func deleteSubtask(_ subtask: TaskSubtask, from task: TaskItem) {
        var subtasks = task.subtasks
        subtasks.removeAll { $0.id == subtask.id }
        task.subtasks = subtasks
        task.updatedAt = Date()
        commitAndReload()
    }

    public func postpone(_ task: TaskItem, option: TaskPostponeOption, now: Date = Date()) {
        let calendar = Calendar.current
        let dueAt: Date?

        switch option {
        case .fifteenMinutes:
            dueAt = calendar.date(byAdding: .minute, value: 15, to: now)
        case .laterToday:
            let twoHoursLater = calendar.date(byAdding: .hour, value: 2, to: now) ?? now
            let evening = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now) ?? twoHoursLater
            dueAt = max(twoHoursLater, evening)
        case .tomorrow:
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
            dueAt = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow)
        case .thisWeek:
            let laterThisWeek = calendar.date(byAdding: .day, value: 3, to: now) ?? now
            dueAt = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: laterThisWeek)
        }

        task.dueAt = dueAt
        task.reminderAt = dueAt
        task.postponedAt = now
        task.postponeCount += 1
        if let dueAt, calendar.isDate(dueAt, inSameDayAs: now) {
            task.todaySortIndex = task.todaySortIndex ?? nextTodaySortIndex()
        } else if option == .tomorrow || option == .thisWeek {
            task.todaySortIndex = nil
        }
        task.updatedAt = now
        commitAndReload()
    }

    public func updateMetadata(
        _ task: TaskItem,
        notes: String? = nil,
        dueAt: Date? = nil,
        reminderAt: Date? = nil,
        repeatRule: TaskRepeatRule? = nil,
        tags: [String]? = nil,
        projectName: String? = nil,
        estimatedMinutes: Int? = nil
    ) {
        if let notes {
            task.notes = notes
        }
        task.dueAt = dueAt
        task.reminderAt = reminderAt
        task.repeatRule = repeatRule
        if let tags {
            task.tags = tags
        }
        task.projectName = projectName
        task.estimatedMinutes = estimatedMinutes
        task.updatedAt = Date()
        commitAndReload()
    }

    public func dailyReview(now: Date = Date()) -> TaskDailyReview {
        let calendar = Calendar.current
        let completedToday = completedTasks.filter { task in
            guard let completedAt = task.completedAt else { return false }
            return calendar.isDate(completedAt, inSameDayAs: now)
        }
        let postponedToday = incompleteTasks.filter { task in
            guard let postponedAt = task.postponedAt else { return false }
            return calendar.isDate(postponedAt, inSameDayAs: now)
        }
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let tomorrowTasks = incompleteTasks.filter { task in
            guard let dueAt = task.dueAt else { return false }
            return calendar.isDate(dueAt, inSameDayAs: tomorrow)
        }
        let focusSeconds = tasks.reduce(TimeInterval(0)) { total, task in
            total + self.focusSeconds(for: task, now: now)
        }

        return TaskDailyReview(
            completedToday: completedToday,
            postponedToday: postponedToday,
            tomorrowTasks: tomorrowTasks,
            focusSeconds: focusSeconds
        )
    }

    public func advanceCurrent() {
        let activeTasks = incompleteTasks
        guard !activeTasks.isEmpty else { return }

        guard let currentTask else {
            setCurrent(activeTasks[activeTasks.startIndex])
            return
        }

        let currentIndex = activeTasks.firstIndex { $0.id == currentTask.id } ?? activeTasks.startIndex

        let nextIndex = activeTasks.index(after: currentIndex)
        let nextTask = activeTasks[nextIndex == activeTasks.endIndex ? activeTasks.startIndex : nextIndex]
        setCurrent(nextTask)
    }

    public func deleteCompleted() {
        for task in completedTasks {
            context.delete(task)
        }
        commitAndReload()
    }

    public func exportTasks(to url: URL) throws {
        try exportTasks(to: url, format: .preferred(for: url))
    }

    public func exportTasks(to url: URL, format: TaskExportFormat) throws {
        let data: Data
        switch format {
        case .json:
            data = try jsonExportData()
        case .markdown:
            data = Data(markdownExportText().utf8)
        case .csv:
            data = Data(csvExportText().utf8)
        }
        try data.write(to: url, options: .atomic)
    }

    private func jsonExportData() throws -> Data {
        let archive = TaskArchive(
            version: 2,
            exportedAt: Date(),
            tasks: tasks.map(TaskArchiveItem.init(task:))
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(archive)
    }

    private func markdownExportText() -> String {
        let formatter = ISO8601DateFormatter()
        var lines: [String] = [
            "# 任务岛导出",
            "",
            "导出时间：\(formatter.string(from: Date()))",
            ""
        ]

        func appendSection(_ title: String, tasks: [TaskItem]) {
            lines.append("## \(title)")
            lines.append("")
            if tasks.isEmpty {
                lines.append("- 无")
                lines.append("")
                return
            }

            for task in tasks {
                let mark = task.isCompleted ? "x" : " "
                var metadata: [String] = [task.priority.title]
                if let dueAt = task.dueAt {
                    metadata.append("截止 \(formatter.string(from: dueAt))")
                }
                if let projectName = task.projectName, !projectName.isEmpty {
                    metadata.append("+\(projectName)")
                }
                metadata.append(contentsOf: task.tags.map { "#\($0)" })
                if let estimatedMinutes = task.estimatedMinutes {
                    metadata.append("\(estimatedMinutes)分钟")
                }
                lines.append("- [\(mark)] \(task.title) _\(metadata.joined(separator: " · "))_")
                if !task.notes.isEmpty {
                    lines.append("  - 备注：\(task.notes.replacingOccurrences(of: "\n", with: " "))")
                }
                for subtask in task.subtasks {
                    lines.append("  - [\(subtask.isCompleted ? "x" : " ")] \(subtask.title)")
                }
            }
            lines.append("")
        }

        appendSection("未完成", tasks: incompleteTasks)
        appendSection("已完成", tasks: completedTasks)
        return lines.joined(separator: "\n")
    }

    private func csvExportText() -> String {
        let formatter = ISO8601DateFormatter()
        let header = [
            "id",
            "title",
            "notes",
            "completed",
            "current",
            "priority",
            "dueAt",
            "reminderAt",
            "repeat",
            "tags",
            "project",
            "estimatedMinutes",
            "today",
            "subtasks",
            "focusSeconds",
            "postponeCount"
        ]
        let rows = tasks.map { task in
            [
                task.id.uuidString,
                task.title,
                task.notes,
                task.isCompleted ? "true" : "false",
                task.isCurrent ? "true" : "false",
                task.priority.shortTitle,
                task.dueAt.map(formatter.string(from:)) ?? "",
                task.reminderAt.map(formatter.string(from:)) ?? "",
                task.repeatRule?.title ?? "",
                task.tags.joined(separator: "|"),
                task.projectName ?? "",
                task.estimatedMinutes.map(String.init) ?? "",
                task.isInTodayQueue ? "true" : "false",
                task.subtasks.map { "\($0.isCompleted ? "x" : " "):\($0.title)" }.joined(separator: "|"),
                String(Int(task.focusSeconds.rounded())),
                String(task.postponeCount)
            ]
        }

        return ([header] + rows)
            .map { row in row.map(Self.csvEscaped).joined(separator: ",") }
            .joined(separator: "\n") + "\n"
    }

    @discardableResult
    public func importTasks(from url: URL) throws -> Int {
        if url.pathExtension.lowercased() == "csv" {
            return try importCSVTasks(from: url)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try Data(contentsOf: url)
        let archive = try decoder.decode(TaskArchive.self, from: data)

        var importedCount = 0
        for item in archive.tasks {
            if let existing = tasks.first(where: { $0.id == item.id }) {
                item.apply(to: existing)
            } else {
                context.insert(item.makeTask())
                importedCount += 1
            }
        }

        try context.save()
        reloadTasks()
        normalizeCurrentTask()
        return importedCount
    }

    @discardableResult
    public func importCSVTasks(from url: URL) throws -> Int {
        let text = try String(contentsOf: url, encoding: .utf8)
        let rows = Self.parseCSV(text)
        guard let header = rows.first, !header.isEmpty else { return 0 }

        let normalizedHeader = header.map(Self.normalizedCSVKey)
        var importedCount = 0
        for row in rows.dropFirst() {
            var values: [String: String] = [:]
            for (index, key) in normalizedHeader.enumerated() where !key.isEmpty {
                values[key] = index < row.count ? row[index] : ""
            }
            guard let item = Self.archiveItem(fromCSVValues: values) else { continue }

            if let existing = tasks.first(where: { $0.id == item.id }) {
                item.apply(to: existing)
            } else {
                context.insert(item.makeTask())
                importedCount += 1
            }
        }

        try context.save()
        reloadTasks()
        normalizeCurrentTask()
        return importedCount
    }

    public func reloadTasks() {
        do {
            var descriptor = FetchDescriptor<TaskItem>(
                sortBy: [
                    SortDescriptor(\TaskItem.sortIndex, order: .forward),
                    SortDescriptor(\TaskItem.createdAt, order: .forward)
                ]
            )
            descriptor.includePendingChanges = true
            tasks = try context.fetch(descriptor)
            lastError = nil
        } catch {
            lastError = "无法读取已保存的任务：\(error.localizedDescription)"
        }
    }

    private func normalizeCurrentTask() {
        let activeTasks = incompleteTasks
        var changed = false

        for task in tasks where task.isCurrent && (task.isCompleted || activeTasks.isEmpty) {
            task.isCurrent = false
            task.updatedAt = Date()
            changed = true
        }

        let currentTasks = activeTasks.filter(\.isCurrent)
        for task in currentTasks.dropFirst() {
            task.isCurrent = false
            task.updatedAt = Date()
            changed = true
        }

        if changed {
            commitAndReload()
        }
    }

    private func commitAndReload() {
        do {
            try context.save()
            reloadTasks()
            lastError = nil
        } catch {
            lastError = "无法保存任务：\(error.localizedDescription)"
        }
    }

    private func clearCurrentFlags() {
        for task in incompleteTasks where task.isCurrent {
            task.isCurrent = false
            task.updatedAt = Date()
        }
    }

    private func stopFocusClock(_ task: TaskItem, now: Date) {
        guard let startedAt = task.focusStartedAt else { return }

        task.focusSeconds = task.focusSeconds + max(now.timeIntervalSince(startedAt), 0)
        task.focusStartedAt = nil
        task.updatedAt = now
    }

    private func suggestionScore(_ task: TaskItem, now: Date, endOfToday: Date) -> Int {
        var score = 0
        if task.isInTodayQueue { score += 80 }
        if task.isCurrent { score += 30 }

        switch task.priority {
        case .high:
            score += 30
        case .medium:
            score += 16
        case .low:
            score += 6
        }

        if let dueAt = task.dueAt {
            if dueAt < now {
                score += 70
            } else if dueAt < endOfToday {
                score += 55
            } else if dueAt.timeIntervalSince(now) < 3 * 24 * 60 * 60 {
                score += 24
            }
        }

        if let estimatedMinutes = task.estimatedMinutes {
            if estimatedMinutes <= 30 {
                score += 10
            } else if estimatedMinutes <= 60 {
                score += 6
            }
        }

        return score
    }

    private func nextSortIndex() -> Int {
        (tasks.map(\.sortIndex).max() ?? -1) + 1
    }

    private func sorted(_ items: [TaskItem]) -> [TaskItem] {
        items.sorted { lhs, rhs in
            if lhs.sortIndex != rhs.sortIndex {
                return lhs.sortIndex < rhs.sortIndex
            }
            return lhs.createdAt < rhs.createdAt
        }
    }

    private func sortedByPriority(_ items: [TaskItem]) -> [TaskItem] {
        items.sorted { lhs, rhs in
            if lhs.isInTodayQueue != rhs.isInTodayQueue {
                return lhs.isInTodayQueue && !rhs.isInTodayQueue
            }
            if lhs.priority.rawValue != rhs.priority.rawValue {
                return lhs.priority.rawValue < rhs.priority.rawValue
            }
            if let lhsDue = lhs.dueAt, let rhsDue = rhs.dueAt, lhsDue != rhsDue {
                return lhsDue < rhsDue
            }
            if lhs.dueAt != nil && rhs.dueAt == nil {
                return true
            }
            if lhs.dueAt == nil && rhs.dueAt != nil {
                return false
            }
            if lhs.isCurrent != rhs.isCurrent {
                return lhs.isCurrent && !rhs.isCurrent
            }
            if lhs.sortIndex != rhs.sortIndex {
                return lhs.sortIndex < rhs.sortIndex
            }
            return lhs.createdAt < rhs.createdAt
        }
    }

    private func sortedToday(_ items: [TaskItem]) -> [TaskItem] {
        items.sorted { lhs, rhs in
            if let lhsToday = lhs.todaySortIndex, let rhsToday = rhs.todaySortIndex, lhsToday != rhsToday {
                return lhsToday < rhsToday
            }
            if let lhsDue = lhs.dueAt, let rhsDue = rhs.dueAt, lhsDue != rhsDue {
                return lhsDue < rhsDue
            }
            if lhs.priority.rawValue != rhs.priority.rawValue {
                return lhs.priority.rawValue < rhs.priority.rawValue
            }
            return lhs.sortIndex < rhs.sortIndex
        }
    }

    private func nextTodaySortIndex() -> Int {
        (tasks.compactMap(\.todaySortIndex).max() ?? -1) + 1
    }

    private func makeNextRecurringTask(from task: TaskItem) -> TaskItem? {
        guard let repeatRule = task.repeatRule,
              let dueAt = task.dueAt,
              let nextDueAt = nextDate(after: dueAt, repeatRule: repeatRule) else {
            return nil
        }

        return TaskItem(
            title: task.title,
            notes: task.notes,
            isCurrent: false,
            sortIndex: nextSortIndex(),
            priority: task.priority,
            dueAt: nextDueAt,
            reminderAt: task.reminderAt == nil ? nil : nextDueAt,
            repeatRule: repeatRule,
            tags: task.tags,
            projectName: task.projectName,
            estimatedMinutes: task.estimatedMinutes,
            todaySortIndex: Calendar.current.isDateInToday(nextDueAt) ? nextTodaySortIndex() : nil,
            subtasks: task.subtasks.map {
                TaskSubtask(title: $0.title, isCompleted: false, createdAt: Date())
            }
        )
    }

    private func nextDate(after date: Date, repeatRule: TaskRepeatRule) -> Date? {
        let calendar = Calendar.current
        switch repeatRule {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date)
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date)
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date)
        }
    }

    private static func csvEscaped(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }

    private static func parseCSV(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var isQuoted = false
        var index = text.startIndex

        while index < text.endIndex {
            let character = text[index]
            let nextIndex = text.index(after: index)

            if character == "\"" {
                if isQuoted, nextIndex < text.endIndex, text[nextIndex] == "\"" {
                    field.append("\"")
                    index = text.index(after: nextIndex)
                    continue
                }
                isQuoted.toggle()
            } else if character == ",", !isQuoted {
                row.append(field)
                field = ""
            } else if (character == "\n" || character == "\r"), !isQuoted {
                if character == "\r", nextIndex < text.endIndex, text[nextIndex] == "\n" {
                    index = text.index(after: nextIndex)
                } else {
                    index = nextIndex
                }
                row.append(field)
                if row.contains(where: { !$0.isEmpty }) {
                    rows.append(row)
                }
                row = []
                field = ""
                continue
            } else {
                field.append(character)
            }

            index = nextIndex
        }

        row.append(field)
        if row.contains(where: { !$0.isEmpty }) {
            rows.append(row)
        }
        return rows
    }

    private static func normalizedCSVKey(_ key: String) -> String {
        key
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "")
    }

    private static func archiveItem(fromCSVValues values: [String: String]) -> TaskArchiveItem? {
        let title = firstValue(in: values, keys: ["title", "content", "taskname", "name", "任务", "标题"])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return nil }

        let now = Date()
        let idValue = firstValue(in: values, keys: ["id", "uuid"])
        let id = UUID(uuidString: idValue) ?? UUID()
        let notes = firstValue(in: values, keys: ["notes", "description", "备注", "描述"])
        let isCompleted = boolValue(firstValue(in: values, keys: ["completed", "complete", "done", "已完成"]))
        let isCurrent = boolValue(firstValue(in: values, keys: ["current", "iscurrent", "当前"]))
        let createdAt = dateValue(firstValue(in: values, keys: ["createdat", "created", "创建时间"])) ?? now
        let updatedAt = dateValue(firstValue(in: values, keys: ["updatedat", "updated", "更新时间"])) ?? now
        let completedAt = dateValue(firstValue(in: values, keys: ["completedat", "completeddate", "完成时间"]))
            ?? (isCompleted ? now : nil)
        let priority = priorityValue(firstValue(in: values, keys: ["priority", "优先级"]))
        let dueAt = dateValue(firstValue(in: values, keys: ["dueat", "duedate", "date", "到期", "截止"]))
        let reminderAt = dateValue(firstValue(in: values, keys: ["reminderat", "reminder", "提醒"])) ?? dueAt
        let repeatRule = repeatRuleValue(firstValue(in: values, keys: ["repeat", "recurring", "重复"]))
        let tags = tagValues(firstValue(in: values, keys: ["tags", "labels", "label", "标签"]))
        let project = firstValue(in: values, keys: ["project", "projectname", "list", "section", "项目", "清单"])
        let estimatedMinutes = intValue(firstValue(in: values, keys: ["estimatedminutes", "duration", "预计分钟"]))
        let today = boolValue(firstValue(in: values, keys: ["today", "myday", "今天"]))
        let subtasks = subtaskValues(firstValue(in: values, keys: ["subtasks", "steps", "子任务"]))
        let focusSeconds = Double(intValue(firstValue(in: values, keys: ["focusseconds", "专注秒数"])) ?? 0)
        let postponeCount = intValue(firstValue(in: values, keys: ["postponecount", "推迟次数"])) ?? 0

        return TaskArchiveItem(
            id: id,
            title: title,
            notes: notes,
            isCompleted: isCompleted,
            isCurrent: isCurrent,
            createdAt: createdAt,
            updatedAt: updatedAt,
            completedAt: completedAt,
            sortIndex: intValue(firstValue(in: values, keys: ["sortindex", "order", "排序"])) ?? 0,
            priorityRawValue: priority.rawValue,
            dueAt: dueAt,
            reminderAt: reminderAt,
            repeatRuleRawValue: repeatRule?.rawValue,
            tags: tags,
            projectName: project.isEmpty ? nil : project,
            estimatedMinutes: estimatedMinutes,
            todaySortIndex: today ? 0 : nil,
            subtasks: subtasks,
            focusStartedAt: nil,
            focusAccumulatedSeconds: focusSeconds,
            postponedAt: nil,
            postponeCount: postponeCount
        )
    }

    private static func firstValue(in values: [String: String], keys: [String]) -> String {
        for key in keys {
            let normalizedKey = normalizedCSVKey(key)
            if let value = values[normalizedKey], !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return value
            }
        }
        return ""
    }

    private static func boolValue(_ value: String) -> Bool {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return ["true", "yes", "1", "x", "done", "completed", "已完成", "是"].contains(normalized)
    }

    private static func intValue(_ value: String) -> Int? {
        Int(value.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private static func dateValue(_ value: String) -> Date? {
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }

        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: cleaned) {
            return date
        }

        let dateFormats = [
            "yyyy-MM-dd HH:mm",
            "yyyy/MM/dd HH:mm",
            "yyyy-MM-dd",
            "yyyy/MM/dd",
            "M/d/yyyy",
            "MM/dd/yyyy"
        ]
        for format in dateFormats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = format
            if let date = formatter.date(from: cleaned) {
                return date
            }
        }

        return nil
    }

    private static func priorityValue(_ value: String) -> TaskPriority {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalized.contains("高") || normalized.contains("high") || normalized == "p1" || normalized == "1" || normalized == "4" {
            return .high
        }
        if normalized.contains("低") || normalized.contains("low") || normalized == "p3" || normalized == "3" {
            return .low
        }
        return .medium
    }

    private static func repeatRuleValue(_ value: String) -> TaskRepeatRule? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalized.contains("每天") || normalized.contains("daily") {
            return .daily
        }
        if normalized.contains("每周") || normalized.contains("weekly") {
            return .weekly
        }
        if normalized.contains("每月") || normalized.contains("monthly") {
            return .monthly
        }
        if normalized.contains("每年") || normalized.contains("yearly") || normalized.contains("annually") {
            return .yearly
        }
        return nil
    }

    private static func tagValues(_ value: String) -> [String] {
        value
            .split { ["|", ";", " ", "#"].contains(String($0)) }
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func subtaskValues(_ value: String) -> [TaskSubtask] {
        value
            .split(separator: "|")
            .map { raw in
                let text = String(raw)
                if text.hasPrefix("x:") {
                    return TaskSubtask(title: String(text.dropFirst(2)), isCompleted: true)
                }
                if text.hasPrefix(" :") {
                    return TaskSubtask(title: String(text.dropFirst(2)), isCompleted: false)
                }
                return TaskSubtask(title: text)
            }
            .filter { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private static func defaultPersistenceURL() -> URL {
        let baseURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.homeDirectoryForCurrentUser

        return baseURL
            .appendingPathComponent("TaskIsland", isDirectory: true)
            .appendingPathComponent("tasks.json", isDirectory: false)
    }

    private func migrateLegacyJSONIfNeeded() {
        guard tasks.isEmpty else { return }

        let legacyURL = Self.defaultPersistenceURL()
        guard FileManager.default.fileExists(atPath: legacyURL.path) else { return }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let data = try Data(contentsOf: legacyURL)
            let legacyTasks = try decoder.decode([LegacyTaskItem].self, from: data)

            guard !legacyTasks.isEmpty else { return }

            for legacyTask in legacyTasks {
                context.insert(TaskItem(legacyTask: legacyTask))
            }

            try context.save()
            let migratedURL = legacyURL.deletingLastPathComponent()
                .appendingPathComponent("tasks.migrated.json", isDirectory: false)
            if FileManager.default.fileExists(atPath: migratedURL.path) {
                try FileManager.default.removeItem(at: migratedURL)
            }
            try FileManager.default.moveItem(at: legacyURL, to: migratedURL)
            reloadTasks()
        } catch {
            lastError = "无法迁移旧任务数据：\(error.localizedDescription)"
        }
    }
}

private struct LegacyTaskItem: Decodable {
    var id: UUID
    var title: String
    var notes: String
    var isCompleted: Bool
    var isCurrent: Bool
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?
    var sortIndex: Int
}

private struct TaskArchive: Codable {
    var version: Int
    var exportedAt: Date
    var tasks: [TaskArchiveItem]
}

private struct TaskArchiveItem: Codable {
    var id: UUID
    var title: String
    var notes: String
    var isCompleted: Bool
    var isCurrent: Bool
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?
    var sortIndex: Int
    var priorityRawValue: Int?
    var dueAt: Date?
    var reminderAt: Date?
    var repeatRuleRawValue: String?
    var tags: [String]
    var projectName: String?
    var estimatedMinutes: Int?
    var todaySortIndex: Int?
    var subtasks: [TaskSubtask]
    var focusStartedAt: Date?
    var focusAccumulatedSeconds: Double
    var postponedAt: Date?
    var postponeCount: Int

    init(
        id: UUID,
        title: String,
        notes: String,
        isCompleted: Bool,
        isCurrent: Bool,
        createdAt: Date,
        updatedAt: Date,
        completedAt: Date?,
        sortIndex: Int,
        priorityRawValue: Int?,
        dueAt: Date?,
        reminderAt: Date?,
        repeatRuleRawValue: String?,
        tags: [String],
        projectName: String?,
        estimatedMinutes: Int?,
        todaySortIndex: Int?,
        subtasks: [TaskSubtask],
        focusStartedAt: Date?,
        focusAccumulatedSeconds: Double,
        postponedAt: Date?,
        postponeCount: Int
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.isCompleted = isCompleted
        self.isCurrent = isCurrent
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.sortIndex = sortIndex
        self.priorityRawValue = priorityRawValue
        self.dueAt = dueAt
        self.reminderAt = reminderAt
        self.repeatRuleRawValue = repeatRuleRawValue
        self.tags = tags
        self.projectName = projectName
        self.estimatedMinutes = estimatedMinutes
        self.todaySortIndex = todaySortIndex
        self.subtasks = subtasks
        self.focusStartedAt = focusStartedAt
        self.focusAccumulatedSeconds = focusAccumulatedSeconds
        self.postponedAt = postponedAt
        self.postponeCount = postponeCount
    }

    init(task: TaskItem) {
        id = task.id
        title = task.title
        notes = task.notes
        isCompleted = task.isCompleted
        isCurrent = task.isCurrent
        createdAt = task.createdAt
        updatedAt = task.updatedAt
        completedAt = task.completedAt
        sortIndex = task.sortIndex
        priorityRawValue = task.priority.rawValue
        dueAt = task.dueAt
        reminderAt = task.reminderAt
        repeatRuleRawValue = task.repeatRuleRawValue
        tags = task.tags
        projectName = task.projectName
        estimatedMinutes = task.estimatedMinutes
        todaySortIndex = task.todaySortIndex
        subtasks = task.subtasks
        focusStartedAt = task.focusStartedAt
        focusAccumulatedSeconds = task.focusSeconds
        postponedAt = task.postponedAt
        postponeCount = task.postponeCount
    }

    func makeTask() -> TaskItem {
        TaskItem(
            id: id,
            title: title,
            notes: notes,
            isCompleted: isCompleted,
            isCurrent: isCurrent,
            createdAt: createdAt,
            updatedAt: updatedAt,
            completedAt: completedAt,
            sortIndex: sortIndex,
            priority: TaskPriority(rawValue: priorityRawValue ?? TaskPriority.medium.rawValue) ?? .medium,
            dueAt: dueAt,
            reminderAt: reminderAt,
            repeatRule: repeatRuleRawValue.flatMap(TaskRepeatRule.init(rawValue:)),
            tags: tags,
            projectName: projectName,
            estimatedMinutes: estimatedMinutes,
            todaySortIndex: todaySortIndex,
            subtasks: subtasks,
            focusStartedAt: focusStartedAt,
            focusAccumulatedSeconds: focusAccumulatedSeconds,
            postponedAt: postponedAt,
            postponeCount: postponeCount
        )
    }

    func apply(to task: TaskItem) {
        task.title = title
        task.notes = notes
        task.isCompleted = isCompleted
        task.isCurrent = isCurrent
        task.createdAt = createdAt
        task.updatedAt = updatedAt
        task.completedAt = completedAt
        task.sortIndex = sortIndex
        task.priorityRawValue = priorityRawValue
        task.dueAt = dueAt
        task.reminderAt = reminderAt
        task.repeatRuleRawValue = repeatRuleRawValue
        task.tags = tags
        task.projectName = projectName
        task.estimatedMinutes = estimatedMinutes
        task.todaySortIndex = todaySortIndex
        task.subtasks = subtasks
        task.focusStartedAt = focusStartedAt
        task.focusAccumulatedSeconds = focusAccumulatedSeconds
        task.postponedAt = postponedAt
        task.postponeCountRawValue = postponeCount
        task.updatedAt = updatedAt
    }
}

private extension TaskItem {
    convenience init(legacyTask: LegacyTaskItem) {
        self.init(
            id: legacyTask.id,
            title: legacyTask.title,
            notes: legacyTask.notes,
            isCompleted: legacyTask.isCompleted,
            isCurrent: legacyTask.isCurrent,
            createdAt: legacyTask.createdAt,
            updatedAt: legacyTask.updatedAt,
            completedAt: legacyTask.completedAt,
            sortIndex: legacyTask.sortIndex,
            priority: .medium,
            dueAt: nil,
            reminderAt: nil,
            repeatRule: nil,
            tags: [],
            projectName: nil,
            estimatedMinutes: nil,
            todaySortIndex: nil
        )
    }
}
