import AppKit
import Foundation
import os

@MainActor
final class WatchFolderAccess {
    private let log = Logger(subsystem: "com.aviralmehrotra.Nomen", category: "WatchFolderAccess")
    private let defaultsKey = "watchFolderBookmark"
    private(set) var resolvedURL: URL?

    func resolveStoredBookmark() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else {
            log.notice("No watch folder bookmark stored yet")
            return nil
        }
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: data,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            if isStale {
                log.notice("Stored bookmark is stale; clearing")
                UserDefaults.standard.removeObject(forKey: defaultsKey)
                return nil
            }
            guard url.startAccessingSecurityScopedResource() else {
                log.error("Failed to start security-scoped access for stored bookmark")
                return nil
            }
            resolvedURL = url
            log.notice("Resumed access to watch folder: \(url.path, privacy: .public)")
            return url
        } catch {
            log.error("Failed to resolve bookmark: \(error.localizedDescription, privacy: .public)")
            UserDefaults.standard.removeObject(forKey: defaultsKey)
            return nil
        }
    }

    func promptForFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.title = "Choose Screenshot Folder"
        panel.message = "Confirm your screenshot folder. We've pre-selected the location macOS is currently saving to — just click 'Watch This Folder' to grant access."
        panel.prompt = "Watch This Folder"
        panel.directoryURL = ScreencaptureDefaults.location
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Desktop")

        NSApp.activate(ignoringOtherApps: true)
        let response = panel.runModal()
        guard response == .OK, let url = panel.url else {
            log.notice("User cancelled folder selection")
            return nil
        }
        return saveBookmark(for: url) ? url : nil
    }

    private func saveBookmark(for url: URL) -> Bool {
        stopAccessing()
        do {
            let data = try url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(data, forKey: defaultsKey)
            guard url.startAccessingSecurityScopedResource() else {
                log.error("Failed to start security-scoped access on new bookmark")
                return false
            }
            resolvedURL = url
            log.notice("Saved bookmark for: \(url.path, privacy: .public)")
            return true
        } catch {
            log.error("Failed to create bookmark: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func stopAccessing() {
        if let url = resolvedURL {
            url.stopAccessingSecurityScopedResource()
            resolvedURL = nil
        }
    }
}
