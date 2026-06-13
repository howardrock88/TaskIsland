import SwiftUI
import TaskIslandCore

@MainActor
final class IslandViewState: ObservableObject {
    @Published var isExpanded = false
    @Published var showsExpandedContent = false
    @Published var isResizing = false
    @Published var isPinned = false
    @Published var usesAttentionSize = false
    @Published var focusAttentionTaskID: UUID?
    @Published var focusCompletionTaskID: UUID?
    @Published var focusCompletionStartedAt = Date()
    @Published var reminderTaskID: UUID?
    @Published var attentionStartedAt = Date()
}

struct CapsuleIslandView: View {
    @EnvironmentObject private var store: TaskStore
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject var viewState: IslandViewState

    let onOpenTasks: () -> Void
    let onQuickAdd: () -> Void
    let onPinToggle: () -> Void
    let onHoverChanged: (Bool) -> Void

    var body: some View {
        ZStack {
            collapsedContent
                .opacity(showsCollapsedContent ? 1 : 0)
                .scaleEffect(showsExpandedContent ? 0.985 : 1)
                .allowsHitTesting(showsCollapsedContent)

            attentionContent
                .opacity(showsAttentionContent ? 1 : 0)
                .scaleEffect(showsAttentionContent ? 1 : 0.985)
                .allowsHitTesting(showsAttentionContent)

            expandedContent
                .opacity(showsExpandedDetails ? 1 : 0)
                .scaleEffect(isExpanded ? 1 : 0.985)
                .allowsHitTesting(showsExpandedDetails)
        }
        .padding(.horizontal, isVisuallyExpanded ? 12 : (isAttentionMode ? 12 : 14))
        .padding(.vertical, isVisuallyExpanded ? 7 : (isAttentionMode ? 6 : 3))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(islandShape)
        .background {
            islandGlass
        }
        .clipShape(islandShape)
        .mask(islandShape)
        .overlay {
            darkIslandShade
                .allowsHitTesting(false)
        }
        .overlay {
            islandShape
                .stroke(
                    LinearGradient(
                        colors: islandStrokeColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isVisuallyExpanded ? 1 : 1.2
                )
        }
        .overlay {
            visibilityContour
                .allowsHitTesting(false)
        }
        .overlay {
            attentionGlowOverlay
                .allowsHitTesting(false)
        }
        .shadow(
            color: .black.opacity(settings.darkGlassMode ? (isVisuallyExpanded ? 0.34 : 0.28) : (isVisuallyExpanded ? 0.18 : 0.15)),
            radius: isVisuallyExpanded ? 18 : 11,
            x: 0,
            y: isVisuallyExpanded ? 12 : 7
        )
        .shadow(
            color: .white.opacity(settings.darkGlassMode ? 0.04 : 0.22),
            radius: 2,
            x: 0,
            y: -1
        )
        .opacity(capsuleVisibilityScale)
        .onHover { hovered in
            onHoverChanged(hovered)
        }
        .highPriorityGesture(
            SpatialTapGesture()
                .onEnded { value in
                    handleIslandTap(at: value.location)
                }
        )
        .animation(.easeOut(duration: 0.14), value: showsExpandedContent)
        .animation(.easeInOut(duration: 0.16), value: settings.capsuleTransparencyPercent)
        .animation(.easeInOut(duration: 0.18), value: settings.capsuleBackgroundColorHex)
        .animation(.easeInOut(duration: 0.18), value: settings.capsuleTextColorHex)
        .preferredColorScheme(settings.darkGlassMode ? .dark : nil)
    }

    private var isExpanded: Bool {
        viewState.isExpanded
    }

    private var isPinned: Bool {
        viewState.isPinned
    }

    private var showsExpandedContent: Bool {
        viewState.showsExpandedContent
    }

    private var isResizing: Bool {
        viewState.isResizing
    }

    private var usesAttentionSize: Bool {
        viewState.usesAttentionSize
    }

    private var isAttentionMode: Bool {
        usesAttentionSize && !isExpanded
    }

    private var attentionTask: TaskItem? {
        focusCompletionTask ?? focusAttentionTask ?? reminderTask
    }

    private var focusCompletionTask: TaskItem? {
        guard let focusCompletionTaskID = viewState.focusCompletionTaskID else { return nil }
        return store.incompleteTasks.first { $0.id == focusCompletionTaskID }
    }

    private var focusAttentionTask: TaskItem? {
        if let task = store.focusAttentionTask {
            return task
        }
        guard let focusAttentionTaskID = viewState.focusAttentionTaskID else { return nil }
        return store.incompleteTasks.first { $0.id == focusAttentionTaskID }
    }

    private var reminderTask: TaskItem? {
        guard let reminderTaskID = viewState.reminderTaskID else { return nil }
        return store.incompleteTasks.first { $0.id == reminderTaskID }
    }

    private var isFocusAttention: Bool {
        focusCompletionTask == nil && focusAttentionTask != nil
    }

    private var isFocusCompletionAttention: Bool {
        focusCompletionTask != nil
    }

    private var isReminderAttention: Bool {
        !isFocusCompletionAttention && !isFocusAttention && reminderTask != nil
    }

    private var showsCollapsedContent: Bool {
        !isExpanded && !showsExpandedContent && !isResizing && attentionTask == nil
    }

    private var showsAttentionContent: Bool {
        !isExpanded && !showsExpandedContent && !isResizing && attentionTask != nil
    }

    private var showsExpandedDetails: Bool {
        isExpanded && showsExpandedContent && !isResizing
    }

    private var isVisuallyExpanded: Bool {
        isExpanded || showsExpandedContent || (isResizing && !isAttentionMode)
    }

    private var islandCornerRadius: CGFloat {
        if isAttentionMode {
            return 26
        }
        return isVisuallyExpanded ? 28 : 15
    }

    private var islandShape: IslandGlassShape {
        IslandGlassShape(isExpanded: isVisuallyExpanded)
    }

    private var capsuleOpacityProgress: Double {
        1 - AppSettings.clampedTransparency(settings.capsuleTransparencyPercent) / 100
    }

    private var capsuleVisibilityScale: Double {
        let defaultProgress = 0.72
        guard capsuleOpacityProgress < defaultProgress else { return 1 }
        return capsuleOpacityProgress / defaultProgress
    }

    private var capsuleDensityBoost: Double {
        let defaultProgress = 0.72
        guard capsuleOpacityProgress > defaultProgress else { return 0 }
        return min((capsuleOpacityProgress - defaultProgress) / (1 - defaultProgress), 1)
    }

    private func boostedOpacity(_ opacity: Double, boost: Double = 0.45) -> Double {
        min(opacity * (1 + capsuleDensityBoost * boost), 1)
    }

    private var islandGlass: some View {
        ZStack {
            if isVisuallyExpanded {
                Color.clear
                    .taskIslandGlass(in: islandShape)
                    .opacity(boostedOpacity(settings.darkGlassMode ? 0.82 : 0.52, boost: 0.30))
            } else {
                islandShape
                    .fill(
                        LinearGradient(
                            colors: collapsedGlassBaseColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            islandShape
                .fill(
                    LinearGradient(
                        colors: backgroundTintColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(boostedOpacity(isVisuallyExpanded ? 0.30 : 0.42, boost: 0.22))

            if capsuleDensityBoost > 0 {
                islandShape
                    .fill(
                        LinearGradient(
                            colors: densityOverlayColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(capsuleDensityBoost)
            }

            islandShape
                .fill(
                    LinearGradient(
                        colors: glassPresenceColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            islandShape
                .fill(
                    LinearGradient(
                        colors: glassTintColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(settings.darkGlassMode ? .normal : .plusLighter)

            islandShape
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(settings.darkGlassMode ? 0.080 : 0.062),
                            .clear,
                            .black.opacity(settings.darkGlassMode ? (isVisuallyExpanded ? 0.10 : 0.22) : (isVisuallyExpanded ? 0.018 : 0.060))
                        ],
                        startPoint: isVisuallyExpanded ? .top : .topLeading,
                        endPoint: isVisuallyExpanded ? .bottom : .bottomTrailing
                    )
                )
                .opacity(boostedOpacity(isVisuallyExpanded ? 0.34 : 0.62, boost: 0.26))

            GeometryReader { proxy in
                let height = proxy.size.height

                if isVisuallyExpanded {
                    RoundedRectangle(cornerRadius: max(islandCornerRadius - 6, 18), style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(settings.darkGlassMode ? 0.22 : 0.18),
                                    .white.opacity(settings.darkGlassMode ? 0.07 : 0.050),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: max(height * 0.32, 16))
                        .blur(radius: 0.55)
                        .padding(.horizontal, 8)
                        .padding(.top, 2)
                } else {
                    Capsule(style: .circular)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(settings.darkGlassMode ? 0.24 : 0.28),
                                    .white.opacity(settings.darkGlassMode ? 0.09 : 0.08),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: max(proxy.size.width - height * 1.28, 72), height: 10)
                        .offset(x: height * 0.52, y: 3)
                        .blur(radius: 0.5)
                }

                if !isVisuallyExpanded {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(settings.darkGlassMode ? 0.20 : 0.32),
                                    .white.opacity(settings.darkGlassMode ? 0.08 : 0.12),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: max(proxy.size.width - height * 1.1, 84), height: 1.2)
                        .offset(x: height * 0.50, y: height * 0.20)
                        .blur(radius: 0.18)
                }

                islandShape
                    .stroke(.white.opacity(settings.darkGlassMode ? 0.24 : 0.42), lineWidth: 3.5)
                    .blur(radius: 4)
                    .offset(x: -1.5, y: -1.5)
                    .opacity(settings.darkGlassMode ? 0.54 : 0.68)

                islandShape
                    .stroke(.black.opacity(settings.darkGlassMode ? 0.30 : 0.13), lineWidth: 3.5)
                    .blur(radius: 4)
                    .offset(x: 1.5, y: 2)
                    .opacity(settings.darkGlassMode ? 0.48 : 0.38)
            }
            .allowsHitTesting(false)

            if isVisuallyExpanded {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                .white.opacity(settings.darkGlassMode ? 0.14 : 0.24),
                                Color(red: 0.64, green: 0.92, blue: 1.0).opacity(settings.darkGlassMode ? 0.08 : 0.11),
                                .clear
                            ],
                            center: .center,
                            startRadius: 2,
                            endRadius: 82
                        )
                    )
                    .frame(width: 132, height: 92)
                    .blur(radius: 3)
                    .offset(x: 164, y: -44)
                    .allowsHitTesting(false)
            }
        }
        .compositingGroup()
    }

    @ViewBuilder
    private var darkIslandShade: some View {
        if settings.darkGlassMode {
            islandShape
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(isVisuallyExpanded ? 0.18 : 0.12),
                            Color(red: 0.03, green: 0.08, blue: 0.12).opacity(isVisuallyExpanded ? 0.16 : 0.10),
                            Color.black.opacity(isVisuallyExpanded ? 0.26 : 0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    private var collapsedContent: some View {
        Button {
            onOpenTasks()
        } label: {
            HStack(spacing: 11) {
                if store.incompleteCount == 0 {
                    Label(t("完成", "Done"), systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(capsuleTextColor)
                } else {
                    ForEach(TaskPriority.allCases) { priority in
                        priorityCount(priority, compact: true)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .help(t("打开任务面板", "Open task panel"))
    }

    private var attentionContent: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            if let task = attentionTask {
                let tint = task.priority.tintColor(settings: settings)
                HStack(spacing: 9) {
                    ZStack {
                        Circle()
                            .fill(tint.opacity(isFocusCompletionAttention ? 0.30 : (isReminderAttention ? 0.28 : 0.18)))
                            .frame(width: 26, height: 26)
                        Image(systemName: attentionIconName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(isFocusAttention ? capsuleTextColor : tint)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title)
                            .font(.system(size: 13.5, weight: .semibold))
                            .foregroundStyle(capsuleTextColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)

                        Text(attentionSubtitle(for: task, now: timeline.date))
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundStyle(capsuleSecondaryTextColor)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 4)

                    Text(attentionTrailingText(for: task, now: timeline.date))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(capsuleTextColor)
                        .padding(.horizontal, isFocusCompletionAttention ? 12 : 8)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(isFocusCompletionAttention ? 0.18 : (isReminderAttention ? 0.14 : 0.09)), in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(tint.opacity(isFocusCompletionAttention ? 0.48 : (isReminderAttention ? 0.34 : 0.20)), lineWidth: 1)
                        }

                    if isFocusAttention {
                        HStack(spacing: 5) {
                            AttentionActionButton(
                                systemName: task.focusStartedAt == nil ? "play.fill" : "pause.fill",
                                foregroundColor: capsuleTextColor,
                                help: task.focusStartedAt == nil ? t("继续专注", "Resume focus") : t("暂停专注", "Pause focus")
                            )

                            AttentionActionButton(
                                systemName: "stop.fill",
                                foregroundColor: capsuleTextColor,
                                help: t("停止专注", "Stop focus")
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private var attentionGlowOverlay: some View {
        if showsAttentionContent, let task = attentionTask {
            if isFocusCompletionAttention {
                TimelineView(.animation) { timeline in
                    let elapsed = timeline.date.timeIntervalSince(viewState.focusCompletionStartedAt)
                    let rotation = elapsed * 230
                    let wave = (sin(elapsed * 6.2) + 1) / 2
                    let beat = pow(max(sin(elapsed * .pi * 2.4), 0), 5)
                    let tint = task.priority.tintColor(settings: settings)
                    let glowOpacity = 0.58 + 0.36 * wave

                    ZStack {
                        GeometryReader { proxy in
                            let sweepProgress = CGFloat((elapsed * 0.20).truncatingRemainder(dividingBy: 1))
                            let sweepWidth = max(proxy.size.width * 0.80, 260)
                            let sweepX = -sweepWidth / 2 + (proxy.size.width + sweepWidth) * sweepProgress

                            ZStack {
                                Capsule(style: .continuous)
                                    .fill(
                                        LinearGradient(
                                        colors: [
                                            .clear,
                                            .white.opacity(0.18 + 0.12 * wave),
                                            .white.opacity(0.48 + 0.20 * wave),
                                            tint.opacity(0.34 + 0.20 * wave),
                                            Color.green.opacity(0.20 + 0.16 * wave),
                                            .clear
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                    .frame(width: sweepWidth, height: proxy.size.height * 1.70)
                                    .rotationEffect(.degrees(-10))
                                    .position(x: sweepX, y: proxy.size.height * 0.45)
                                    .blur(radius: 2.5)
                                    .shadow(color: .white.opacity(0.34 + 0.20 * wave), radius: 6)

                                Capsule(style: .continuous)
                                    .fill(.white.opacity(0.30 + 0.22 * beat))
                                    .frame(width: max(proxy.size.width * 0.13, 42), height: proxy.size.height * 1.52)
                                    .rotationEffect(.degrees(-10))
                                    .position(x: sweepX + sweepWidth * 0.21, y: proxy.size.height * 0.43)
                                    .blur(radius: 1.2)
                                    .shadow(color: .white.opacity(0.44), radius: 5)
                            }
                            .blendMode(settings.darkGlassMode ? .screen : .plusLighter)
                            .clipShape(islandShape)
                        }
                        .allowsHitTesting(false)

                        islandShape
                            .stroke(
                                AngularGradient(
                                    colors: [
                                        .clear,
                                        tint.opacity(0.36),
                                        .white.opacity(glowOpacity),
                                        tint.opacity(glowOpacity),
                                        Color.green.opacity(0.48 + 0.26 * wave),
                                        .clear
                                    ],
                                    center: .center,
                                    startAngle: .degrees(rotation),
                                    endAngle: .degrees(rotation + 360)
                                ),
                                lineWidth: 3.4
                            )
                            .padding(2)
                            .blur(radius: 0.45)
                            .shadow(color: tint.opacity(0.34 + 0.22 * wave), radius: 4)

                        islandShape
                            .stroke(
                                AngularGradient(
                                    colors: [
                                        .clear,
                                        .white.opacity(0.92),
                                        tint.opacity(0.88),
                                        Color.green.opacity(0.74),
                                        .white.opacity(0.80),
                                        .clear
                                    ],
                                    center: .center,
                                    startAngle: .degrees(elapsed * 310),
                                    endAngle: .degrees(elapsed * 310 + 360)
                                ),
                                style: StrokeStyle(
                                    lineWidth: 2.6 + 1.8 * beat,
                                    lineCap: .round,
                                    lineJoin: .round,
                                    dash: [2, 4, 16, 4, 4, 8, 28, 5, 3, 7],
                                    dashPhase: -elapsed * 118
                                )
                            )
                            .padding(2.5)
                            .shadow(color: tint.opacity(0.58 + 0.24 * beat), radius: 7 + 4 * beat)

                        focusCompletionPulseSegment(
                            start: elapsed * 0.62,
                            length: 0.22 + 0.04 * beat,
                            tint: tint,
                            opacity: 0.90 + 0.10 * beat,
                            lineWidth: 3.3 + 1.7 * beat
                        )

                        islandShape
                            .stroke(
                                .white.opacity(0.28 + 0.36 * beat),
                                style: StrokeStyle(
                                    lineWidth: 1.6 + 1.2 * beat,
                                    lineCap: .round,
                                    lineJoin: .round,
                                    dash: [1, 4, 9, 3, 1, 10, 18, 4],
                                    dashPhase: -elapsed * 96
                                )
                            )
                            .padding(3)

                        islandShape
                            .stroke(Color.green.opacity(0.30 + 0.22 * wave), lineWidth: 5.5)
                            .padding(3)
                            .blur(radius: 5.5)
                            .scaleEffect(1.0 + 0.014 * wave)

                        islandShape
                            .stroke(.white.opacity(0.48 + 0.28 * wave), lineWidth: 1.45)
                            .padding(1.5)
                            .scaleEffect(1.006 + 0.006 * wave)
                    }
                }
            } else if isReminderAttention {
                TimelineView(.animation) { timeline in
                    let elapsed = timeline.date.timeIntervalSince(viewState.attentionStartedAt)
                    let rotation = elapsed * 150
                    let wave = (sin(elapsed * 5.4) + 1) / 2
                    let tint = task.priority.tintColor(settings: settings)
                    let pulseOpacity = 0.34 + 0.34 * wave

                    ZStack {
                        islandShape
                            .stroke(
                                AngularGradient(
                                    colors: [
                                        .clear,
                                        tint.opacity(pulseOpacity),
                                        .white.opacity(0.72),
                                        tint.opacity(pulseOpacity),
                                        .clear
                                    ],
                                    center: .center,
                                    startAngle: .degrees(rotation),
                                    endAngle: .degrees(rotation + 360)
                                ),
                                lineWidth: 2.5
                            )
                            .blur(radius: 0.9)

                        islandShape
                            .stroke(tint.opacity(0.18 + 0.16 * wave), lineWidth: 6)
                            .blur(radius: 8)
                            .scaleEffect(1.0 + 0.012 * wave)
                    }
                }
            } else {
                islandShape
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(settings.darkGlassMode ? 0.28 : 0.42),
                                task.priority.tintColor(settings: settings).opacity(0.10),
                                .white.opacity(settings.darkGlassMode ? 0.12 : 0.20)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .blur(radius: 0.25)
                }
        }
    }

    @ViewBuilder
    private func focusCompletionPulseSegment(
        start: Double,
        length: Double,
        tint: Color,
        opacity: Double,
        lineWidth: Double
    ) -> some View {
        let normalizedStart = start - floor(start)
        let normalizedEnd = normalizedStart + length
        let stroke = StrokeStyle(
            lineWidth: lineWidth,
            lineCap: .round,
            lineJoin: .round,
            dash: [18, 5, 3, 5, 10, 6],
            dashPhase: -start * 36
        )

        if normalizedEnd <= 1 {
            islandShape
                .trim(from: CGFloat(normalizedStart), to: CGFloat(normalizedEnd))
                .stroke(
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(min(opacity + 0.12, 1)),
                            tint.opacity(opacity)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: stroke
                )
                .padding(2.5)
        } else {
            islandShape
                .trim(from: CGFloat(normalizedStart), to: 1)
                .stroke(
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(min(opacity + 0.12, 1)),
                            tint.opacity(opacity)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: stroke
                )
                .padding(2.5)

            islandShape
                .trim(from: 0, to: CGFloat(normalizedEnd - 1))
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(min(opacity + 0.12, 1)),
                            tint.opacity(opacity),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: stroke
                )
                .padding(2.5)
        }
    }

    private var expandedContent: some View {
        HStack(spacing: 8) {
            expandedTaskPreview
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

            Rectangle()
                .fill(.white.opacity(settings.darkGlassMode ? 0.13 : 0.24))
                .frame(width: 1)
                .frame(maxHeight: 58)
                .blur(radius: 0.2)

            expandedActions
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var expandedTaskPreview: some View {
        if store.incompleteCount == 0 {
            emptyExpandedRow()
        } else {
            let tasks = store.previewTasks(limit: 3)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                    previewTaskRow(task)
                }
            }
        }
    }

    private func handleIslandTap(at location: CGPoint) {
        guard isExpanded else {
            onOpenTasks()
            return
        }

        if handleExpandedTopAction(atTopLeftPoint: location) {
            return
        }

        if handleExpandedTaskAction(atTopLeftPoint: location) {
            return
        }

        onOpenTasks()
    }

    private func handleExpandedTopAction(atTopLeftPoint point: CGPoint) -> Bool {
        let toolbarFrame = expandedToolbarFrame(panelHeight: isExpanded ? expandedPanelHeightEstimate : 92)
        let frame = CGRect(
            x: toolbarFrame.minX,
            y: toolbarFrame.minY,
            width: toolbarFrame.width,
            height: toolbarFrame.height
        )
        guard frame.contains(point) else { return false }

        let localY = point.y - frame.minY
        if localY <= 28 {
            onQuickAdd()
        } else if localY >= 36 {
            onPinToggle()
        }
        return true
    }

    private func handleExpandedTaskAction(atTopLeftPoint point: CGPoint) -> Bool {
        let tasks = store.previewTasks(limit: 3)
        guard !tasks.isEmpty else { return false }

        let rowHeight: CGFloat = 31
        let rowSpacing: CGFloat = 6
        let contentY: CGFloat = 10
        let contentHeight = max(expandedPanelHeightEstimate - 20, rowHeight)
        let stackHeight = CGFloat(tasks.count) * rowHeight + CGFloat(max(tasks.count - 1, 0)) * rowSpacing
        let rowStartY = contentY + max((contentHeight - stackHeight) / 2, 0)
        let rowStride = rowHeight + rowSpacing
        let relativeY = point.y - rowStartY
        let rowIndex = Int(relativeY / rowStride)
        guard rowIndex >= 0,
              rowIndex < tasks.count,
              relativeY.truncatingRemainder(dividingBy: rowStride) <= rowHeight else {
            return false
        }

        let actionFrame = CGRect(
            x: 300,
            y: rowStartY + CGFloat(rowIndex) * rowStride,
            width: 64,
            height: rowHeight
        )
        guard actionFrame.contains(point) else { return false }

        let task = tasks[rowIndex]
        if point.x > actionFrame.midX {
            store.delete(task)
        } else {
            store.complete(task)
        }
        return true
    }

    private var expandedPanelHeightEstimate: CGFloat {
        let visibleRows = max(1, min(3, store.incompleteCount))
        return CGFloat(max(92, visibleRows * 35 + 17))
    }

    private func expandedToolbarFrame(panelHeight: CGFloat) -> CGRect {
        let contentY: CGFloat = 11
        let contentHeight = max(panelHeight - 22, 64)
        return CGRect(
            x: 390,
            y: contentY + max((contentHeight - 64) / 2, 0),
            width: 34,
            height: 64
        )
    }

    private func priorityCount(_ priority: TaskPriority, compact: Bool) -> some View {
        let count = store.focusPriorityCounts[priority, default: 0]
        let tint = priority.tintColor(settings: settings)
        return HStack(spacing: compact ? 4 : 5) {
            Circle()
                .fill(tint)
                .frame(width: compact ? 7 : 8, height: compact ? 7 : 8)
                .shadow(color: tint.opacity(0.45), radius: 4)

            Text("\(count)")
                .font(.system(size: compact ? 12 : 11, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(capsuleTextColor)
        }
        .padding(.horizontal, compact ? 5 : 7)
        .padding(.vertical, compact ? 2 : 3)
        .contentShape(Capsule())
    }

    private var islandStrokeColors: [Color] {
        if settings.darkGlassMode {
            return [
                .white.opacity(isVisuallyExpanded ? 0.58 : 0.50),
                Color(red: 0.48, green: 0.86, blue: 1.0).opacity(isVisuallyExpanded ? 0.36 : 0.30),
                .white.opacity(isVisuallyExpanded ? 0.18 : 0.14)
            ]
        }

        return [
            .white.opacity(isVisuallyExpanded ? 0.88 : 0.86),
            Color(red: 0.68, green: 0.94, blue: 1.0).opacity(isVisuallyExpanded ? 0.42 : 0.40),
            .white.opacity(isVisuallyExpanded ? 0.30 : 0.28)
        ]
    }

    private var visibilityContour: some View {
        ZStack {
            islandShape
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(settings.darkGlassMode ? 0.48 : 0.86),
                            .white.opacity(settings.darkGlassMode ? 0.22 : 0.48),
                            .black.opacity(settings.darkGlassMode ? 0.40 : 0.26)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isVisuallyExpanded ? 1.25 : 1.65
                )
                .padding(isVisuallyExpanded ? 0 : 1)

            islandShape
                .stroke(.black.opacity(settings.darkGlassMode ? 0.22 : 0.16), lineWidth: 1.25)
                .blur(radius: 0.45)
                .offset(y: 0.8)
                .padding(isVisuallyExpanded ? 0 : 1)
        }
    }

    private var glassPresenceColors: [Color] {
        let tint = capsuleBackgroundColor
        if settings.darkGlassMode {
            return [
                Color.white.opacity(isVisuallyExpanded ? 0.055 : 0.050),
                tint.opacity(isVisuallyExpanded ? 0.12 : 0.10),
                Color.black.opacity(isVisuallyExpanded ? 0.16 : 0.13)
            ]
        }

        return [
            Color.white.opacity(isVisuallyExpanded ? 0.105 : 0.12),
            tint.opacity(isVisuallyExpanded ? 0.085 : 0.12),
            Color.black.opacity(isVisuallyExpanded ? 0.018 : 0.026)
        ]
    }

    private var collapsedGlassBaseColors: [Color] {
        let tint = capsuleBackgroundColor
        if settings.darkGlassMode {
            return [
                Color.white.opacity(0.10),
                tint.opacity(0.24),
                Color.black.opacity(0.28)
            ]
        }

        return [
            Color.white.opacity(0.40),
            tint.opacity(0.34),
            Color.white.opacity(0.20)
        ]
    }

    private var glassTintColors: [Color] {
        let tint = capsuleBackgroundColor
        if settings.darkGlassMode {
            return [
                Color.white.opacity(isVisuallyExpanded ? 0.055 : 0.045),
                tint.opacity(isVisuallyExpanded ? 0.115 : 0.090),
                Color(red: 0.18, green: 0.82, blue: 0.62).opacity(isVisuallyExpanded ? 0.055 : 0.040),
                Color.black.opacity(isVisuallyExpanded ? 0.10 : 0.14)
            ]
        }

        return [
            Color.white.opacity(isVisuallyExpanded ? 0.030 : 0.022),
            tint.opacity(isVisuallyExpanded ? 0.060 : 0.046),
            Color(red: 0.96, green: 1.0, blue: 0.82).opacity(isVisuallyExpanded ? 0.020 : 0.014),
            Color.white.opacity(isVisuallyExpanded ? 0.018 : 0.010)
        ]
    }

    private var densityOverlayColors: [Color] {
        let tint = capsuleBackgroundColor
        if settings.darkGlassMode {
            return [
                tint.opacity(0.55),
                tint.opacity(0.36),
                Color(red: 0.05, green: 0.07, blue: 0.10)
            ]
        }

        return [
            Color(red: 0.98, green: 1.0, blue: 1.0),
            tint.opacity(0.72),
            Color(red: 0.94, green: 1.0, blue: 0.96)
        ]
    }

    private var backgroundTintColors: [Color] {
        let tint = capsuleBackgroundColor
        if settings.darkGlassMode {
            return [
                tint.opacity(0.38),
                tint.opacity(0.18),
                Color.black.opacity(0.12)
            ]
        }

        return [
            Color.white.opacity(0.22),
            tint.opacity(0.56),
            tint.opacity(0.24)
        ]
    }

    private var capsuleBackgroundColor: Color {
        Color(taskIslandHex: settings.capsuleBackgroundColorHex)
            ?? Color(taskIslandHex: AppSettings.defaultCapsuleBackgroundColorHex)
            ?? Color(red: 0.78, green: 0.94, blue: 1.0)
    }

    private var capsuleTextColor: Color {
        Color(taskIslandHex: settings.capsuleTextColorHex)
            ?? automaticCapsuleTextColor
    }

    private var capsuleSecondaryTextColor: Color {
        capsuleTextColor.opacity(settings.darkGlassMode ? 0.76 : 0.66)
    }

    private var automaticCapsuleTextColor: Color {
        settings.darkGlassMode ? Color.white : Color(red: 0.06, green: 0.20, blue: 0.24)
    }

    private func previewTaskRow(_ task: TaskItem) -> some View {
        let tint = task.priority.tintColor(settings: settings)
        return HStack(spacing: 7) {
            Circle()
                .fill(tint)
                .frame(width: 7, height: 7)
                .shadow(color: tint.opacity(0.45), radius: 3)

            Text(task.title)
                .font(.system(size: 13.5, weight: task.isCurrent ? .semibold : .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .foregroundStyle(capsuleTextColor)

            if task.isCurrent {
                Text(t("当前", "Current"))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(capsuleSecondaryTextColor)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(.ultraThinMaterial, in: Capsule())
            }

            if task.focusStartedAt != nil || task.focusSeconds > 0 {
                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    Text(islandFocusText(task, now: timeline.date))
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(capsuleSecondaryTextColor)
                        .lineLimit(1)
                }
            } else if let dueAt = task.dueAt {
                Text(islandDateText(dueAt))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(capsuleSecondaryTextColor)
                    .lineLimit(1)
            } else if let estimatedMinutes = task.estimatedMinutes {
                Text("\(estimatedMinutes)m")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(capsuleSecondaryTextColor)
            }

            Spacer(minLength: 4)

            IslandTaskActionButton(
                systemName: "checkmark",
                foregroundColor: capsuleTextColor,
                help: t("完成任务", "Complete task")
            ) {
                store.complete(task)
            }

            IslandTaskActionButton(
                systemName: "trash",
                foregroundColor: capsuleTextColor,
                help: t("删除任务", "Delete task")
            ) {
                store.delete(task)
            }
        }
        .padding(.leading, 9)
        .padding(.trailing, 6)
        .frame(height: 31)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(settings.darkGlassMode ? 0.13 : (task.isCurrent ? 0.26 : 0.18)),
                    Color.white.opacity(settings.darkGlassMode ? 0.060 : (task.isCurrent ? 0.12 : 0.075))
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: Capsule()
        )
        .overlay {
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(settings.darkGlassMode ? 0.22 : 0.42),
                            tint.opacity(task.isCurrent ? 0.34 : 0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }

    private func islandDateText(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = settings.locale

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
            return t("今天 \(formatter.string(from: date))", "Today \(formatter.string(from: date))")
        }
        if calendar.isDateInTomorrow(date) {
            formatter.dateFormat = "HH:mm"
            return t("明天 \(formatter.string(from: date))", "Tomorrow \(formatter.string(from: date))")
        }

        formatter.dateFormat = settings.isEnglish ? "MMM d" : "M/d"
        return formatter.string(from: date)
    }

    private func islandFocusText(_ task: TaskItem, now: Date) -> String {
        if task.focusStartedAt == nil {
            return focusDurationText(store.focusSeconds(for: task, now: now))
        }
        return t("剩 \(focusDurationText(store.focusRemainingSeconds(for: task, now: now, defaultMinutes: settings.defaultFocusMinutesInt)))", "\(focusDurationText(store.focusRemainingSeconds(for: task, now: now, defaultMinutes: settings.defaultFocusMinutesInt))) left")
    }

    private func attentionSubtitle(for task: TaskItem, now: Date) -> String {
        if isFocusCompletionAttention {
            let minutes = store.focusTargetMinutes(for: task, defaultMinutes: settings.defaultFocusMinutesInt)
            return t("专注完成 · \(minutes) 分钟", "Focus done · \(minutes) min")
        }

        if isFocusAttention {
            let state = task.focusStartedAt == nil ? t("已暂停", "Paused") : t("专注中", "Focusing")
            return t("\(state) · \(task.priority.shortTitle)优先级", "\(state) · \(task.priority.localizedShortTitle(settings: settings))")
        }

        if let reminderAt = task.reminderAt ?? task.dueAt {
            return t("提醒到了 · \(islandDateText(reminderAt))", "Reminder due · \(islandDateText(reminderAt))")
        }
        return t("提醒到了 · \(task.priority.title)", "Reminder due · \(task.priority.localizedTitle(settings: settings))")
    }

    private func attentionTrailingText(for task: TaskItem, now: Date) -> String {
        if isFocusCompletionAttention {
            return t("完成", "Done")
        }

        if isFocusAttention {
            return focusCountdownText(store.focusRemainingSeconds(for: task, now: now, defaultMinutes: settings.defaultFocusMinutesInt))
        }
        return t("现在", "Now")
    }

    private var attentionIconName: String {
        if isFocusCompletionAttention {
            return "checkmark.circle.fill"
        }
        return isFocusAttention ? "timer.circle.fill" : "bell.badge.fill"
    }

    private func focusCountdownText(_ seconds: TimeInterval) -> String {
        let totalSeconds = max(Int(seconds.rounded()), 0)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let remainingSeconds = totalSeconds % 60

        if hours > 0 {
            return "\(hours):\(String(format: "%02d", minutes)):\(String(format: "%02d", remainingSeconds))"
        }
        return "\(minutes):\(String(format: "%02d", remainingSeconds))"
    }

    private func focusDurationText(_ seconds: TimeInterval) -> String {
        let totalSeconds = max(Int(seconds.rounded()), 0)
        let minutes = totalSeconds / 60
        if minutes >= 60 {
            return "\(minutes / 60)h\(minutes % 60)m"
        }
        return "\(minutes)m"
    }

    private func emptyExpandedRow() -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(capsuleTextColor)
            Text(t("暂无待办，今天很清爽", "No tasks. All clear."))
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
                .foregroundStyle(capsuleTextColor)
            Spacer()
        }
        .padding(.horizontal, 9)
        .frame(height: 30)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.07), in: Capsule())
    }

    @ViewBuilder
    private var expandedActions: some View {
        VStack(spacing: 8) {
            IslandActionButton(
                systemName: "plus",
                foregroundColor: capsuleTextColor,
                help: t("快速新增任务", "Quick add task")
            ) {
                onQuickAdd()
            }

            IslandActionButton(
                systemName: isPinned ? "pin.fill" : "pin",
                isActive: isPinned,
                foregroundColor: capsuleTextColor,
                help: isPinned ? t("取消固定展开", "Unpin expanded island") : t("固定展开", "Pin expanded island")
            ) {
                onPinToggle()
            }
        }
        .frame(width: 34)
        .frame(maxHeight: .infinity, alignment: .center)
    }

    private func t(_ chinese: String, _ english: String) -> String {
        settings.localized(chinese, english)
    }
}

private struct IslandGlassShape: Shape {
    var isExpanded: Bool

    func path(in rect: CGRect) -> Path {
        if isExpanded {
            let radius = min(28, rect.height / 2)
            return RoundedRectangle(cornerRadius: radius, style: .continuous)
                .path(in: rect)
        }

        return RoundedRectangle(cornerRadius: rect.height / 2, style: .circular)
            .path(in: rect)
    }
}

private struct IslandActionButton: View {
    let systemName: String
    var isActive = false
    let foregroundColor: Color
    let help: String
    let action: () -> Void

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(foregroundColor.opacity(isActive ? 1 : 0.84))
            .frame(width: 29, height: 29)
            .background(.ultraThinMaterial, in: Circle())
            .background(isActive ? foregroundColor.opacity(0.16) : Color.white.opacity(0.035), in: Circle())
            .overlay {
                Circle()
                    .stroke(isActive ? foregroundColor.opacity(0.46) : .white.opacity(0.42), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.08), radius: 5, x: 0, y: 3)
            .contentShape(Circle())
            .onTapGesture(perform: action)
            .help(help)
    }
}

private struct IslandTaskActionButton: View {
    let systemName: String
    let foregroundColor: Color
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(taskActionTint)
                .frame(width: 27, height: 27)
                .background(.ultraThinMaterial, in: Circle())
                .background(Color.white.opacity(0.030), in: Circle())
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.36), lineWidth: 1)
                }
                .contentShape(Circle())
            }
        .buttonStyle(.plain)
        .help(help)
    }

    private var taskActionTint: Color {
        if systemName == "checkmark" {
            return Color(red: 0.02, green: 0.52, blue: 0.30)
        }
        if systemName == "trash" {
            return foregroundColor.opacity(0.58)
        }
        return foregroundColor.opacity(0.86)
    }
}

private struct AttentionActionButton: View {
    let systemName: String
    let foregroundColor: Color
    let help: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 10.5, weight: .bold))
            .foregroundStyle(foregroundColor.opacity(0.90))
            .frame(width: 24, height: 24)
            .background(.ultraThinMaterial, in: Circle())
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.38), lineWidth: 1)
            }
            .contentShape(Circle())
            .help(help)
    }
}
