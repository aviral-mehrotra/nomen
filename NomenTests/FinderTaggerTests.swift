import XCTest
@testable import Nomen

final class FinderTaggerTests: XCTestCase {
    private var tempDir: URL!
    private var tagger: FinderTagger!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("NomenTaggerTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        tagger = FinderTagger()
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
        tempDir = nil
        tagger = nil
        try super.tearDownWithError()
    }

    private func makeFile(named name: String) throws -> URL {
        let url = tempDir.appendingPathComponent(name)
        try "x".write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func testWriteAndReadRoundTrip() throws {
        let url = try makeFile(named: "tagme.png")
        try tagger.setTags(["red", "todo"], on: url)
        let read = Set(tagger.readTags(of: url))
        XCTAssertEqual(read, Set(["red", "todo"]))
    }

    func testSecondCallMergesRatherThanReplaces() throws {
        let url = try makeFile(named: "tagme.png")
        try tagger.setTags(["alpha"], on: url)
        try tagger.setTags(["beta"], on: url)
        let read = Set(tagger.readTags(of: url))
        XCTAssertEqual(read, Set(["alpha", "beta"]))
    }

    func testEmptyTagsLeavesExistingAlone() throws {
        let url = try makeFile(named: "tagme.png")
        try tagger.setTags(["keep"], on: url)
        try tagger.setTags([], on: url)
        let read = Set(tagger.readTags(of: url))
        XCTAssertEqual(read, Set(["keep"]))
    }
}
