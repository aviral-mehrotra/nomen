import Foundation

/// Reads (read-only) the user's `com.apple.screencapture` preferences. Works inside the
/// app sandbox via `CFPreferencesCopyAppValue`, which is allowed for cross-domain reads of
/// user-level preferences.
enum ScreencaptureDefaults {
    private static func domain() -> CFString { "com.apple.screencapture" as CFString }

    /// User's configured save location for screenshots. Returns nil if unset.
    static var location: URL? {
        guard let raw = CFPreferencesCopyAppValue("location" as CFString, domain()) as? String else {
            return nil
        }
        return URL(fileURLWithPath: (raw as NSString).expandingTildeInPath, isDirectory: true)
    }

    /// True when macOS shows the floating thumbnail in the corner after a capture.
    /// This delays the file write to disk; surfacing the toggle helps users tune latency.
    static var showsFloatingThumbnail: Bool {
        let value = CFPreferencesCopyAppValue("show-thumbnail" as CFString, domain()) as? Bool
        return value ?? true
    }
}
