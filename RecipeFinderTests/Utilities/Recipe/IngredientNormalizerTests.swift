import XCTest
@testable import RecipeFinder

final class IngredientNormalizerTests: XCTestCase {

    // MARK: - Whitespace and case

    func testNormalize_trimmingWhitespace() {
        let result = IngredientNormalizer.normalize("  chicken breast  ")
        XCTAssertFalse(result.hasPrefix(" "))
        XCTAssertFalse(result.hasSuffix(" "))
    }

    func testNormalize_uppercaseInput_returnsCapitalized() {
        let result = IngredientNormalizer.normalize("SALMON")
        XCTAssertEqual(result, "Salmon")
    }

    // MARK: - Known normalization map entries

    func testNormalize_mincedBeef_returnsGroundBeef() {
        XCTAssertEqual(IngredientNormalizer.normalize("minced beef"), "Ground Beef")
    }

    func testNormalize_beefMince_returnsGroundBeef() {
        XCTAssertEqual(IngredientNormalizer.normalize("beef mince"), "Ground Beef")
    }

    func testNormalize_groundBeefMeat_returnsGroundBeef() {
        XCTAssertEqual(IngredientNormalizer.normalize("ground beef meat"), "Ground Beef")
    }

    func testNormalize_slicedChickenBreast_returnsChickenBreast() {
        XCTAssertEqual(IngredientNormalizer.normalize("sliced chicken breast"), "Chicken Breast")
    }

    func testNormalize_salmonFillet_returnsSalmon() {
        XCTAssertEqual(IngredientNormalizer.normalize("salmon fillet"), "Salmon")
    }

    func testNormalize_salmonFilet_returnsSalmon() {
        XCTAssertEqual(IngredientNormalizer.normalize("salmon filet"), "Salmon")
    }

    func testNormalize_peeledAndDeveinedShrimp_returnsShrimp() {
        XCTAssertEqual(IngredientNormalizer.normalize("peeled and deveined shrimp"), "Shrimp")
    }

    func testNormalize_cherryTomatoesHalved_returnsCherryTomatoes() {
        XCTAssertEqual(IngredientNormalizer.normalize("cherry tomatoes halved"), "Cherry Tomatoes")
    }

    func testNormalize_redPepperFlakes_returnsRedPepperFlakes() {
        XCTAssertEqual(IngredientNormalizer.normalize("red pepper flakes"), "Red Pepper Flakes")
    }

    func testNormalize_crushedRedPepper_returnsRedPepperFlakes() {
        XCTAssertEqual(IngredientNormalizer.normalize("crushed red pepper"), "Red Pepper Flakes")
    }

    func testNormalize_cannedDicedTomatoes_returnsDicedTomatoes() {
        XCTAssertEqual(IngredientNormalizer.normalize("canned diced tomatoes"), "Diced Tomatoes")
    }

    // MARK: - Measurement word stripping

    func testNormalize_stripsMeasurementWords() {
        // "2 cups chicken breast" → "chicken breast" → capitalized
        let result = IngredientNormalizer.normalize("2 cups chicken breast")
        XCTAssertFalse(result.lowercased().contains("cup"))
        XCTAssertFalse(result.contains("2"))
    }

    func testNormalize_stripsLeadingNumbers() {
        let result = IngredientNormalizer.normalize("1/2 tsp salt")
        XCTAssertFalse(result.contains("1/2"))
        XCTAssertFalse(result.lowercased().contains("tsp"))
    }

    func testNormalize_stripsParentheticals() {
        let result = IngredientNormalizer.normalize("chicken breast (boneless)")
        XCTAssertFalse(result.contains("(boneless)"))
    }

    // MARK: - Idempotency

    func testNormalize_calledTwice_returnsSameResult() {
        let first = IngredientNormalizer.normalize("minced beef")
        let second = IngredientNormalizer.normalize("minced beef")
        XCTAssertEqual(first, second)
    }

    // MARK: - Batch normalize

    func testNormalizeBatch_returnsCorrectCount() {
        let inputs = ["minced beef", "salmon fillet", "red pepper flakes"]
        let results = IngredientNormalizer.normalize(inputs)
        XCTAssertEqual(results.count, 3)
    }

    func testNormalizeBatch_appliesSameRulesAsScalar() {
        let inputs = ["minced beef", "salmon fillet"]
        let batch = IngredientNormalizer.normalize(inputs)
        XCTAssertEqual(batch[0], IngredientNormalizer.normalize("minced beef"))
        XCTAssertEqual(batch[1], IngredientNormalizer.normalize("salmon fillet"))
    }

    func testNormalizeBatch_emptyArray_returnsEmptyArray() {
        XCTAssertTrue(IngredientNormalizer.normalize([]).isEmpty)
    }

    // MARK: - Unknown ingredient

    func testNormalize_unknownIngredient_returnsCapitalizedInput() {
        let result = IngredientNormalizer.normalize("xyzzy spice")
        XCTAssertEqual(result, "Xyzzy Spice")
    }
}
