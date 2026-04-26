import Foundation
import os

final class FinderTagger: Sendable {
    private let log = Logger(subsystem: "com.aviralmehrotra.Nomen", category: "Tagger")

    /// Reads existing Finder tags on `url`, unions with `tags`, and writes the result.
    func setTags(_ tags: [String], on url: URL) throws {
        let merged = Array(Set(readTags(of: url)).union(tags))
        try (url as NSURL).setResourceValue(merged, forKey: .tagNamesKey)
        log.notice("Wrote \(merged.count) tags to \(url.lastPathComponent, privacy: .public)")
    }

    func readTags(of url: URL) -> [String] {
        var value: AnyObject?
        do {
            try (url as NSURL).getResourceValue(&value, forKey: .tagNamesKey)
            return (value as? [String]) ?? []
        } catch {
            return []
        }
    }
}
