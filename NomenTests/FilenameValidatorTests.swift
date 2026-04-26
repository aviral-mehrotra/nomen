import XCTest
@testable import Nomen

final class FilenameValidatorTests: XCTestCase {
    func testStripsIllegalChars() {
        XCTAssertEqual(FilenameValidator.sanitize("a/b:c?*|<>\"d"), "abcd")
    }

    func testStripsControlChars() {
        XCTAssertEqual(FilenameValidator.sanitize("foo\nbar\ttbaz"), "foobartbaz")
    }

    func testCollapsesWhitespace() {
        XCTAssertEqual(FilenameValidator.sanitize("hello    world"), "hello world")
    }

    func testTrimsLeadingAndTrailingWhitespace() {
        XCTAssertEqual(FilenameValidator.sanitize("   hello   "), "hello")
    }

    func testEmptyInputReturnsEmpty() {
        XCTAssertEqual(FilenameValidator.sanitize(""), "")
    }

    func testWhitespaceOnlyReturnsEmpty() {
        XCTAssertEqual(FilenameValidator.sanitize("   \t  "), "")
    }

    func testUnicodePreserved() {
        XCTAssertEqual(FilenameValidator.sanitize("café résumé 日本語"), "café résumé 日本語")
    }

    func testIllegalOnlyReturnsEmpty() {
        XCTAssertEqual(FilenameValidator.sanitize("///:::"), "")
    }

    func testTruncatesOverlongInput() {
        let huge = String(repeating: "a", count: 500)
        let result = FilenameValidator.sanitize(huge)
        XCTAssertEqual(result.count, FilenameValidator.maxLength)
    }

    func testInputAtCapIsPreserved() {
        let exact = String(repeating: "x", count: FilenameValidator.maxLength)
        XCTAssertEqual(FilenameValidator.sanitize(exact), exact)
    }
}
