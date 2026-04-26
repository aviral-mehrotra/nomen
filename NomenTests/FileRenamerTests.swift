import XCTest
@testable import Nomen

final class FileRenamerTests: XCTestCase {
    private var tempDir: URL!
    private var renamer: FileRenamer!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("NomenTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        renamer = FileRenamer()
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
        tempDir = nil
        renamer = nil
        try super.tearDownWithError()
    }

    private func makeFile(named name: String, contents: String = "x") throws -> URL {
        let url = tempDir.appendingPathComponent(name)
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func testBasicRenamePreservesExtension() async throws {
        let src = try makeFile(named: "Screenshot 2026-04-25.png")
        let dst = try await renamer.rename(source: src, to: "Login error")
        XCTAssertEqual(dst.lastPathComponent, "Login error.png")
        XCTAssertTrue(FileManager.default.fileExists(atPath: dst.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: src.path))
    }

    func testRenameStripsIllegalChars() async throws {
        let src = try makeFile(named: "Screenshot.png")
        let dst = try await renamer.rename(source: src, to: "before/after")
        XCTAssertEqual(dst.lastPathComponent, "beforeafter.png")
    }

    func testEmptyNameThrows() async throws {
        let src = try makeFile(named: "Screenshot.png")
        do {
            _ = try await renamer.rename(source: src, to: "   ")
            XCTFail("Expected empty error")
        } catch FileRenamerError.empty {
            // expected
        }
    }

    func testCollisionAppendsCounter() async throws {
        let src1 = try makeFile(named: "Screenshot 1.png", contents: "first")
        _ = try await renamer.rename(source: src1, to: "Login error")

        let src2 = try makeFile(named: "Screenshot 2.png", contents: "second")
        let dst2 = try await renamer.rename(source: src2, to: "Login error")
        XCTAssertEqual(dst2.lastPathComponent, "Login error (2).png")

        let src3 = try makeFile(named: "Screenshot 3.png", contents: "third")
        let dst3 = try await renamer.rename(source: src3, to: "Login error")
        XCTAssertEqual(dst3.lastPathComponent, "Login error (3).png")
    }

    func testSourceMissingThrows() async throws {
        let phantom = tempDir.appendingPathComponent("does-not-exist.png")
        do {
            _ = try await renamer.rename(source: phantom, to: "anything")
            XCTFail("Expected sourceMissing error")
        } catch FileRenamerError.sourceMissing {
            // expected
        }
    }

    func testPathWithSpaces() async throws {
        let src = try makeFile(named: "Screen Recording 2026.mov")
        let dst = try await renamer.rename(source: src, to: "demo clip")
        XCTAssertEqual(dst.lastPathComponent, "demo clip.mov")
    }

    func testUnicodeName() async throws {
        let src = try makeFile(named: "Screenshot.png")
        let dst = try await renamer.rename(source: src, to: "café 日本語")
        XCTAssertEqual(dst.lastPathComponent, "café 日本語.png")
    }

    func testCandidateFilenameHelper() {
        XCTAssertEqual(FileRenamer.candidateFilename(base: "foo", ext: "png", attempt: 0), "foo.png")
        XCTAssertEqual(FileRenamer.candidateFilename(base: "foo", ext: "png", attempt: 1), "foo (2).png")
        XCTAssertEqual(FileRenamer.candidateFilename(base: "foo", ext: "png", attempt: 2), "foo (3).png")
        XCTAssertEqual(FileRenamer.candidateFilename(base: "foo", ext: "", attempt: 0), "foo")
    }
}
