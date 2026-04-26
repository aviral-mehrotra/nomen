import Combine
import CoreServices
import Foundation
import os

final class ScreenshotWatcher {
    private let log = Logger(subsystem: "com.aviralmehrotra.Nomen", category: "Watcher")
    private let subject = PassthroughSubject<Screenshot, Never>()
    private var stream: FSEventStreamRef?
    private let launchedAt: Date
    private let queue = DispatchQueue(label: "com.aviralmehrotra.Nomen.fsevents", qos: .userInitiated)
    private var seenInodes = Set<UInt64>()

    var publisher: AnyPublisher<Screenshot, Never> {
        subject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    init() {
        launchedAt = Date().addingTimeInterval(-5)
    }

    deinit {
        stop()
    }

    func start(watching url: URL) {
        stop()
        let path = url.path

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let callback: FSEventStreamCallback = { _, info, numEvents, eventPaths, eventFlags, _ in
            guard let info else { return }
            let paths = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] ?? []
            var flagArray: [FSEventStreamEventFlags] = []
            flagArray.reserveCapacity(numEvents)
            for i in 0..<numEvents {
                flagArray.append(eventFlags[i])
            }
            let watcher = Unmanaged<ScreenshotWatcher>.fromOpaque(info).takeUnretainedValue()
            watcher.handle(paths: paths, flags: flagArray)
        }

        let flags = UInt32(
            kFSEventStreamCreateFlagFileEvents |
            kFSEventStreamCreateFlagUseCFTypes |
            kFSEventStreamCreateFlagNoDefer
        )

        guard let newStream = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &context,
            [path] as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.1,
            flags
        ) else {
            log.error("FSEventStreamCreate failed for \(path, privacy: .public)")
            return
        }

        FSEventStreamSetDispatchQueue(newStream, queue)
        FSEventStreamStart(newStream)
        stream = newStream
        log.notice("Watching \(path, privacy: .public)")
    }

    func stop() {
        guard let s = stream else { return }
        FSEventStreamStop(s)
        FSEventStreamInvalidate(s)
        FSEventStreamRelease(s)
        stream = nil
    }

    private func handle(paths: [String], flags: [FSEventStreamEventFlags]) {
        let createdMask = UInt32(kFSEventStreamEventFlagItemCreated)
        let renamedMask = UInt32(kFSEventStreamEventFlagItemRenamed)
        let fileMask = UInt32(kFSEventStreamEventFlagItemIsFile)

        for (path, flag) in zip(paths, flags) {
            guard (flag & fileMask) != 0 else { continue }
            guard (flag & createdMask) != 0 || (flag & renamedMask) != 0 else { continue }

            let url = URL(fileURLWithPath: path)
            guard isScreenshotFilename(url.lastPathComponent) else { continue }
            guard FileManager.default.fileExists(atPath: path) else { continue }
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
                  let createdAt = attrs[.creationDate] as? Date,
                  let inode = attrs[.systemFileNumber] as? UInt64 else { continue }
            guard createdAt >= launchedAt else { continue }
            guard seenInodes.insert(inode).inserted else { continue }

            let screenshot = Screenshot(url: url, createdAt: createdAt)
            log.notice("Detected: \(url.lastPathComponent, privacy: .public)")
            subject.send(screenshot)
        }
    }

    private static let screenshotPrefixes: [String] = [
        "Screenshot",
        "Screen Recording",
        "Snímek obrazovky",
        "Skærmbillede",
        "Schermafbeelding",
        "Captura de pantalla",
        "Capture d’écran",
        "Bildschirmfoto",
        "스크린샷",
        "スクリーンショット",
        "Schermata",
        "Captura de tela",
        "Снимок экрана",
        "屏幕快照",
        "螢幕快照"
    ]

    private func isScreenshotFilename(_ filename: String) -> Bool {
        Self.screenshotPrefixes.contains { filename.hasPrefix($0) }
    }
}
