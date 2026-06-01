import AppKit
import SwiftUI
import TaskIslandCore

@MainActor
final class QuickAddPanelController: NSObject, NSWindowDelegate {
    private let store: TaskStore
    private let settings: AppSettings
    private let panel: QuickAddPanel
    private weak var previousApplication: NSRunningApplication?

    init(store: TaskStore, settings: AppSettings) {
        self.store = store
        self.settings = settings
        panel = QuickAddPanel(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 156)
        )
        super.init()
        panel.delegate = self
        panel.onCancel = { [weak self] in
            self?.hide()
        }
    }

    func show() {
        previousApplication = NSWorkspace.shared.frontmostApplication
        panel.contentView = NSHostingView(
            rootView: QuickAddView(
                onSubmit: { [weak self] title, priority in
                    self?.store.addTask(title: title, priority: priority)
                    self?.hide()
                },
                onCancel: { [weak self] in
                    self?.hide()
                }
            )
            .environmentObject(settings)
        )

        positionPanel()
        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
    }

    private func hide() {
        guard panel.isVisible else { return }
        panel.orderOut(nil)
        panel.contentView = nil
        previousApplication?.activate()
    }

    func windowDidResignKey(_ notification: Notification) {
        guard panel.isVisible else { return }
        hide()
    }

    private func positionPanel() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }

        let size = NSSize(width: 500, height: 156)
        let visibleFrame = screen.visibleFrame
        let origin = NSPoint(
            x: visibleFrame.midX - size.width / 2,
            y: visibleFrame.maxY - size.height - 120
        )

        panel.setFrame(NSRect(origin: origin, size: size), display: true)
    }
}

final class QuickAddPanel: NSPanel {
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
        hasShadow = true
        hidesOnDeactivate = true
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

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onCancel?()
            return
        }
        super.keyDown(with: event)
    }
}
