import XCTest
@testable import RecipeFinder

final class CookingTipModelTests: XCTestCase {

    // MARK: - CookingTipCategory.icon

    func testCategoryIcon_allCasesHaveNonEmptyIcon() {
        for category in CookingTipCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty, "\(category) has empty icon")
        }
    }

    func testCategoryIcon_specificValues() {
        XCTAssertEqual(CookingTipCategory.basics.icon, "book.fill")
        XCTAssertEqual(CookingTipCategory.techniques.icon, "wand.and.stars")
        XCTAssertEqual(CookingTipCategory.ingredients.icon, "carrot.fill")
        XCTAssertEqual(CookingTipCategory.equipment.icon, "wrench.and.screwdriver.fill")
        XCTAssertEqual(CookingTipCategory.safety.icon, "checkmark.shield.fill")
        XCTAssertEqual(CookingTipCategory.storage.icon, "refrigerator.fill")
        XCTAssertEqual(CookingTipCategory.substitutions.icon, "arrow.triangle.swap")
        XCTAssertEqual(CookingTipCategory.timeSaving.icon, "bolt.fill")
        XCTAssertEqual(CookingTipCategory.presentation.icon, "sparkles")
        XCTAssertEqual(CookingTipCategory.seasoning.icon, "leaf.fill")
    }

    // MARK: - CookingTipCategory.color

    func testCategoryColor_allCasesHaveNonEmptyColor() {
        for category in CookingTipCategory.allCases {
            XCTAssertFalse(category.color.isEmpty, "\(category) has empty color")
        }
    }

    func testCategoryColor_specificValues() {
        XCTAssertEqual(CookingTipCategory.basics.color, "blue")
        XCTAssertEqual(CookingTipCategory.techniques.color, "purple")
        XCTAssertEqual(CookingTipCategory.ingredients.color, "green")
        XCTAssertEqual(CookingTipCategory.equipment.color, "orange")
        XCTAssertEqual(CookingTipCategory.safety.color, "red")
        XCTAssertEqual(CookingTipCategory.storage.color, "cyan")
        XCTAssertEqual(CookingTipCategory.substitutions.color, "indigo")
        XCTAssertEqual(CookingTipCategory.timeSaving.color, "yellow")
        XCTAssertEqual(CookingTipCategory.presentation.color, "pink")
        XCTAssertEqual(CookingTipCategory.seasoning.color, "mint")
    }

    // MARK: - CookingTipCategory.id

    func testCategoryId_matchesRawValue() {
        for category in CookingTipCategory.allCases {
            XCTAssertEqual(category.id, category.rawValue)
        }
    }

    // MARK: - TipDifficulty.icon

    func testDifficultyIcon_allCasesHaveNonEmptyIcon() {
        for difficulty in TipDifficulty.allCases {
            XCTAssertFalse(difficulty.icon.isEmpty, "\(difficulty) has empty icon")
        }
    }

    func testDifficultyIcon_specificValues() {
        XCTAssertEqual(TipDifficulty.beginner.icon, "star.fill")
        XCTAssertEqual(TipDifficulty.intermediate.icon, "star.leadinghalf.filled")
        XCTAssertEqual(TipDifficulty.advanced.icon, "star.circle.fill")
    }
}
