import XCTest
@testable import RecipeFinder

final class ExtensionsTests: XCTestCase {

    // MARK: - Array safe subscript

    func testSafeSubscript_validIndex_returnsElement() {
        let array = [10, 20, 30]
        XCTAssertEqual(array[safe: 0], 10)
        XCTAssertEqual(array[safe: 2], 30)
    }

    func testSafeSubscript_negativeIndex_returnsNil() {
        let array = [1, 2, 3]
        XCTAssertNil(array[safe: -1])
    }

    func testSafeSubscript_indexAtCount_returnsNil() {
        let array = [1, 2, 3]
        XCTAssertNil(array[safe: 3])
    }

    func testSafeSubscript_emptyArray_returnsNil() {
        let array: [Int] = []
        XCTAssertNil(array[safe: 0])
    }

    // MARK: - String.capitalizedFirst

    func testCapitalizedFirst_lowercaseInput_capitalizesFirstLetter() {
        XCTAssertEqual("hello".capitalizedFirst, "Hello")
    }

    func testCapitalizedFirst_alreadyCapitalized_unchanged() {
        XCTAssertEqual("Hello".capitalizedFirst, "Hello")
    }

    func testCapitalizedFirst_allCaps_onlyFirstPreserved() {
        XCTAssertEqual("HELLO".capitalizedFirst, "HELLO")
    }

    func testCapitalizedFirst_emptyString_returnsEmpty() {
        XCTAssertEqual("".capitalizedFirst, "")
    }

    func testCapitalizedFirst_singleChar_capitalized() {
        XCTAssertEqual("a".capitalizedFirst, "A")
    }

    func testCapitalizedFirst_doesNotLowercaseRestOfString() {
        XCTAssertEqual("hELLO".capitalizedFirst, "HELLO")
    }

    // MARK: - String.trimmed

    func testTrimmed_leadingAndTrailingSpaces_removed() {
        XCTAssertEqual("  hello  ".trimmed, "hello")
    }

    func testTrimmed_noWhitespace_unchanged() {
        XCTAssertEqual("hello".trimmed, "hello")
    }

    func testTrimmed_onlyWhitespace_isEmpty() {
        XCTAssertTrue("   ".trimmed.isEmpty)
    }

    func testTrimmed_newlines_removed() {
        XCTAssertEqual("\nhello\n".trimmed, "hello")
    }

    // MARK: - String.isBlank

    func testIsBlank_emptyString_isTrue() {
        XCTAssertTrue("".isBlank)
    }

    func testIsBlank_onlySpaces_isTrue() {
        XCTAssertTrue("   ".isBlank)
    }

    func testIsBlank_onlyNewlines_isTrue() {
        XCTAssertTrue("\n\t".isBlank)
    }

    func testIsBlank_nonEmptyString_isFalse() {
        XCTAssertFalse("hello".isBlank)
    }

    func testIsBlank_stringWithInternalWhitespace_isFalse() {
        XCTAssertFalse("hello world".isBlank)
    }

    // MARK: - String.ranges(of:)

    func testRanges_singleOccurrence_returnsOneRange() {
        let ranges = "hello world".ranges(of: "world")
        XCTAssertEqual(ranges.count, 1)
    }

    func testRanges_multipleOccurrences_returnsAll() {
        let ranges = "abcabc".ranges(of: "abc")
        XCTAssertEqual(ranges.count, 2)
    }

    func testRanges_noOccurrence_returnsEmpty() {
        let ranges = "hello".ranges(of: "xyz")
        XCTAssertTrue(ranges.isEmpty)
    }

    func testRanges_caseInsensitive_matchesBothCases() {
        let ranges = "Hello hello".ranges(of: "hello", options: .caseInsensitive)
        XCTAssertEqual(ranges.count, 2)
    }
}
