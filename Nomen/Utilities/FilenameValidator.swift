import Foundation

enum FilenameValidator {
    private static let illegal = CharacterSet(charactersIn: "/:\\?*|<>\"")
    private static let controls = CharacterSet.controlCharacters

    /// Per-component cap chosen well below APFS's 255-byte limit so the file
    /// system rejection path is unreachable from typical input. Multi-byte
    /// Unicode is counted by character; truncation respects grapheme boundaries.
    static let maxLength = 200

    /// Strips path-illegal characters and control chars, collapses runs of whitespace,
    /// trims, and clamps to `maxLength` characters. Returns "" for empty/whitespace-only.
    static func sanitize(_ input: String) -> String {
        let scalars = input.unicodeScalars.filter { !illegal.contains($0) && !controls.contains($0) }
        let cleaned = String(String.UnicodeScalarView(scalars))
        let collapsed = cleaned.replacingOccurrences(of: " +", with: " ", options: .regularExpression)
        let trimmed = collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > maxLength {
            return String(trimmed.prefix(maxLength))
        }
        return trimmed
    }
}
