import Combine
import Foundation
import os

@MainActor
final class AppServices {
    static let shared = AppServices()

    let log = Logger(subsystem: "com.aviralmehrotra.Nomen", category: "AppServices")
    let watchFolderAccess = WatchFolderAccess()
    let watcher = ScreenshotWatcher()
    let history = ScreenshotHistory()
    let panelController = PanelController()
    private var watcherSubscription: AnyCancellable?
    private var paused = false

    var isPaused: Bool { paused }
    var watchFolderURL: URL? { watchFolderAccess.resolvedURL }

    private init() {}

    /// Subscribes the panel controller to detected screenshots. Idempotent.
    func wireWatcherToPanel() {
        guard watcherSubscription == nil else { return }
        watcherSubscription = watcher.publisher.sink { [weak self] screenshot in
            guard let self, !self.paused else { return }
            self.panelController.enqueue(screenshot)
        }
    }

    func startWatching(at url: URL) {
        watcher.start(watching: url)
    }

    func setPaused(_ paused: Bool) {
        self.paused = paused
        log.notice("Pause set to \(paused)")
    }

    func shutdown() {
        watcher.stop()
        watchFolderAccess.stopAccessing()
    }
}
