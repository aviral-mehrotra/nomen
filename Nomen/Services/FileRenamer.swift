import Foundation
import os

enum FileRenamerError: Error, LocalizedError {
    case empty
    case sourceMissing
    case tooManyCollisions
    case ioFailed(Error)

    var errorDescription: String? {
        switch self {
        case .empty: return "Filename was empty after sanitization."
        case .sourceMissing: return "Source file no longer exists."
        case .tooManyCollisions: return "Too many filename collisions."
        case .ioFailed(let err): return "I/O failed: \(err.localizedDescription)"
        }
    }
}

final class FileRenamer: Sendable {
    private let log = Logger(subsystem: "com.aviralmehrotra.Nomen", category: "Renamer")
    private let queue = DispatchQueue(label: "com.aviralmehrotra.Nomen.rename", qos: .userInitiated)

    func rename(source: URL, to newName: String) async throws -> URL {
        let sanitized = FilenameValidator.sanitize(newName)
        guard !sanitized.isEmpty else { throw FileRenamerError.empty }

        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    let result = try self.performRename(source: source, sanitizedName: sanitized)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func performRename(source: URL, sanitizedName: String) throws -> URL {
        let fm = FileManager.default
        guard fm.fileExists(atPath: source.path) else {
            throw FileRenamerError.sourceMissing
        }

        let ext = source.pathExtension
        let dir = source.deletingLastPathComponent()
        let maxAttempts = 999

        for attempt in 0...maxAttempts {
            let candidateName = candidateFilename(base: sanitizedName, ext: ext, attempt: attempt)
            let candidate = dir.appendingPathComponent(candidateName)
            if !fm.fileExists(atPath: candidate.path) {
                do {
                    try fm.moveItem(at: source, to: candidate)
                    log.notice("Renamed \(source.lastPathComponent, privacy: .public) -> \(candidateName, privacy: .public)")
                    return candidate
                } catch {
                    throw FileRenamerError.ioFailed(error)
                }
            }
        }
        throw FileRenamerError.tooManyCollisions
    }

    static func candidateFilename(base: String, ext: String, attempt: Int) -> String {
        let stem = attempt == 0 ? base : "\(base) (\(attempt + 1))"
        return ext.isEmpty ? stem : "\(stem).\(ext)"
    }

    private func candidateFilename(base: String, ext: String, attempt: Int) -> String {
        Self.candidateFilename(base: base, ext: ext, attempt: attempt)
    }
}
