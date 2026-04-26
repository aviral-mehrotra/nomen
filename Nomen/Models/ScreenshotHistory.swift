import Foundation
import Observation
import os

struct HistoryEntry: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let originalName: String
    let newName: String
    let path: String
    let tags: [String]
    let timestamp: Date
}

@MainActor
@Observable
final class ScreenshotHistory {
    private let log = Logger(subsystem: "com.aviralmehrotra.Nomen", category: "History")
    private(set) var entries: [HistoryEntry] = []  // most recent first
    private let storeURL: URL
    private let cap = 200

    var onChange: (() -> Void)?

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Nomen", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        storeURL = dir.appendingPathComponent("history.json")
        load()
    }

    func record(originalName: String, newURL: URL, tags: [String]) {
        let entry = HistoryEntry(
            id: UUID(),
            originalName: originalName,
            newName: newURL.lastPathComponent,
            path: newURL.path,
            tags: tags,
            timestamp: Date()
        )
        entries.insert(entry, at: 0)
        if entries.count > cap {
            entries.removeLast(entries.count - cap)
        }
        save()
        onChange?()
    }

    private func load() {
        guard let data = try? Data(contentsOf: storeURL),
              let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data) else { return }
        entries = decoded
        log.notice("Loaded \(self.entries.count) history entries")
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(entries)
            try data.write(to: storeURL, options: .atomic)
        } catch {
            log.error("History save failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
