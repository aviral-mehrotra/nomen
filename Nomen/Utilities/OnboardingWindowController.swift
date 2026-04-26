import AppKit
import SwiftUI

@MainActor
final class OnboardingWindowController: NSObject {
    static let shared = OnboardingWindowController()

    private var window: NSWindow?

    private override init() {}

    func show(onFinished: @escaping () -> Void) {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = OnboardingView { [weak self] in
            self?.close()
            onFinished()
        }
        let hosting = NSHostingController(rootView: view)
        let w = NSWindow(contentViewController: hosting)
        w.title = "Welcome to Nomen"
        w.styleMask = [.titled, .closable]
        w.isReleasedWhenClosed = false
        window = w

        NSApp.activate(ignoringOtherApps: true)
        w.makeKeyAndOrderFront(nil)
        positionCenter(w)
    }

    private func positionCenter(_ window: NSWindow) {
        let mouse = NSEvent.mouseLocation
        let chosen = NSScreen.screens.first { NSPointInRect(mouse, $0.frame) }
            ?? NSScreen.main
            ?? NSScreen.screens.first
        guard let screen = chosen else { return }
        let visible = screen.visibleFrame
        let size = window.frame.size
        let x = visible.origin.x + (visible.width - size.width) / 2
        let y = visible.origin.y + (visible.height - size.height) / 2 + visible.height * 0.05
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    func close() {
        window?.close()
        window = nil
    }
}
