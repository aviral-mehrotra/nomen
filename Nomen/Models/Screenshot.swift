import Foundation

struct Screenshot: Identifiable, Hashable, Sendable {
    let id: UUID
    let url: URL
    let createdAt: Date

    init(url: URL, createdAt: Date) {
        self.id = UUID()
        self.url = url
        self.createdAt = createdAt
    }

    var originalFilename: String { url.lastPathComponent }
    var pathExtension: String { url.pathExtension }
}
