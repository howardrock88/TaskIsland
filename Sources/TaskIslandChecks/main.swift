import Foundation
import TaskIslandCore

@MainActor
private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        fatalError(message)
    }
}

@MainActor
private func runChecks() throws {
    do {
        let store = try TaskStore(inMemory: true)
        store.addTask(title: "Draft launch notes")
        require(store.incompleteCount == 1, "First task was not added")
        require(store.currentTask?.title == "Draft launch notes", "First task did not become current")
        require(store.currentTask?.isCurrent == true, "Current flag was not set")
        require(store.currentTask?.priority == .medium, "New tasks should default to medium priority")
    }

    do {
        let store = try TaskStore(inMemory: true)
        guard let first = store.addTask(title: "First") else {
            fatalError("First task was not created")
        }
        store.addTask(title: "Second")
        store.complete(first)
        require(store.incompleteCount == 1, "Completing current task left the wrong count")
        require(store.currentTask?.title == "Second", "Next task was not promoted")
        require(store.completedTasks.count == 1, "Completed task was not retained")
    }

    do {
        let store = try TaskStore(inMemory: true)
        store.addTask(title: "One")
        store.addTask(title: "Two")
        store.addTask(title: "Three")
        store.advanceCurrent()
        require(store.currentTask?.title == "Two", "Advance did not select task two")
        store.advanceCurrent()
        require(store.currentTask?.title == "Three", "Advance did not select task three")
        store.advanceCurrent()
        require(store.currentTask?.title == "One", "Advance did not cycle to task one")
    }

    do {
        let store = try TaskStore(inMemory: true)
        let task = store.addTask(title: "   ")
        require(task == nil, "Blank title created a task")
        require(store.incompleteCount == 0, "Blank title changed task count")
    }

    do {
        let store = try TaskStore(inMemory: true)
        guard let first = store.addTask(title: "First") else {
            fatalError("First task was not created")
        }
        store.addTask(title: "Second")
        store.delete(first)
        require(store.incompleteCount == 1, "Deleting current task left the wrong count")
        require(store.currentTask?.title == "Second", "Deleting current task did not promote next")
    }

    do {
        let store = try TaskStore(inMemory: true)
        guard let low = store.addTask(title: "Low", priority: .low),
              let high = store.addTask(title: "High", priority: .high),
              let medium = store.addTask(title: "Medium") else {
            fatalError("Priority tasks were not created")
        }

        require(store.priorityCounts[.high, default: 0] == 1, "High priority count was wrong")
        require(store.priorityCounts[.medium, default: 0] == 1, "Medium priority count was wrong")
        require(store.priorityCounts[.low, default: 0] == 1, "Low priority count was wrong")
        require(store.previewTasks().map(\.title) == ["High", "Medium", "Low"], "Preview tasks were not priority sorted")

        store.setPriority(low, priority: .high)
        require(store.priorityCounts[.high, default: 0] == 2, "Priority update did not change high count")
        require(store.priorityCounts[.low, default: 0] == 0, "Priority update did not clear low count")

        store.complete(high)
        require(store.priorityCounts[.high, default: 0] == 1, "Completing high priority task did not update count")
        require(store.previewTasks(limit: 2).map(\.title) == ["Low", "Medium"], "Preview limit or ordering was wrong")
        _ = medium
    }

    do {
        let legacyTask = TaskItem(title: "Legacy", sortIndex: 0)
        legacyTask.priorityRawValue = nil
        require(legacyTask.priority == .medium, "Legacy tasks should read as medium priority")
    }

    do {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1, hour: 12))!
        let parsed = TaskQuickAddParser.parse(
            "明天 10点 发周报 #工作 !高 /30m",
            fallbackPriority: .medium,
            now: now,
            calendar: calendar
        )

        require(parsed.title == "发周报", "Quick add parser did not clean title")
        require(parsed.priority == .high, "Quick add parser did not parse priority")
        require(parsed.tags == ["工作"], "Quick add parser did not parse tags")
        require(parsed.estimatedMinutes == 30, "Quick add parser did not parse duration")
        require(parsed.dueAt != nil, "Quick add parser did not parse due date")
        let dueComponents = calendar.dateComponents([.month, .day, .hour, .minute], from: parsed.dueAt!)
        require(dueComponents.month == 6 && dueComponents.day == 2, "Quick add parser due day was wrong")
        require(dueComponents.hour == 10 && dueComponents.minute == 0, "Quick add parser due time was wrong")
    }

    do {
        let store = try TaskStore(inMemory: true)
        guard let task = store.addTask(title: "今天 15:30 写日报 #工作 !低 /45m") else {
            fatalError("Parsed task was not created")
        }

        require(task.title == "写日报", "Store did not use parsed title")
        require(task.priority == .low, "Store did not use parsed priority")
        require(task.tags == ["工作"], "Store did not persist parsed tags")
        require(task.estimatedMinutes == 45, "Store did not persist parsed duration")
        require(task.dueAt != nil, "Store did not persist parsed due date")
        require(task.isInTodayQueue, "Today task was not added to Today queue")
        require(store.todayTasks.count == 1, "Today queue count was wrong")
    }

    do {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1, hour: 12))!
        let parsed = TaskQuickAddParser.parse(
            "每周五 18:00 发周报 #工作 !高",
            fallbackPriority: .medium,
            now: now,
            calendar: calendar
        )

        require(parsed.repeatRule == .weekly, "Quick add parser did not parse weekly repeat")
        require(parsed.title == "发周报", "Weekly quick add title was not cleaned")
        let dueComponents = calendar.dateComponents([.weekday, .hour, .minute], from: parsed.dueAt!)
        require(dueComponents.weekday == 6, "Weekly quick add due weekday was wrong")
        require(dueComponents.hour == 18 && dueComponents.minute == 0, "Weekly quick add time was wrong")
    }

    do {
        let store = try TaskStore(inMemory: true)
        guard let task = store.addTask(title: "每周五 18:00 发周报 #工作 !高 /30m") else {
            fatalError("Recurring task was not created")
        }

        store.complete(task)
        require(store.completedTasks.count == 1, "Completing recurring task did not keep completed instance")
        require(store.incompleteCount == 1, "Completing recurring task did not create next instance")
        guard let nextTask = store.incompleteTasks.first else {
            fatalError("Next recurring task was missing")
        }
        require(nextTask.title == "发周报", "Next recurring task title was wrong")
        require(nextTask.repeatRule == .weekly, "Next recurring task did not keep repeat rule")
        require(nextTask.tags == ["工作"], "Next recurring task did not keep tags")
        require(nextTask.estimatedMinutes == 30, "Next recurring task did not keep duration")
        require(nextTask.priority == .high, "Next recurring task did not keep priority")
        require(nextTask.dueAt != task.dueAt, "Next recurring task due date did not advance")
    }

    do {
        let store = try TaskStore(inMemory: true)
        guard let task = store.addTask(title: "写产品方案 /25m") else {
            fatalError("Focus task was not created")
        }
        let start = Date(timeIntervalSince1970: 100)
        let pause = Date(timeIntervalSince1970: 700)
        store.startFocus(task, now: start)
        require(store.activeFocusTask?.id == task.id, "Focus task did not become active")
        store.pauseFocus(task, now: pause)
        require(Int(store.focusSeconds(for: task, now: pause)) == 600, "Focus seconds were not accumulated")
        require(Int(store.focusRemainingSeconds(for: task, now: pause, defaultMinutes: 45)) == 900, "Task duration should override default focus minutes")
        require(store.activeFocusTask == nil, "Paused focus task stayed active")

        guard let defaultTask = store.addTask(title: "阅读资料") else {
            fatalError("Default focus task was not created")
        }
        require(store.focusTargetMinutes(for: defaultTask, defaultMinutes: 15) == 15, "Default focus minutes were not used")
        require(Int(store.focusRemainingSeconds(for: defaultTask, now: pause, defaultMinutes: 15)) == 900, "Default focus remaining seconds were wrong")
    }

    do {
        let store = try TaskStore(inMemory: true)
        guard let task = store.addTask(title: "整理发布清单") else {
            fatalError("Subtask task was not created")
        }
        store.addSubtask("检查安装包", to: task)
        store.addSubtask("更新说明", to: task)
        require(task.subtasks.count == 2, "Subtasks were not added")
        store.toggleSubtask(task.subtasks[0], in: task)
        require(task.completedSubtaskCount == 1, "Subtask completion was not toggled")
        store.deleteSubtask(task.subtasks[1], from: task)
        require(task.subtasks.count == 1, "Subtask was not deleted")
    }

    do {
        let store = try TaskStore(inMemory: true)
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1, hour: 10))!
        guard let task = store.addTask(title: "回复邮件") else {
            fatalError("Postpone task was not created")
        }
        store.setTodayQueue(task, isInTodayQueue: true)
        store.postpone(task, option: .tomorrow, now: now)
        require(task.postponeCount == 1, "Postpone count was not updated")
        require(task.dueAt != nil, "Postpone did not set due date")
        require(!task.isInTodayQueue, "Tomorrow postpone should leave Today queue")

        let review = store.dailyReview(now: now)
        require(review.postponedToday.count == 1, "Daily review did not include postponed task")
        require(review.tomorrowTasks.count == 1, "Daily review did not include tomorrow task")
    }

    do {
        let store = try TaskStore(inMemory: true)
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1, hour: 10))!
        let todayDue = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1, hour: 16))!
        let futureDue = calendar.date(from: DateComponents(year: 2026, month: 6, day: 4, hour: 9))!
        _ = store.addTaskFromMetadata(title: "低优未来", priority: .low, dueAt: futureDue)
        _ = store.addTaskFromMetadata(title: "高优今天", priority: .high, dueAt: todayDue, estimatedMinutes: 20)
        _ = store.addTaskFromMetadata(title: "中优无日期", priority: .medium)

        require(store.suggestedTodayTasks(limit: 1, now: now).first?.title == "高优今天", "Suggested tasks did not prioritize high due-today task")

        guard let task = store.incompleteTasks.first(where: { $0.title == "中优无日期" }) else {
            fatalError("Task for this-week postpone was missing")
        }
        store.postpone(task, option: .thisWeek, now: now)
        require(task.dueAt != nil, "This-week postpone did not set due date")
        require(!task.isInTodayQueue, "This-week postpone should leave Today queue")
    }

    do {
        let store = try TaskStore(inMemory: true)
        guard let task = store.addTask(title: "导出测试 #数据 !高 /10m") else {
            fatalError("Export task was not created")
        }
        store.addSubtask("子任务", to: task)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("TaskIslandChecks-\(UUID().uuidString).json")
        try store.exportTasks(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let importedStore = try TaskStore(inMemory: true)
        let count = try importedStore.importTasks(from: url)
        require(count == 1, "Import count was wrong")
        require(importedStore.incompleteCount == 1, "Imported store task count was wrong")
        let importedTask = importedStore.incompleteTasks[0]
        require(importedTask.priority == .high, "Imported priority was wrong")
        require(importedTask.tags == ["数据"], "Imported tags were wrong")
        require(importedTask.subtasks.count == 1, "Imported subtasks were wrong")
    }

    do {
        let store = try TaskStore(inMemory: true)
        let calendar = Calendar(identifier: .gregorian)
        let dueDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 3, hour: 10))!
        _ = store.addTaskFromMetadata(
            title: "准备客户演示",
            notes: "带上设计稿",
            priority: .high,
            dueAt: dueDate,
            tags: ["客户", "演示"],
            projectName: "增长项目",
            estimatedMinutes: 45
        )
        _ = store.addTask(title: "无日期任务 #杂项 +个人")

        require(store.allTags.contains("客户") && store.allTags.contains("演示"), "All tags did not include imported tags")
        require(store.allProjects.contains("增长项目"), "All projects did not include project")
        require(store.upcomingTasks.first?.title == "准备客户演示", "Upcoming tasks did not sort due task first")
        require(store.incompleteTasks(tagged: "客户").count == 1, "Tag filter did not find task")
        require(store.incompleteTasks(inProject: "增长项目").count == 1, "Project filter did not find task")
        require(store.tasks(matching: "设计稿").count == 1, "Search did not match notes")
    }

    do {
        let store = try TaskStore(inMemory: true)
        guard let task = store.addTask(title: "编辑详情") else {
            fatalError("Metadata edit task was not created")
        }
        store.setProjectName(task, projectName: "产品")
        store.setTags(task, tags: ["设计", "发布"])
        store.setEstimatedMinutes(task, estimatedMinutes: 35)
        store.setRepeatRule(task, repeatRule: .monthly)

        require(task.projectName == "产品", "Project setter did not persist")
        require(task.tags == ["设计", "发布"], "Tag setter did not persist")
        require(task.estimatedMinutes == 35, "Estimate setter did not persist")
        require(task.repeatRule == .monthly, "Repeat setter did not persist")
    }

    do {
        let store = try TaskStore(inMemory: true)
        _ = store.addTask(title: "CSV 导出 #数据 !高 /10m")
        let csvURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("TaskIslandChecks-\(UUID().uuidString).csv")
        let markdownURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("TaskIslandChecks-\(UUID().uuidString).md")
        defer {
            try? FileManager.default.removeItem(at: csvURL)
            try? FileManager.default.removeItem(at: markdownURL)
        }

        try store.exportTasks(to: csvURL, format: .csv)
        try store.exportTasks(to: markdownURL, format: .markdown)
        let csvText = try String(contentsOf: csvURL, encoding: .utf8)
        let markdownText = try String(contentsOf: markdownURL, encoding: .utf8)
        require(csvText.contains("CSV 导出"), "CSV export did not include task title")
        require(markdownText.contains("# 任务岛导出"), "Markdown export did not include title")

        let importedStore = try TaskStore(inMemory: true)
        let count = try importedStore.importCSVTasks(from: csvURL)
        require(count == 1, "CSV import count was wrong")
        require(importedStore.incompleteTasks.first?.tags == ["数据"], "CSV import tags were wrong")
    }

    do {
        let todoistCSV = """
        TYPE,CONTENT,DESCRIPTION,PRIORITY,DATE,LABELS,PROJECT
        task,发周报,整理本周数据,1,2026-06-05 18:00,工作|周报,运营
        """
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("TaskIslandChecks-Todoist-\(UUID().uuidString).csv")
        try todoistCSV.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let store = try TaskStore(inMemory: true)
        let count = try store.importCSVTasks(from: url)
        require(count == 1, "Todoist-style CSV import count was wrong")
        guard let task = store.incompleteTasks.first else {
            fatalError("Todoist-style CSV task was missing")
        }
        require(task.title == "发周报", "Todoist-style CSV title was wrong")
        require(task.notes == "整理本周数据", "Todoist-style CSV notes were wrong")
        require(task.priority == .high, "Todoist-style CSV priority was wrong")
        require(task.tags == ["工作", "周报"], "Todoist-style CSV labels were wrong")
        require(task.projectName == "运营", "Todoist-style CSV project was wrong")
        require(task.dueAt != nil, "Todoist-style CSV due date was missing")
    }
}

do {
    try await MainActor.run {
        try runChecks()
    }
    print("TaskIsland checks passed")
} catch {
    fputs("TaskIsland checks failed: \(error.localizedDescription)\n", stderr)
    exit(1)
}
