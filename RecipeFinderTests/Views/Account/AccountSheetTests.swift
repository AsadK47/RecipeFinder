import XCTest
@testable import RecipeFinder

final class AccountSheetTests: XCTestCase {

    // MARK: - id values

    func testId_privacyPolicy() {
        XCTAssertEqual(AccountSheet.privacyPolicy.id, "privacyPolicy")
    }

    func testId_imagePicker() {
        XCTAssertEqual(AccountSheet.imagePicker.id, "imagePicker")
    }

    func testId_passwordVerification() {
        XCTAssertEqual(AccountSheet.passwordVerification.id, "passwordVerification")
    }

    func testId_badgeIncludesBadgeId() {
        let badge = Badge(id: "test-badge-42", title: "Test", description: "Desc",
                         icon: "star", color: "gold", dateEarned: nil, isUnlocked: false,
                         howToEarn: "Do stuff")
        XCTAssertEqual(AccountSheet.badge(badge).id, "badge_test-badge-42")
    }

    // MARK: - uniqueness

    func testId_staticCasesAreUnique() {
        let ids = [AccountSheet.privacyPolicy.id,
                   AccountSheet.imagePicker.id,
                   AccountSheet.passwordVerification.id]
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testId_staticCasesDoNotClashWithBadgePrefix() {
        let staticIds = [AccountSheet.privacyPolicy.id,
                         AccountSheet.imagePicker.id,
                         AccountSheet.passwordVerification.id]
        for id in staticIds {
            XCTAssertFalse(id.hasPrefix("badge_"), "\(id) clashes with badge prefix")
        }
    }

    func testId_differentBadgeIdsProduceDifferentSheetIds() {
        let b1 = Badge(id: "a", title: "A", description: "", icon: "star",
                       color: "blue", dateEarned: nil, isUnlocked: false, howToEarn: "")
        let b2 = Badge(id: "b", title: "B", description: "", icon: "star",
                       color: "blue", dateEarned: nil, isUnlocked: false, howToEarn: "")
        XCTAssertNotEqual(AccountSheet.badge(b1).id, AccountSheet.badge(b2).id)
    }
}
