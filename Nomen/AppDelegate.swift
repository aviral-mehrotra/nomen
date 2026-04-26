import AppKit
import os

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let log = Logger(subsystem: "com.aviralmehrotra.Nomen", category: "AppDelegate")
    private var menuBarController: MenuBarController?
    private let services = AppServices.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        log.notice("Nomen launched")
        let menuBar = MenuBarController()
        menuBar.onSummonTestPanel = { [weak self] in
            self?.services.panelController.summonTestPanel()
        }
        menuBar.onTogglePause = { [weak self] paused in
            self?.services.setPaused(paused)
        }
        menuBar.onOpenWatchFolder = { [weak self] in
            if let url = self?.services.watchFolderURL {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
        }
        menuBarController = menuBar

        // Initial population + reactive updates for the Recent submenu.
        menuBar.updateRecent(entries: services.history.entries)
        services.history.onChange = { [weak menuBar, weak services] in
            guard let menuBar, let services else { return }
            menuBar.updateRecent(entries: services.history.entries)
        }

        services.wireWatcherToPanel()
        startWatching()
    }

    func applicationWillTerminate(_ notification: Notification) {
        services.shutdown()
    }

    private func startWatching() {
        if let resolved = services.watchFolderAccess.resolveStoredBookmark() {
            services.startWatching(at: resolved)
            return
        }

        OnboardingWindowController.shared.show { [weak self] in
            // Folder grant + watcher start happen inside OnboardingView. If the user
            // closed the window without granting, fall back to logging idle.
            if self?.services.watchFolderURL == nil {
                self?.log.notice("Onboarding completed without folder; idle")
            }
        }
    }
}
