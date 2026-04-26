import Foundation
import Observation
import os

@MainActor
@Observable
final class TagStore {
    private let log = Logger(subsystem: "com.aviralmehrotra.Nomen", category: "TagStore")
    private(set) var allTags: Set<String> = []
    private let storeURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Nomen", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        storeURL = dir.appendingPathComponent("tags.json")
        load()
    }

    func record(_ tags: [String]) {
        let before = allTags.count
        for tag in tags where !tag.isEmpty {
            allTags.insert(tag)
        }
        if allTags.count != before {
            save()
        }
    }

    func suggestions(matching prefix: String, limit: Int = 8) -> [String] {
        guard !prefix.isEmpty else { return Array(allTags.sorted().prefix(limit)) }
        let lower = prefix.lowercased()
        return allTags
            .filter { $0.lowercased().hasPrefix(lower) }
            .sorted()
            .prefix(limit)
            .map { $0 }
    }

    private func load() {
        guard let data = try? Data(contentsOf: storeURL),
              let decoded = try? JSONDecoder().decode([String].self, from: data) else { return }
        allTags = Set(decoded)
        log.notice("Loaded \(self.allTags.count) tags")
    }

    private func save() {
        let array = allTags.sorted()
        do {
            let data = try JSONEncoder().encode(array)
            try data.write(to: storeURL, options: .atomic)
        } catch {
            log.error("Failed to save tags: \(error.localizedDescription, privacy: .public)")
        }
    }
}
