import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSObject {
    static let shared = SettingsWindowController()

    private var window: NSWindow?

    private override init() {}

    func show() {
        if let window {
            positionCenter(window)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingController = NSHostingController(rootView: SettingsView())
        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = "Nomen Settings"
        newWindow.styleMask = [.titled, .closable]
        newWindow.isReleasedWhenClosed = false
        window = newWindow

        NSApp.activate(ignoringOtherApps: true)
        newWindow.makeKeyAndOrderFront(nil)
        positionCenter(newWindow)
    }

    /// Centers the window on the screen the user's cursor is currently on, with
    /// a small upward bias. NSWindow.center() picks the key window's screen,
    /// which is wrong on multi-monitor setups when the user is looking elsewhere.
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
}
