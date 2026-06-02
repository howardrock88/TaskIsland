import AppKit
import QuartzCore
import SwiftUI
import TaskIslandCore

@MainActor
final class IslandPanelController {
    private let panel: IslandPanel
    private let store: TaskStore
    private let settings: AppSettings
    private let viewState = IslandViewState()
    private var hostingView: NSView?
    private var isExpanded = false
    private var isPinned = false
    private var isDragging = false
    private var dragStartFrame: NSRect?
    private var dragStartMouseLocation: NSPoint?
    private var collapseTask: Task<Void, Never>?
    private var frameAnimationGeneration = 0
    private var contentSwitchTask: Task<Void, Never>?
    private var reminderAlertTask: Task<Void, Never>?
    private var eventMonitor: Any?
    private var globalMouseUpMonitor: Any?

    private let collapsedSize = NSSize(width: 172, height: 30)
    private let attentionSize = NSSize(width: 340, height: 52)
    private let animationDuration = 0.45
    private let contentFadeDuration = 0.12
    private let reminderAlertDuration: TimeInterval = 18

    private var expandedSize: NSSize {
        let visibleRows = max(1, min(3, store.incompleteCount))
        let height = max(92, visibleRows * 35 + 17)
        return NSSize(width: 440, height: CGFloat(height))
    }

    var onOpenTasks: () -> Void = {}
    var onQuickAdd: () -> Void = {}

    var screenFrame: NSRect {
        panel.frame
    }

