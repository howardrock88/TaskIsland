import AppKit
import SwiftUI
import TaskIslandCore

@MainActor
final class TaskPanelState: ObservableObject {
    @Published var isPinned = false
}

@MainActor
final class TaskPanelController: NSObject, NSWindowDelegate {
    private let panel: TaskPanel
    private let panelState = TaskPanelState()
    private let panelSize = NSSize(width: 430, height: 590)
    private var panelDragStartFrame: NSRect?
    private var panelDragStartMouseLocation: NSPoint?
    var onClose: () -> Void = {}

    init(store: TaskStore, settings: AppSettings) {
        panel = TaskPanel(contentRect: NSRect(origin: .zero, size: panelSize))
        super.init()
        panel.delegate = self
        panel.onCancel = { [weak self] in
            self?.hide()
        }
        panel.contentView = DraggableHostingView(
            rootView: MenuBarWindowView(panelState: panelState, onDismiss: { [weak self] in
                self?.hide()
            }, onPinChanged: { [weak self] isPinned in
                self?.applyPinnedState(isPinned)
            }, onDragChanged: { [weak self] translation in
                self?.dragPanel(translation: translation)
            }, onDragEnded: { [weak self] in
                self?.finishDraggingPanel()
            })
                .environmentObject(store)
                .environmentObject(settings)
                .frame(width: panelSize.width, height: panelSize.height)
        )
    }

    func toggle(relativeTo button: NSStatusBarButton?) {
        if panel.isVisible {
            hide()
        } else {
            show(relativeTo: button)
        }
    }

    func show(relativeTo button: NSStatusBarButton?) {
        position(relativeTo: button)
        applyPinnedState(panelState.isPinned)
        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
    }

    func show(anchorFrame: NSRect?) {
        position(anchorFrame: anchorFrame)
        applyPinnedState(panelState.isPinned)
        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() {
        panelState.isPinned = false
        applyPinnedState(false)
        panel.orderOut(nil)
        onClose()
    }

    func windowDidResignKey(_ notification: Notification) {
        guard panel.isVisible else { return }
        guard !panelState.isPinned else { return }
        hide()
    }

    private func applyPinnedState(_ isPinned: Bool) {
        panel.hidesOnDeactivate = !isPinned
        panel.level = isPinned ? .statusBar : .floating
    }

    private func dragPanel(translation _: CGSize) {
        let currentMouseLocation = NSEvent.mouseLocation
        if panelDragStartFrame == nil {
            panelDragStartFrame = panel.frame
            panelDragStartMouseLocation = currentMouseLocation
        }
        guard let startFrame = panelDragStartFrame,
              let startMouseLocation = panelDragStartMouseLocation else { return }

        let proposedFrame = NSRect(
            x: startFrame.minX + currentMouseLocation.x - startMouseLocation.x,
            y: startFrame.minY + currentMouseLocation.y - startMouseLocation.y,
            width: startFrame.width,
            height: startFrame.height
        )
        panel.setFrameOrigin(clampedFrame(proposedFrame).origin)
    }

    private func finishDraggingPanel() {
        panelDragStartFrame = nil
        panelDragStartMouseLocation = nil
    }

    private func position(relativeTo button: NSStatusBarButton?) {
        let size = panelSize

        if let button, let window = button.window {
            let buttonRectInScreen = window.convertToScreen(button.convert(button.bounds, to: nil))
            let screen = window.screen ?? NSScreen.main ?? NSScreen.screens.first
            let visibleFrame = screen?.visibleFrame ?? .zero
            let maxX = visibleFrame.maxX - size.width - 8
            let x = min(max(buttonRectInScreen.midX - size.width / 2, visibleFrame.minX + 8), maxX)
            let y = buttonRectInScreen.minY - size.height - 8
            panel.setFrame(NSRect(x: x, y: y, width: size.width, height: size.height), display: true)
            return
        }

        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        position(anchorFrame: NSRect(
            x: screen.visibleFrame.midX,
            y: screen.visibleFrame.maxY - 64,
            width: 0,
            height: 0
        ))
    }

    private func position(anchorFrame: NSRect?) {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let size = panelSize
        let visibleFrame = screen.visibleFrame
        let anchor = anchorFrame ?? NSRect(
            x: visibleFrame.midX,
            y: visibleFrame.maxY - 64,
            width: 0,
            height: 0
        )
        let preferredX = anchor.midX - size.width / 2
        let maxX = visibleFrame.maxX - size.width - 10
        let x = min(max(preferredX, visibleFrame.minX + 10), maxX)
        let preferredY = anchor.minY - size.height - 12
        let minY = visibleFrame.minY + 12
        let y = max(preferredY, minY)
        panel.setFrame(
            NSRect(x: x, y: y, width: size.width, height: size.height),
            display: true
        )
    }

    private func clampedFrame(_ frame: NSRect) -> NSRect {
        let screen = NSScreen.screens.first { $0.visibleFrame.intersects(frame) }
            ?? NSScreen.main
            ?? NSScreen.screens.first
        guard let visibleFrame = screen?.visibleFrame else { return frame }

        let x = min(max(frame.minX, visibleFrame.minX + 8), visibleFrame.maxX - frame.width - 8)
        let y = min(max(frame.minY, visibleFrame.minY + 8), visibleFrame.maxY - frame.height - 8)
        return NSRect(x: x, y: y, width: frame.width, height: frame.height)
    }
}

final class TaskPanel: NSPanel {
    var onCancel: (() -> Void)?

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        hidesOnDeactivate = true
        isMovableByWindowBackground = false
        isReleasedWhenClosed = false
        level = .floating
        collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary
        ]
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }
}

final class DraggableHostingView<Content: View>: NSHostingView<Content> {
    override var mouseDownCanMoveWindow: Bool { false }
}
