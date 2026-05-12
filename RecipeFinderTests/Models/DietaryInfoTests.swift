import XCTest
@testable import RecipeFinder

final class DietaryInfoTests: XCTestCase {

    // MARK: - SnackItem.displayName

    func testDisplayName_combinesEmojiAndName() {
        let snack = makeSnack(emoji: "🍎", name: "Apple")
        XCTAssertEqual(snack.displayName, "🍎 Apple")
    }

    // MARK: - SnackItem.matches(dietaryFilters:)

    func testMatches_emptyFilters_returnsTrue() {
        let snack = makeSnack(tags: [.vegan])
        XCTAssertTrue(snack.matches(dietaryFilters: []))
    }

    func testMatches_allRequiredFiltersPresent_returnsTrue() {
        let snack = makeSnack(tags: [.vegan, .glutenFree])
        XCTAssertTrue(snack.matches(dietaryFilters: [.vegan, .glutenFree]))
    }

    func testMatches_singleMatchingFilter_returnsTrue() {
        let snack = makeSnack(tags: [.vegan, .glutenFree])
        XCTAssertTrue(snack.matches(dietaryFilters: [.vegan]))
    }

    func testMatches_filterNotInTags_returnsFalse() {
        let snack = makeSnack(tags: [.vegan])
        XCTAssertFalse(snack.matches(dietaryFilters: [.keto]))
    }

    func testMatches_partialFilterMatch_returnsFalse() {
        let snack = makeSnack(tags: [.vegan])
        XCTAssertFalse(snack.matches(dietaryFilters: [.vegan, .glutenFree]))
    }

    func testMatches_noTags_emptyFilters_returnsTrue() {
        let snack = makeSnack(tags: [])
        XCTAssertTrue(snack.matches(dietaryFilters: []))
    }

    func testMatches_noTags_withFilter_returnsFalse() {
        let snack = makeSnack(tags: [])
        XCTAssertFalse(snack.matches(dietaryFilters: [.vegan]))
    }

    // MARK: - SnackDatabase.snacks(forCategory:)

    func testSnacksForCategory_returnsOnlyMatchingCategory() {
        let fruitSnacks = SnackDatabase.snacks(forCategory: .fruit)
        XCTAssertFalse(fruitSnacks.isEmpty)
        XCTAssertTrue(fruitSnacks.allSatisfy { $0.category == .fruit })
    }

    func testSnacksForCategory_differentCategoriesHaveNoOverlap() {
        let fruits = Set(SnackDatabase.snacks(forCategory: .fruit).map(\.id))
        let nuts = Set(SnackDatabase.snacks(forCategory: .nuts).map(\.id))
        XCTAssertTrue(fruits.isDisjoint(with: nuts))
    }

    func testSnacksForCategory_allCategoriesRepresented() {
        for category in SnackCategory.allCases {
            let snacks = SnackDatabase.snacks(forCategory: category)
            XCTAssertFalse(snacks.isEmpty, "\(category) has no snacks in the database")
        }
    }

    // MARK: - SnackDatabase.snacks(matching:)

    func testSnacksMatching_emptyFilter_returnsAllSnacks() {
        XCTAssertEqual(SnackDatabase.snacks(matching: []).count, SnackDatabase.allSnacks.count)
    }

    func testSnacksMatching_ketoFilter_returnsOnlyKetoSnacks() {
        let results = SnackDatabase.snacks(matching: [.keto])
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.allSatisfy { $0.dietaryTags.contains(.keto) })
    }

    func testSnacksMatching_multipleFilters_allResultsSatisfyAllFilters() {
        let results = SnackDatabase.snacks(matching: [.vegan, .glutenFree])
        XCTAssertTrue(results.allSatisfy {
            $0.dietaryTags.contains(.vegan) && $0.dietaryTags.contains(.glutenFree)
        })
    }

    func testSnacksMatching_strictFilter_returnsSubsetOfAll() {
        let all = SnackDatabase.allSnacks
        let filtered = SnackDatabase.snacks(matching: [.keto])
        XCTAssertLessThan(filtered.count, all.count)
    }

    // MARK: - SnackDatabase.popularSnacks()

    func testPopularSnacks_returnsEightItems() {
        XCTAssertEqual(SnackDatabase.popularSnacks().count, 8)
    }

    func testPopularSnacks_containsExpectedNames() {
        let names = SnackDatabase.popularSnacks().map(\.name)
        XCTAssertTrue(names.contains("Apple"))
        XCTAssertTrue(names.contains("Banana"))
        XCTAssertTrue(names.contains("Almonds"))
    }

    // MARK: - Helpers

    private func makeSnack(
        emoji: String = "🍎",
        name: String = "Apple",
        tags: [DietaryTag] = [],
        calories: Int? = nil,
        category: SnackCategory = .fruit
    ) -> SnackItem {
        SnackItem(emoji: emoji, name: name, dietaryTags: tags, calories: calories, category: category)
    }
}