    init(store: TaskStore, settings: AppSettings) {
        self.store = store
        self.settings = settings
        panel = IslandPanel(
            contentRect: NSRect(origin: .zero, size: collapsedSize)
        )

        let hostingView = NSHostingView(
            rootView: CapsuleIslandView(
                    viewState: viewState,
                    onOpenTasks: { [weak self] in
                        self?.onOpenTasks()
                    },
                    onQuickAdd: { [weak self] in
                        self?.onQuickAdd()
                    },
                    onPinToggle: { [weak self] in
                        self?.togglePinned()
                    },
                    onHoverChanged: { [weak self] isHovered in
                        self?.handleHoverChanged(isHovered)
                    }
                )
                .environmentObject(store)
                .environmentObject(settings)
        )
        hostingView.frame = NSRect(origin: .zero, size: collapsedSize)
        hostingView.autoresizingMask = [.width, .height]
        configureHostingLayer(for: collapsedSize)
        if #available(macOS 13.0, *) {
            hostingView.sizingOptions = []
        }
        self.hostingView = hostingView
        panel.contentView = hostingView
        installEventMonitor()
    }

    func setVisible(_ isVisible: Bool) {
        if isVisible {
            refreshLayout()
            panel.orderFrontRegardless()
        } else {
            collapseTask?.cancel()
            cancelPanelAnimation()
            contentSwitchTask?.cancel()
            viewState.isResizing = false
            panel.orderOut(nil)
        }
    }

    func refreshLayout(animated: Bool = false) {
        clearStaleReminderAlertIfNeeded()
        updateAttentionState()
        positionPanel(animated: animated)
        if settings.showCapsule {
            panel.orderFrontRegardless()
        }
    }

    func showReminderAlert(taskID: UUID) {
        guard store.incompleteTasks.contains(where: { $0.id == taskID }) else { return }

        reminderAlertTask?.cancel()
        viewState.reminderTaskID = taskID
        viewState.attentionStartedAt = Date()
        updateAttentionState()

        if !isPinned && !isDragging {
            setExpanded(false)
        }
        positionPanel(animated: true)
        panel.orderFrontRegardless()

        reminderAlertTask = Task { @MainActor [weak self] in
            let delay = self?.reminderAlertDuration ?? 18
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard let self, !Task.isCancelled else { return }
            if self.viewState.reminderTaskID == taskID {
                self.viewState.reminderTaskID = nil
                self.updateAttentionState()
                if !self.isExpanded && !self.isPinned {
                    self.positionPanel(animated: true)
                }
            }
        }
    }

    private func handleHoverChanged(_ hovered: Bool) {
        if hovered {
            collapseTask?.cancel()
            guard !isDragging else { return }
            setExpanded(true)
        } else {
            guard !isPinned else { return }
            scheduleCollapseIfNeeded()
        }
    }

    private func setExpanded(_ expanded: Bool) {
        guard expanded || !isPinned else { return }
        guard isExpanded != expanded else { return }
        contentSwitchTask?.cancel()
        isExpanded = expanded

        if expanded {
            withAnimation(.easeOut(duration: contentFadeDuration)) {
                viewState.showsExpandedContent = false
            }
            viewState.isResizing = true
            withAnimation(.easeInOut(duration: 0.18)) {
                viewState.isExpanded = true
            }
            positionPanel(animated: true) { [weak self] in
                guard let self, self.isExpanded else { return }
                withAnimation(.easeOut(duration: 0.16)) {
                    self.viewState.isResizing = false
                    self.viewState.showsExpandedContent = true
                }
            }
        } else {
            withAnimation(.easeOut(duration: contentFadeDuration)) {
                viewState.showsExpandedContent = false
            }

            contentSwitchTask = Task { @MainActor [weak self] in
                let delay = self?.contentFadeDuration ?? 0.12
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard let self, !Task.isCancelled, !self.isExpanded else { return }
                self.viewState.isResizing = true
                withAnimation(.easeInOut(duration: 0.18)) {
                    self.viewState.isExpanded = false
                }
                self.positionPanel(animated: true) { [weak self] in
                    guard let self, !self.isExpanded else { return }
                    withAnimation(.easeOut(duration: 0.12)) {
                        self.viewState.isResizing = false
                    }
                }
            }
            return
        }
    }

    private func togglePinned() {
        isPinned.toggle()
        collapseTask?.cancel()

        withAnimation(.easeInOut(duration: 0.18)) {
            viewState.isPinned = isPinned
        }

        if isPinned {
            setExpanded(true)
        } else if !isMouseInsidePanel(margin: 10) {
            scheduleCollapseIfNeeded()
        }
    }

    private func scheduleCollapseIfNeeded() {
        guard !isPinned else { return }
        collapseTask?.cancel()
        collapseTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 520_000_000)
            guard let self, !self.isDragging, !self.isPinned else { return }
            guard !self.isMouseInsidePanel(margin: 10) else { return }
            self.setExpanded(false)
        }
    }

    private func finishDragging() {
        isDragging = false
        dragStartFrame = nil
        dragStartMouseLocation = nil

        let frame = panel.frame
        settings.hasCapsuleCustomPosition = true
        settings.capsuleAnchorX = frame.midX
        settings.capsuleTopY = frame.maxY

        if !isPinned && !isMouseInsidePanel(margin: 10) {
            scheduleCollapseIfNeeded()
        }
    }

    private func positionPanel(animated: Bool, completion: (@MainActor @Sendable () -> Void)? = nil) {
        guard let placement = placementContext() else { return }

        updateAttentionState()
        let size = targetSize
        let frame = targetFrame(
            for: size,
            in: placement.screen.visibleFrame,
            useCustomPosition: placement.useCustomPosition
        )

        if animated {
            animatePanel(to: frame, contentSize: size, completion: completion)
        } else {
            cancelPanelAnimation()
            hostingView?.frame = NSRect(origin: .zero, size: size)
            panel.contentView?.setFrameSize(size)
            configureHostingLayer(for: size)
            panel.setFrame(frame, display: true)
            completion?()
        }
    }

    private func animatePanel(
        to targetFrame: NSRect,
        contentSize: NSSize,
        completion: (@MainActor @Sendable () -> Void)? = nil
    ) {
        cancelPanelAnimation()

        let targetFrame = pixelAlignedFrame(targetFrame)
        let startFrame = panel.frame
        guard pixelAlignedFrame(startFrame) != targetFrame else {
            hostingView?.frame = NSRect(origin: .zero, size: contentSize)
            panel.contentView?.setFrameSize(contentSize)
            configureHostingLayer(for: contentSize)
            completion?()
            return
        }

        frameAnimationGeneration += 1
        let generation = frameAnimationGeneration
        configureHostingLayer(for: startFrame.size)
        animateHostingCornerRadius(to: cornerRadius(for: contentSize))

        NSAnimationContext.runAnimationGroup { context in
            context.duration = animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            context.allowsImplicitAnimation = true
            panel.animator().setFrame(targetFrame, display: true)
        } completionHandler: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self,
                      generation == self.frameAnimationGeneration else {
                    return
                }
                self.panel.setFrame(targetFrame, display: true)
                self.hostingView?.frame = NSRect(origin: .zero, size: contentSize)
                self.panel.contentView?.setFrameSize(contentSize)
                self.configureHostingLayer(for: contentSize)
                completion?()
            }
        }
    }

    private func cancelPanelAnimation() {
        frameAnimationGeneration += 1
        hostingView?.layer?.removeAnimation(forKey: "islandCornerRadius")
    }

    private func configureHostingLayer(for size: NSSize) {
        guard let hostingView else { return }
        hostingView.wantsLayer = true
        guard let layer = hostingView.layer else { return }
        layer.backgroundColor = NSColor.clear.cgColor
        layer.isOpaque = false
        layer.masksToBounds = true
        setHostingCornerRadius(cornerRadius(for: size), on: layer)

        if #available(macOS 10.15, *) {
            layer.cornerCurve = .continuous
        }
    }

    private func cornerRadius(for size: NSSize) -> CGFloat {
        if size.width <= attentionSize.width + 1 && size.height <= attentionSize.height + 1 {
            return size.height / 2
        }
        return min(28, size.height / 2)
    }

    private var targetSize: NSSize {
        if isExpanded {
            return expandedSize
        }
        if hasAttentionContent {
            return attentionSize
        }
        return collapsedSize
    }

    private var hasAttentionContent: Bool {
        store.activeFocusTask != nil || activeReminderTask != nil
    }

    private var activeReminderTask: TaskItem? {
        guard let reminderTaskID = viewState.reminderTaskID else { return nil }
        return store.incompleteTasks.first { $0.id == reminderTaskID }
    }

    private func updateAttentionState() {
        clearStaleReminderAlertIfNeeded()
        viewState.usesAttentionSize = hasAttentionContent && !isExpanded
    }

    private func clearStaleReminderAlertIfNeeded() {
        guard let reminderTaskID = viewState.reminderTaskID else { return }
        guard store.incompleteTasks.contains(where: { $0.id == reminderTaskID }) else {
            viewState.reminderTaskID = nil
            reminderAlertTask?.cancel()
            reminderAlertTask = nil
            return
        }
    }

    private func setHostingCornerRadius(_ radius: CGFloat, on layer: CALayer) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.cornerRadius = radius
        CATransaction.commit()
    }

    private func animateHostingCornerRadius(to radius: CGFloat) {
        guard let layer = hostingView?.layer else { return }
        let currentRadius = layer.presentation()?.cornerRadius ?? layer.cornerRadius
        setHostingCornerRadius(radius, on: layer)

        let animation = CABasicAnimation(keyPath: "cornerRadius")
        animation.fromValue = currentRadius
        animation.toValue = radius
        animation.duration = animationDuration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(animation, forKey: "islandCornerRadius")
    }

    private func pixelAlignedFrame(_ frame: NSRect) -> NSRect {
        let scale = panel.screen?.backingScaleFactor
            ?? NSScreen.main?.backingScaleFactor
            ?? 2

        func align(_ value: CGFloat) -> CGFloat {
            (value * scale).rounded() / scale
        }

        return NSRect(
            x: align(frame.minX),
            y: align(frame.minY),
            width: align(frame.width),
            height: align(frame.height)
        )
    }

    private func targetFrame(
        for size: NSSize,
        in visibleFrame: NSRect,
        useCustomPosition: Bool
    ) -> NSRect {
        let anchorX: CGFloat
        let topY: CGFloat

        if useCustomPosition {
            anchorX = settings.capsuleAnchorX == 0 ? visibleFrame.midX : CGFloat(settings.capsuleAnchorX)
            topY = settings.capsuleTopY == 0 ? visibleFrame.maxY : CGFloat(settings.capsuleTopY)
        } else {
            anchorX = visibleFrame.midX
            topY = visibleFrame.maxY - CGFloat(settings.capsuleYOffset)
        }

        let proposedFrame = NSRect(
            x: anchorX - size.width / 2,
            y: topY - size.height,
            width: size.width,
            height: size.height
        )
        return clampedFrame(proposedFrame, in: visibleFrame)
    }

    private func placementContext() -> (screen: NSScreen, useCustomPosition: Bool)? {
        if settings.hasCapsuleCustomPosition {
            let savedPoint = NSPoint(
                x: CGFloat(settings.capsuleAnchorX),
                y: CGFloat(settings.capsuleTopY) - 1
            )
            if let screen = NSScreen.screens.first(where: { screen in
                screen.visibleFrame.insetBy(dx: -80, dy: -80).contains(savedPoint)
            }) {
                return (screen, true)
            }
            settings.hasCapsuleCustomPosition = false
        }

        let primaryScreen = NSScreen.screens.first { screen in
            screen.frame.origin == .zero
        }
        guard let screen = primaryScreen ?? NSScreen.main ?? NSScreen.screens.first else {
            return nil
        }
        return (screen, false)
    }

    private func clampedFrame(_ frame: NSRect) -> NSRect {
        let screen = NSScreen.screens.first { $0.visibleFrame.intersects(frame) }
            ?? NSScreen.main
            ?? NSScreen.screens.first
        return clampedFrame(frame, in: screen?.visibleFrame ?? frame)
    }

    private func clampedFrame(_ frame: NSRect, in visibleFrame: NSRect) -> NSRect {
        let x = min(max(frame.minX, visibleFrame.minX), visibleFrame.maxX - frame.width)
        let y = min(max(frame.minY, visibleFrame.minY), visibleFrame.maxY - frame.height)
        return NSRect(x: x, y: y, width: frame.width, height: frame.height)
    }

    private func isMouseInsidePanel(margin: CGFloat) -> Bool {
        panel.frame.insetBy(dx: -margin, dy: -margin).contains(NSEvent.mouseLocation)
    }

    private func installEventMonitor() {
        panel.eventHandler = { [weak self] event in
            self?.handleMouseEvent(event) ?? false
        }
        globalMouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleGlobalMouseUp()
            }
        }
    }

    private func handleMouseEvent(_ event: NSEvent) -> Bool {
        switch event.type {
        case .leftMouseDown:
            collapseTask?.cancel()
            cancelPanelAnimation()
            dragStartFrame = panel.frame
            dragStartMouseLocation = NSEvent.mouseLocation
            isDragging = false
            return false

        case .leftMouseDragged:
            guard let dragStartFrame,
                  let dragStartMouseLocation else {
                return false
            }

            let mouseLocation = NSEvent.mouseLocation
            let deltaX = mouseLocation.x - dragStartMouseLocation.x
            let deltaY = mouseLocation.y - dragStartMouseLocation.y
            guard abs(deltaX) > 1 || abs(deltaY) > 1 else { return true }

            isDragging = true
            let proposedFrame = NSRect(
                x: dragStartFrame.minX + deltaX,
                y: dragStartFrame.minY + deltaY,
                width: dragStartFrame.width,
                height: dragStartFrame.height
            )
            panel.setFrame(clampedFrame(proposedFrame), display: true)
            return true

        case .leftMouseUp:
            if !isDragging, handleIslandClick(at: event.locationInWindow) {
                dragStartFrame = nil
                dragStartMouseLocation = nil
                return true
            }

            if isDragging {
                finishDragging()
                return true
            }
            dragStartFrame = nil
            dragStartMouseLocation = nil
            return false

        default:
            return false
        }
    }

    private func handleGlobalMouseUp() {
        guard !isDragging else { return }
        let mouseLocation = NSEvent.mouseLocation
        guard panel.frame.insetBy(dx: -2, dy: -2).contains(mouseLocation) else { return }
        let localPoint = NSPoint(
            x: mouseLocation.x - panel.frame.minX,
            y: mouseLocation.y - panel.frame.minY
        )
        _ = handleIslandClick(at: localPoint)
    }

    private func handleIslandClick(at point: NSPoint) -> Bool {
        guard isExpanded else {
            onOpenTasks()
            return true
        }

        let topLeftPoint = CGPoint(x: point.x, y: panel.frame.height - point.y)
        if handleExpandedTopAction(atTopLeftPoint: topLeftPoint) {
            return true
        }

        if handleExpandedTaskAction(atTopLeftPoint: topLeftPoint) {
            return true
        }

        onOpenTasks()
        return true
    }

    private func handleExpandedTopAction(atTopLeftPoint point: CGPoint) -> Bool {
        let frame = expandedToolbarFrame(panelHeight: panel.frame.height)
        guard frame.contains(point) else { return false }

        let localY = point.y - frame.minY
        if localY <= 28 {
            onQuickAdd()
        } else if localY >= 36 {
            togglePinned()
        }
        return true
    }

    private func handleExpandedTaskAction(atTopLeftPoint point: CGPoint) -> Bool {
        let tasks = store.previewTasks(limit: 3)
        guard !tasks.isEmpty else { return false }

        let rowHeight: CGFloat = 30
        let rowSpacing: CGFloat = 5
        let contentY: CGFloat = 11
        let contentHeight = max(panel.frame.height - 22, rowHeight)
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
            x: 302,
            y: rowStartY + CGFloat(rowIndex) * rowStride,
            width: 62,
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
}

final class IslandPanel: NSPanel {
    var eventHandler: ((NSEvent) -> Bool)?

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        level = .statusBar
        collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    override func sendEvent(_ event: NSEvent) {
        if eventHandler?(event) == true {
            return
        }
        super.sendEvent(event)
    }
}
