import XCTest
@testable import RecipeFinder

final class BadgeModelTests: XCTestCase {

    // MARK: - BadgeType.requiredCount

    func testRequiredCount_countBasedBadges() {
        XCTAssertEqual(BadgeType.firstRecipe.requiredCount, 1)
        XCTAssertEqual(BadgeType.fiveRecipes.requiredCount, 5)
        XCTAssertEqual(BadgeType.tenRecipes.requiredCount, 10)
        XCTAssertEqual(BadgeType.twentyFiveRecipes.requiredCount, 25)
        XCTAssertEqual(BadgeType.fiftyRecipes.requiredCount, 50)
        XCTAssertEqual(BadgeType.hundredRecipes.requiredCount, 100)
    }

    func testRequiredCount_nonCountBadgesAreZero() {
        XCTAssertEqual(BadgeType.welcomeAboard.requiredCount, 0)
        XCTAssertEqual(BadgeType.mealPlanner.requiredCount, 0)
        XCTAssertEqual(BadgeType.shoppingExpert.requiredCount, 0)
    }

    func testRequiredCount_thresholdsAreStrictlyIncreasing() {
        let countBased: [BadgeType] = [.firstRecipe, .fiveRecipes, .tenRecipes, .twentyFiveRecipes, .fiftyRecipes, .hundredRecipes]
        let counts = countBased.map(\.requiredCount)
        for i in 1..<counts.count {
            XCTAssertGreaterThan(counts[i], counts[i - 1])
        }
    }

    // MARK: - BadgeType.badge invariants

    func testBadge_idMatchesRawValue() {
        for type in BadgeType.allCases {
            XCTAssertEqual(type.badge.id, type.rawValue)
        }
    }

    func testBadge_defaultsAreLockedAndUnearned() {
        for type in BadgeType.allCases {
            let badge = type.badge
            XCTAssertFalse(badge.isUnlocked)
            XCTAssertNil(badge.dateEarned)
        }
    }

    func testBadge_allTypesHaveNonEmptyFields() {
        for type in BadgeType.allCases {
            let badge = type.badge
            XCTAssertFalse(badge.title.isEmpty, "\(type) has empty title")
            XCTAssertFalse(badge.icon.isEmpty, "\(type) has empty icon")
            XCTAssertFalse(badge.color.isEmpty, "\(type) has empty color")
            XCTAssertFalse(badge.howToEarn.isEmpty, "\(type) has empty howToEarn")
        }
    }
}
