import Foundation
import SwiftUI
import TaskIslandCore

struct TaskRowView: View {
    @EnvironmentObject private var store: TaskStore
    @EnvironmentObject private var settings: AppSettings
    @State private var isShowingDetails = false
    @State private var notesDraft = ""
    @State private var newSubtaskTitle = ""
    @State private var projectDraft = ""
    @State private var tagsDraft = ""
    @State private var estimatedMinutesDraft = ""
    @State private var hasDueDateDraft = false
    @State private var dueDateDraft = Date()
    @State private var hasReminderDateDraft = false
    @State private var reminderDateDraft = Date()

    let task: TaskItem

    var body: some View {
        let tint = task.priority.tintColor(settings: settings)
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Circle()
                    .fill(tint)
                    .frame(width: 8, height: 8)
                    .shadow(color: tint.opacity(0.42), radius: 3)

                VStack(alignment: .leading, spacing: 3) {
                    Text(task.title)
                        .font(.system(size: 14, weight: task.isCurrent ? .semibold : .regular))
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    HStack(spacing: 6) {
                        if task.isCurrent {
                            metadataBadge("当前", systemName: "smallcircle.filled.circle")
                        } else {
                            currentTaskButton
                        }
                        todayQueueButton
                        if let dueAt = task.dueAt {
                            metadataBadge(shortDateText(dueAt), systemName: "calendar")
                        }
                        if let estimatedMinutes = task.estimatedMinutes {
                            metadataBadge("\(estimatedMinutes) 分钟", systemName: "timer")
                        }
                        if task.focusStartedAt != nil || task.focusSeconds > 0 {
                            focusMetadataBadge
                        }
                        if !task.subtasks.isEmpty {
                            metadataBadge("\(task.completedSubtaskCount)/\(task.subtasks.count)", systemName: "checklist")
                        }
                        if let repeatRule = task.repeatRule {
                            metadataBadge(repeatRule.title, systemName: "repeat")
                        }
                        if let projectName = task.projectName, !projectName.isEmpty {
                            metadataBadge(projectName, systemName: "tray")
                        }
                        ForEach(task.tags.prefix(2), id: \.self) { tag in
                            metadataBadge("#\(tag)", systemName: "tag")
                        }
                    }
                    .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    toggleDetails()
                }

                Spacer(minLength: 6)

                Button {
                    toggleDetails()
                } label: {
                    Image(systemName: isShowingDetails ? "chevron.up" : "chevron.down")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(TaskRowIconButtonStyle(tint: .secondary))
                .help(isShowingDetails ? "收起详情" : "展开详情")

                Button {
                    store.toggleFocus(task)
                } label: {
                    Image(systemName: task.focusStartedAt == nil ? "timer" : "pause.fill")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(TaskRowIconButtonStyle(tint: Color(red: 0.16, green: 0.48, blue: 0.92)))
                .help(task.focusStartedAt == nil ? "开始专注" : "暂停专注")

                priorityMenu

                Button {
                    store.complete(task)
                } label: {
                    Image(systemName: "checkmark")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(TaskRowIconButtonStyle(tint: Color(red: 0.16, green: 0.68, blue: 0.34)))
                .help("完成任务")

                Button {
                    store.delete(task)
                } label: {
                    Image(systemName: "trash")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(TaskRowIconButtonStyle(tint: .secondary))
                .help("删除任务")
            }

            if isShowingDetails {
                detailPanel
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(rowBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(tint.opacity(task.isCurrent ? 0.35 : 0.16), lineWidth: 1)
        }
        .onAppear {
            syncDrafts()
        }
    }

    private var rowBackground: some ShapeStyle {
        task.isCurrent ? AnyShapeStyle(.thinMaterial) : AnyShapeStyle(.ultraThinMaterial)
    }

    private func metadataBadge(_ title: String, systemName: String) -> some View {
        Label(title, systemImage: systemName)
            .font(.system(size: 10.5, weight: .medium))
            .foregroundStyle(.secondary)
            .labelStyle(.titleAndIcon)
    }

    private var focusMetadataBadge: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            metadataBadge(
                focusBadgeText(now: timeline.date),
                systemName: task.focusStartedAt == nil ? "timer" : "timer.circle.fill"
            )
        }
    }

    private var todayQueueButton: some View {
        Button {
            store.setTodayQueue(task, isInTodayQueue: !task.isInTodayQueue)
        } label: {
            Label(task.isInTodayQueue ? "今天" : "加入今天", systemImage: task.isInTodayQueue ? "sun.max.fill" : "sun.max")
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(task.isInTodayQueue ? Color.orange : Color.secondary)
                .labelStyle(.titleAndIcon)
        }
        .buttonStyle(.plain)
        .help(task.isInTodayQueue ? "移出今天队列" : "加入今天队列")
    }

    private var currentTaskButton: some View {
        Button {
            store.setCurrent(task)
        } label: {
            Label("设为当前", systemImage: "arrowtriangle.right.circle")
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .labelStyle(.titleAndIcon)
        }
        .buttonStyle(.plain)
        .help("把这条任务设为当前任务")
    }

    private var detailPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            focusControls

            HStack(spacing: 8) {
                quickDateButton("今天", systemName: "sun.max") {
                    let date = defaultDate(hour: 9, dayOffset: 0)
                    hasDueDateDraft = true
                    dueDateDraft = date
                    hasReminderDateDraft = true
                    reminderDateDraft = date
                    store.setDueDate(task, dueAt: date, reminderAt: date)
                }
                quickDateButton("明天", systemName: "calendar.badge.plus") {
                    let date = defaultDate(hour: 9, dayOffset: 1)
                    hasDueDateDraft = true
                    dueDateDraft = date
                    hasReminderDateDraft = true
                    reminderDateDraft = date
                    store.setDueDate(task, dueAt: date, reminderAt: date)
                }
                quickDateButton("清除日期", systemName: "calendar.badge.minus") {
                    hasDueDateDraft = false
                    hasReminderDateDraft = false
                    store.setDueDate(task, dueAt: nil)
                }
                postponeMenu
                Spacer()
            }

            dateReminderEditor
            metadataEditor
            subtaskEditor

            TextEditor(text: $notesDraft)
                .font(.system(size: 12))
                .scrollContentBackground(.hidden)
                .frame(height: 56)
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(.white.opacity(0.20), lineWidth: 1)
                }

            HStack {
                Text("备注")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("保存") {
                    store.updateNotes(task, notes: notesDraft)
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .semibold))
            }
        }
        .padding(.leading, 18)
    }

    private var metadataEditor: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                TextField("项目", text: $projectDraft)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 7)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                TextField("标签，用空格分隔", text: $tagsDraft)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 7)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                TextField("专注分钟", text: $estimatedMinutesDraft)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .frame(width: 72)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 7)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .help("本任务单独的专注时长；留空使用设置里的默认时长")
            }

            HStack(spacing: 8) {
                repeatMenu
                Spacer()
                Button("保存信息") {
                    saveMetadataDrafts()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .semibold))
            }
        }
    }

    private var dateReminderEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Toggle("截止时间", isOn: $hasDueDateDraft)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 76, alignment: .leading)
                DatePicker("", selection: $dueDateDraft, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .disabled(!hasDueDateDraft)
                    .opacity(hasDueDateDraft ? 1 : 0.42)
            }

            HStack(spacing: 8) {
                Toggle("提醒时间", isOn: $hasReminderDateDraft)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 76, alignment: .leading)
                DatePicker("", selection: $reminderDateDraft, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .disabled(!hasReminderDateDraft)
                    .opacity(hasReminderDateDraft ? 1 : 0.42)
                Spacer()
                Button("保存时间") {
                    saveDateReminderDrafts()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .semibold))
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        }
    }

    private var repeatMenu: some View {
        Menu {
            Button {
                store.setRepeatRule(task, repeatRule: nil)
            } label: {
                Label("不重复", systemImage: "minus.circle")
            }
            ForEach(TaskRepeatRule.allCases) { repeatRule in
                Button {
                    store.setRepeatRule(task, repeatRule: repeatRule)
                } label: {
                    Label(repeatRule.title, systemImage: "repeat")
                }
            }
        } label: {
            Label(task.repeatRule?.title ?? "不重复", systemImage: "repeat")
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .help("修改重复规则")
    }

    private var focusControls: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            HStack(spacing: 8) {
                Label(focusDetailText(now: timeline.date), systemImage: task.focusStartedAt == nil ? "timer" : "timer.circle.fill")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer(minLength: 8)

                quickDateButton(task.focusStartedAt == nil ? "开始专注" : "暂停", systemName: task.focusStartedAt == nil ? "play.fill" : "pause.fill") {
                    store.toggleFocus(task)
                }
            }
        }
    }

    private var postponeMenu: some View {
        Menu {
            ForEach(TaskPostponeOption.allCases) { option in
                Button {
                    store.postpone(task, option: option)
                } label: {
                    Label(option.title, systemImage: optionSystemName(option))
                }
            }
        } label: {
            Label("推迟", systemImage: "clock.arrow.circlepath")
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .help("推迟任务")
    }

    private var subtaskEditor: some View {
        VStack(alignment: .leading, spacing: 7) {
            if !task.subtasks.isEmpty {
                ForEach(task.subtasks) { subtask in
                    HStack(spacing: 7) {
                        Button {
                            store.toggleSubtask(subtask, in: task)
                        } label: {
                            Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(subtask.isCompleted ? Color.green : Color.secondary)
                        }
                        .buttonStyle(.plain)

                        Text(subtask.title)
                            .font(.system(size: 12))
                            .foregroundStyle(subtask.isCompleted ? .secondary : .primary)
                            .strikethrough(subtask.isCompleted)
                            .lineLimit(1)

                        Spacer(minLength: 6)

                        Button {
                            store.deleteSubtask(subtask, from: task)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .foregroundStyle(.secondary)
                TextField("新增子任务", text: $newSubtaskTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .onSubmit(addSubtask)
                Button("添加") {
                    addSubtask()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .semibold))
                .disabled(newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func quickDateButton(_ title: String, systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemName)
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func shortDateText(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "今天 \(timeText(date))"
        }
        if calendar.isDateInTomorrow(date) {
            return "明天 \(timeText(date))"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }

    private func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func focusBadgeText(now: Date) -> String {
        if task.focusStartedAt == nil {
            return formattedDuration(store.focusSeconds(for: task, now: now))
        }
        return "剩 \(formattedDuration(store.focusRemainingSeconds(for: task, now: now, defaultMinutes: settings.defaultFocusMinutesInt)))"
    }

    private func focusDetailText(now: Date) -> String {
        let elapsed = formattedDuration(store.focusSeconds(for: task, now: now))
        let remaining = formattedDuration(store.focusRemainingSeconds(for: task, now: now, defaultMinutes: settings.defaultFocusMinutesInt))
        let targetMinutes = store.focusTargetMinutes(for: task, defaultMinutes: settings.defaultFocusMinutesInt)
        let sourceText = task.estimatedMinutes == nil ? "默认" : "本任务"
        if task.focusStartedAt == nil {
            return "已专注 \(elapsed)，\(sourceText)按 \(targetMinutes) 分钟一轮"
        }
        return "专注中：已用 \(elapsed)，剩余 \(remaining)"
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

    private func optionSystemName(_ option: TaskPostponeOption) -> String {
        switch option {
        case .fifteenMinutes:
            return "timer"
        case .laterToday:
            return "sunset"
        case .tomorrow:
            return "calendar.badge.clock"
        case .thisWeek:
            return "calendar"
        }
    }

    private func addSubtask() {
        store.addSubtask(newSubtaskTitle, to: task)
        newSubtaskTitle = ""
    }

    private func toggleDetails() {
        syncDrafts()
        withAnimation(.easeInOut(duration: 0.16)) {
            isShowingDetails.toggle()
        }
    }

    private func syncDrafts() {
        notesDraft = task.notes
        projectDraft = task.projectName ?? ""
        tagsDraft = task.tags.joined(separator: " ")
        estimatedMinutesDraft = task.estimatedMinutes.map(String.init) ?? ""
        hasDueDateDraft = task.dueAt != nil
        dueDateDraft = task.dueAt ?? defaultDate(hour: 9, dayOffset: 0)
        hasReminderDateDraft = task.reminderAt != nil
        reminderDateDraft = task.reminderAt ?? task.dueAt ?? defaultDate(hour: 9, dayOffset: 0)
    }

    private func saveMetadataDrafts() {
        let tags = tagsDraft
            .split { $0 == " " || $0 == "," || $0 == "，" || $0 == "#" }
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let estimatedMinutes = Int(estimatedMinutesDraft.trimmingCharacters(in: .whitespacesAndNewlines))

        store.setProjectName(task, projectName: projectDraft)
        store.setTags(task, tags: tags)
        store.setEstimatedMinutes(task, estimatedMinutes: estimatedMinutes)
    }

    private func saveDateReminderDrafts() {
        store.setDueDate(
            task,
            dueAt: hasDueDateDraft ? dueDateDraft : nil,
            reminderAt: hasReminderDateDraft ? reminderDateDraft : nil
        )
    }

    private func defaultDate(hour: Int, dayOffset: Int) -> Date {
        let base = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
        return Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: base) ?? base
    }

    private var priorityMenu: some View {
        Menu {
            ForEach(TaskPriority.allCases) { priority in
                Button {
                    store.setPriority(task, priority: priority)
                } label: {
                    Label(priority.title, systemImage: priority.symbolName)
                }
            }
        } label: {
            HStack(spacing: 5) {
                Circle()
                    .fill(task.priority.tintColor(settings: settings))
                    .frame(width: 7, height: 7)
                Text(task.priority.shortTitle)
                    .font(.system(size: 11, weight: .semibold))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .stroke(task.priority.tintColor(settings: settings).opacity(0.28), lineWidth: 1)
        }
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .help("修改优先级")
    }
}

private struct TaskRowIconButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11.5, weight: .bold))
            .foregroundStyle(tint)
            .background(.ultraThinMaterial, in: Circle())
            .overlay {
                Circle()
                    .stroke(.white.opacity(configuration.isPressed ? 0.20 : 0.34), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}
