import Testing
import XCTest
@testable import RecipeFinder

final class CategoryClassifierTests: XCTestCase {

    // MARK: - Meat

    func testCategorize_beef_returnsMeat() {
        XCTAssertEqual(CategoryClassifier.categorize("beef"), "Meat")
    }

    func testCategorize_groundBeef_returnsMeat() {
        XCTAssertEqual(CategoryClassifier.categorize("ground beef"), "Meat")
    }

    func testCategorize_bacon_returnsMeat() {
        XCTAssertEqual(CategoryClassifier.categorize("bacon"), "Meat")
    }

    // MARK: - Poultry

    func testCategorize_chickenBreast_returnsPoultry() {
        XCTAssertEqual(CategoryClassifier.categorize("chicken breast"), "Poultry")
    }

    func testCategorize_turkey_returnsPoultry() {
        XCTAssertEqual(CategoryClassifier.categorize("turkey"), "Poultry")
    }

    // MARK: - Seafood

    func testCategorize_salmon_returnsSeafood() {
        XCTAssertEqual(CategoryClassifier.categorize("salmon"), "Seafood")
    }

    func testCategorize_shrimp_returnsSeafood() {
        XCTAssertEqual(CategoryClassifier.categorize("shrimp"), "Seafood")
    }

    // MARK: - Produce (Vegetables & Fruits)

    func testCategorize_tomato_returnsProduce() {
        XCTAssertEqual(CategoryClassifier.categorize("tomato"), "Produce")
    }

    func testCategorize_apple_returnsProduce() {
        XCTAssertEqual(CategoryClassifier.categorize("apple"), "Produce")
    }

    // MARK: - Dairy & Eggs

    func testCategorize_milk_returnsDairyEggs() {
        XCTAssertEqual(CategoryClassifier.categorize("milk"), "Dairy & Eggs")
    }

    func testCategorize_eggs_returnsDairyEggs() {
        XCTAssertEqual(CategoryClassifier.categorize("eggs"), "Dairy & Eggs")
    }

    // MARK: - Grains & Pasta

    func testCategorize_rice_returnsGrainsPasta() {
        XCTAssertEqual(CategoryClassifier.categorize("rice"), "Grains & Pasta")
    }

    func testCategorize_pasta_returnsGrainsPasta() {
        XCTAssertEqual(CategoryClassifier.categorize("pasta"), "Grains & Pasta")
    }

    // MARK: - Oils & Fats

    func testCategorize_oliveOil_returnsOilsFats() {
        XCTAssertEqual(CategoryClassifier.categorize("olive oil"), "Oils & Fats")
    }

    func testCategorize_butter_returnsOilsFats() {
        XCTAssertEqual(CategoryClassifier.categorize("butter"), "Oils & Fats")
    }

    // MARK: - Sauces & Condiments

    func testCategorize_soySauce_returnsSaucesCondiments() {
        XCTAssertEqual(CategoryClassifier.categorize("soy sauce"), "Sauces & Condiments")
    }

    func testCategorize_vinegar_returnsSaucesCondiments() {
        XCTAssertEqual(CategoryClassifier.categorize("balsamic vinegar"), "Sauces & Condiments")
    }

    // MARK: - Herbs & Spices

    func testCategorize_basil_returnsHerbsFreshSpices() {
        XCTAssertEqual(CategoryClassifier.categorize("basil"), "Herbs & Fresh Spices")
    }

    func testCategorize_blackPepper_returnsDriedSpices() {
        XCTAssertEqual(CategoryClassifier.categorize("black pepper"), "Dried Spices & Seasonings")
    }

    // MARK: - Sweeteners

    func testCategorize_honey_returnsSweeteners() {
        XCTAssertEqual(CategoryClassifier.categorize("honey"), "Sweeteners")
    }

    func testCategorize_sugar_returnsSweeteners() {
        XCTAssertEqual(CategoryClassifier.categorize("sugar"), "Sweeteners")
    }

    // MARK: - Bakery

    func testCategorize_bread_returnsBakery() {
        XCTAssertEqual(CategoryClassifier.categorize("bread"), "Bakery")
    }

    func testCategorize_croissant_returnsBakery() {
        XCTAssertEqual(CategoryClassifier.categorize("croissant"), "Bakery")
    }

    // MARK: - Frozen

    func testCategorize_frozenPeas_returnsFrozen() {
        XCTAssertEqual(CategoryClassifier.categorize("frozen peas"), "Frozen")
    }

    func testCategorize_iceCream_returnsFrozen() {
        XCTAssertEqual(CategoryClassifier.categorize("ice cream"), "Frozen")
    }

    // MARK: - Beverages

    func testCategorize_coffee_returnsBeverages() {
        XCTAssertEqual(CategoryClassifier.categorize("coffee"), "Beverages")
    }

    func testCategorize_juice_returnsBeverages() {
        XCTAssertEqual(CategoryClassifier.categorize("orange juice"), "Beverages")
    }

    // MARK: - Baking Supplies

    func testCategorize_bakingPowder_returnsBakingSupplies() {
        XCTAssertEqual(CategoryClassifier.categorize("baking powder"), "Baking Supplies")
    }

    func testCategorize_yeast_returnsBakingSupplies() {
        XCTAssertEqual(CategoryClassifier.categorize("yeast"), "Baking Supplies")
    }

    // MARK: - Canned & Jarred

    func testCategorize_cannedTomatoes_returnsCannedJarred() {
        XCTAssertEqual(CategoryClassifier.categorize("canned tomatoes"), "Canned & Jarred")
    }

    // MARK: - Fallback

    func testCategorize_unknownIngredient_returnsOther() {
        XCTAssertEqual(CategoryClassifier.categorize("xyzzy powder"), "Other")
    }

    // MARK: - Case insensitivity

    func testCategorize_uppercaseInput_returnsCorrectCategory() {
        XCTAssertEqual(CategoryClassifier.categorize("CHICKEN"), "Poultry")
    }

    func testCategorize_mixedCaseInput_returnsCorrectCategory() {
        XCTAssertEqual(CategoryClassifier.categorize("Olive Oil"), "Oils & Fats")
    }

    // MARK: - Caching (idempotency)

    func testCategorize_calledTwice_returnsSameResult() {
        let first = CategoryClassifier.categorize("salmon")
        let second = CategoryClassifier.categorize("salmon")
        XCTAssertEqual(first, second)
    }

}

@Suite("CategoryClassifier citrus juice")
struct CategoryClassifierCitrusTests {
    @Test("Cooking citrus juice is Produce; orange juice stays a Beverage")
    func citrusJuice() {
        #expect(CategoryClassifier.categorize("Lemon Juice") == "Produce")
        #expect(CategoryClassifier.categorize("lime juice") == "Produce")
        #expect(CategoryClassifier.categorize("orange juice") == "Beverages")
    }
}
