import XCTest
@testable import RecipeFinder

final class AppErrorTests: XCTestCase {

    // MARK: - errorDescription — interpolated associated values

    func testSaveFailed_errorDescription_containsDetails() {
        let error = AppError.saveFailed(details: "disk full")
        XCTAssertEqual(error.errorDescription, "Failed to save: disk full")
    }

    func testLoadFailed_errorDescription_containsDetails() {
        let error = AppError.loadFailed(details: "corrupted")
        XCTAssertEqual(error.errorDescription, "Failed to load data: corrupted")
    }

    func testDeleteFailed_errorDescription_containsDetails() {
        let error = AppError.deleteFailed(details: "locked")
        XCTAssertEqual(error.errorDescription, "Failed to delete: locked")
    }

    func testWeakPassword_errorDescription_containsReason() {
        let error = AppError.weakPassword(reason: "too short")
        XCTAssertEqual(error.errorDescription, "Password is too weak: too short")
    }

    func testImportFailed_errorDescription_containsReason() {
        let error = AppError.importFailed(reason: "timeout")
        XCTAssertEqual(error.errorDescription, "Import failed: timeout")
    }

    func testEmptyField_errorDescription_containsFieldName() {
        let error = AppError.emptyField(field: "Username")
        XCTAssertEqual(error.errorDescription, "Username cannot be empty")
    }

    func testInvalidFormat_errorDescription_containsFieldName() {
        let error = AppError.invalidFormat(field: "Phone")
        XCTAssertEqual(error.errorDescription, "Phone format is invalid")
    }

    func testOutOfRange_errorDescription_containsFieldAndBounds() {
        let error = AppError.outOfRange(field: "Servings", min: 1, max: 50)
        XCTAssertEqual(error.errorDescription, "Servings must be between 1 and 50")
    }

    // MARK: - errorDescription — static cases

    func testDuplicateEntry_errorDescription() {
        XCTAssertEqual(AppError.duplicateEntry.errorDescription, "This item already exists")
    }

    func testNotFound_errorDescription() {
        XCTAssertEqual(AppError.notFound.errorDescription, "Item not found")
    }

    func testInvalidCredentials_errorDescription() {
        XCTAssertEqual(AppError.invalidCredentials.errorDescription, "Invalid email or password")
    }

    func testInvalidEmail_errorDescription() {
        XCTAssertEqual(AppError.invalidEmail.errorDescription, "Please enter a valid email address")
    }

    func testUserAlreadyExists_errorDescription() {
        XCTAssertEqual(AppError.userAlreadyExists.errorDescription, "An account with this email already exists")
    }

    func testSessionExpired_errorDescription() {
        XCTAssertEqual(AppError.sessionExpired.errorDescription, "Your session has expired. Please sign in again")
    }

    func testInvalidRecipeName_errorDescription() {
        XCTAssertEqual(AppError.invalidRecipeName.errorDescription, "Recipe name must be at least 3 characters")
    }

    func testMissingIngredients_errorDescription() {
        XCTAssertEqual(AppError.missingIngredients.errorDescription, "Please add at least one ingredient")
    }

    func testMissingInstructions_errorDescription() {
        XCTAssertEqual(AppError.missingInstructions.errorDescription, "Please add cooking instructions")
    }

    func testInvalidServings_errorDescription() {
        XCTAssertEqual(AppError.invalidServings.errorDescription, "Servings must be between 1 and 50")
    }

    func testNetworkUnavailable_errorDescription() {
        XCTAssertTrue(AppError.networkUnavailable.errorDescription?.contains("internet") == true)
    }

    func testInvalidURL_errorDescription() {
        XCTAssertEqual(AppError.invalidURL.errorDescription, "Please enter a valid recipe URL")
    }

    func testParsingFailed_errorDescription() {
        XCTAssertEqual(AppError.parsingFailed.errorDescription, "Could not parse recipe from this website")
    }

    // MARK: - errorDescription — all cases non-nil

    func testAllErrorDescriptions_areNonNil() {
        let errors: [AppError] = [
            .saveFailed(details: "x"), .loadFailed(details: "x"), .deleteFailed(details: "x"),
            .duplicateEntry, .notFound,
            .invalidCredentials, .weakPassword(reason: "x"), .invalidEmail,
            .userAlreadyExists, .authenticationFailed, .sessionExpired,
            .invalidRecipeName, .missingIngredients, .missingInstructions,
            .invalidServings, .invalidCookTime,
            .networkUnavailable, .importFailed(reason: "x"), .invalidURL, .parsingFailed,
            .emptyField(field: "x"), .invalidFormat(field: "x"), .outOfRange(field: "x", min: 0, max: 1)
        ]
        for error in errors {
            XCTAssertNotNil(error.errorDescription, "\(error) has nil errorDescription")
            XCTAssertFalse(error.errorDescription!.isEmpty, "\(error) has empty errorDescription")
        }
    }

    // MARK: - recoverySuggestion

    func testRecoverySuggestion_networkUnavailable_isNonNil() {
        XCTAssertNotNil(AppError.networkUnavailable.recoverySuggestion)
    }

    func testRecoverySuggestion_weakPassword_isNonNil() {
        XCTAssertNotNil(AppError.weakPassword(reason: "x").recoverySuggestion)
    }

    func testRecoverySuggestion_invalidEmail_isNonNil() {
        XCTAssertNotNil(AppError.invalidEmail.recoverySuggestion)
    }

    func testRecoverySuggestion_invalidRecipeName_isNonNil() {
        XCTAssertNotNil(AppError.invalidRecipeName.recoverySuggestion)
    }

    func testRecoverySuggestion_missingIngredients_isNonNil() {
        XCTAssertNotNil(AppError.missingIngredients.recoverySuggestion)
    }

    func testRecoverySuggestion_duplicateEntry_isNil() {
        XCTAssertNil(AppError.duplicateEntry.recoverySuggestion)
    }
}
