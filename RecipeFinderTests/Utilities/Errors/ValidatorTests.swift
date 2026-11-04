import XCTest
import Testing
@testable import RecipeFinder

final class ValidatorTests: XCTestCase {

    // MARK: - validateRecipeName

    func testValidRecipeName_sufficientLength_doesNotThrow() {
        XCTAssertNoThrow(try Validator.validateRecipeName("Pasta"))
    }

    func testInvalidRecipeName_empty_throwsEmptyField() {
        XCTAssertThrowsError(try Validator.validateRecipeName("")) { error in
            guard case AppError.emptyField(let field) = error else {
                return XCTFail("Expected emptyField, got \(error)")
            }
            XCTAssertFalse(field.isEmpty)
        }
    }

    func testInvalidRecipeName_whitespaceOnly_throwsEmptyField() {
        XCTAssertThrowsError(try Validator.validateRecipeName("   ")) { error in
            guard case AppError.emptyField = error else {
                XCTFail("Expected emptyField, got \(error)")
                return
            }
        }
    }

    func testInvalidRecipeName_twoChars_throwsInvalidRecipeName() {
        XCTAssertThrowsError(try Validator.validateRecipeName("Eg")) { error in
            guard case AppError.invalidRecipeName = error else {
                XCTFail("Expected invalidRecipeName, got \(error)")
                return
            }
        }
    }

    func testValidRecipeName_exactlyThreeChars_doesNotThrow() {
        XCTAssertNoThrow(try Validator.validateRecipeName("Egg"))
    }

    func testValidRecipeName_leadingTrailingWhitespace_strippedBeforeValidation() {
        XCTAssertNoThrow(try Validator.validateRecipeName("  Pasta  "))
    }

    // MARK: - validateServings

    func testValidServings_one_doesNotThrow() {
        XCTAssertNoThrow(try Validator.validateServings(1))
    }

    func testValidServings_fifty_doesNotThrow() {
        XCTAssertNoThrow(try Validator.validateServings(50))
    }

    func testInvalidServings_zero_throws() {
        XCTAssertThrowsError(try Validator.validateServings(0)) { error in
            guard case AppError.invalidServings = error else {
                XCTFail("Expected invalidServings, got \(error)")
                return
            }
        }
    }

    func testInvalidServings_fiftyOne_throws() {
        XCTAssertThrowsError(try Validator.validateServings(51)) { error in
            guard case AppError.invalidServings = error else {
                XCTFail("Expected invalidServings, got \(error)")
                return
            }
        }
    }

    // MARK: - validateQuantity

    func testValidQuantity_integerString_returnsDouble() throws {
        let result = try Validator.validateQuantity("3", field: "Amount")
        XCTAssertEqual(result, 3.0, accuracy: 0.001)
    }

    func testValidQuantity_decimalString_returnsDouble() throws {
        let result = try Validator.validateQuantity("2.5", field: "Amount")
        XCTAssertEqual(result, 2.5, accuracy: 0.001)
    }

    func testValidQuantity_simpleFraction_returnsDouble() throws {
        let result = try Validator.validateQuantity("1/2", field: "Amount")
        XCTAssertEqual(result, 0.5, accuracy: 0.001)
    }

    func testValidQuantity_mixedNumber_returnsDouble() throws {
        let result = try Validator.validateQuantity("1 1/2", field: "Amount")
        XCTAssertEqual(result, 1.5, accuracy: 0.001)
    }

    func testValidQuantity_quarterFraction_returnsDouble() throws {
        let result = try Validator.validateQuantity("3/4", field: "Amount")
        XCTAssertEqual(result, 0.75, accuracy: 0.001)
    }

    func testInvalidQuantity_empty_throwsEmptyField() {
        XCTAssertThrowsError(try Validator.validateQuantity("", field: "Weight")) { error in
            guard case AppError.emptyField(let field) = error else {
                return XCTFail("Expected emptyField, got \(error)")
            }
            XCTAssertEqual(field, "Weight")
        }
    }

    func testInvalidQuantity_text_throwsInvalidFormat() {
        XCTAssertThrowsError(try Validator.validateQuantity("abc", field: "Amount")) { error in
            guard case AppError.invalidFormat = error else {
                XCTFail("Expected invalidFormat, got \(error)")
                return
            }
        }
    }

    func testInvalidQuantity_zero_throwsInvalidFormat() {
        XCTAssertThrowsError(try Validator.validateQuantity("0", field: "Amount")) { error in
            guard case AppError.invalidFormat = error else {
                XCTFail("Expected invalidFormat, got \(error)")
                return
            }
        }
    }
}

@Suite("Validator quantity parsing")
struct ValidatorUnicodeQuantityTests {
    @Test("Accepts Unicode fractions, same as the ingredient parser", arguments: [
        ("½", 0.5), ("1½", 1.5), ("2 ¾", 2.75),
    ])
    func acceptsUnicodeFractions(input: String, expected: Double) throws {
        #expect(try Validator.validateQuantity(input, field: "Amount") == expected)
    }
}
