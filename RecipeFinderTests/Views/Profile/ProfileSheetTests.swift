import XCTest
@testable import RecipeFinder

final class ProfileSheetTests: XCTestCase {

    // MARK: - id values

    func testId_privacyPolicy() {
        XCTAssertEqual(ProfileSheet.privacyPolicy.id, "privacyPolicy")
    }

    func testId_imagePicker() {
        XCTAssertEqual(ProfileSheet.imagePicker.id, "imagePicker")
    }

    // MARK: - uniqueness

    func testId_staticCasesAreUnique() {
        let ids = [ProfileSheet.privacyPolicy.id,
                   ProfileSheet.imagePicker.id]
        XCTAssertEqual(ids.count, Set(ids).count)
    }

}
