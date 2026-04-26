import AppKit
import Foundation
import Observation
import os

@MainActor
@Observable
final class RenamePromptViewModel {
    let screenshot: Screenshot
    var name: String = ""
    var tagsInput: String = ""
    var errorMessage: String?
    var didSave: Bool = false

    private let log = Logger(subsystem: "com.aviralmehrotra.Nomen", category: "PromptVM")
    private let renamer: FileRenamer
    private let tagger: FinderTagger
    private let tagStore: TagStore
    private let history: ScreenshotHistory
    private let onDismiss: () -> Void
    private var autoDismissTask: Task<Void, Never>?

    init(
        screenshot: Screenshot,
        renamer: FileRenamer,
        tagger: FinderTagger,
        tagStore: TagStore,
        history: ScreenshotHistory,
        onDismiss: @escaping () -> Void
    ) {
        self.screenshot = screenshot
        self.renamer = renamer
        self.tagger = tagger
        self.tagStore = tagStore
        self.history = history
        self.onDismiss = onDismiss
    }

    /// Per-tag character cap to keep absurd values out of the Finder tag store.
    static let maxTagLength = 64
    static let maxTagCount = 16

    var parsedTags: [String] {
        tagsInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { String($0.prefix(Self.maxTagLength)) }
            .prefix(Self.maxTagCount)
            .map { $0 }
    }

    private var defaultTags: [String] {
        let raw = UserDefaults.standard.string(forKey: "defaultTagsInput") ?? ""
        return raw.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var configuredAutoDismissSeconds: TimeInterval {
        let stored = UserDefaults.standard.integer(forKey: "autoDismissSeconds")
        return stored > 0 ? TimeInterval(stored) : 120
    }

    func save() {
        let typed = name
        let tagsToWrite = Array(Set(parsedTags).union(defaultTags))
        log.notice("Save invoked (tag count=\(tagsToWrite.count))")

        if FilenameValidator.sanitize(typed).isEmpty {
            log.notice("Empty name; skipping rename")
            if !tagsToWrite.isEmpty {
                writeTags(to: screenshot.url, tags: tagsToWrite)
            }
            dismiss()
            return
        }

        autoDismissTask?.cancel()
        Task {
            do {
                let newURL = try await renamer.rename(source: screenshot.url, to: typed)
                log.notice("Renamed to \(newURL.lastPathComponent, privacy: .public)")
                if !tagsToWrite.isEmpty {
                    writeTags(to: newURL, tags: tagsToWrite)
                }
                history.record(originalName: screenshot.originalFilename, newURL: newURL, tags: tagsToWrite)
                didSave = true
                try? await Task.sleep(for: .milliseconds(450))
                dismiss()
            } catch {
                log.error("Rename failed: \(error.localizedDescription, privacy: .public)")
                errorMessage = error.localizedDescription
            }
        }
    }

    func cancel() {
        log.notice("Cancel requested")
        dismiss()
    }

    func openInPreview() {
        log.notice("Open in Preview")
        NSWorkspace.shared.open(screenshot.url)
    }

    func startAutoDismissTimer(seconds: TimeInterval? = nil) {
        let effective = seconds ?? configuredAutoDismissSeconds
        autoDismissTask?.cancel()
        autoDismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(effective))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.log.notice("Auto-dismiss after \(Int(effective))s of inactivity")
                self?.dismiss()
            }
        }
    }

    private func writeTags(to url: URL, tags: [String]) {
        do {
            try tagger.setTags(tags, on: url)
            tagStore.record(tags)
        } catch {
            log.error("Tag write failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func dismiss() {
        autoDismissTask?.cancel()
        onDismiss()
    }
}
