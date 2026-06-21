import XCTest
@testable import RecipeFinder

final class IngredientAutocompleteEngineTests: XCTestCase {

    func testSuggestions_emptyQuery_returnsNoSuggestions() {
        XCTAssertTrue(IngredientAutocompleteEngine.suggestions(for: "").isEmpty)
        XCTAssertTrue(IngredientAutocompleteEngine.suggestions(for: "   ").isEmpty)
    }

    func testSuggestions_prefixMatchesRankBeforeContainsMatches() {
        let suggestions = IngredientAutocompleteEngine.suggestions(
            for: "berry",
            limit: 5,
            additionalCandidates: ["Blueberry", "Berry Blend"]
        )

        XCTAssertGreaterThanOrEqual(suggestions.count, 2)
        XCTAssertEqual(suggestions[0].name, "Berry Blend")
        XCTAssertEqual(suggestions[1].name, "Blueberry")
    }

    func testSuggestions_normalizesIngredientDescriptors() {
        let suggestions = IngredientAutocompleteEngine.suggestions(for: "canned diced tomatoes", limit: 5)

        XCTAssertFalse(suggestions.isEmpty)
        XCTAssertEqual(suggestions.first?.name, "Diced Tomatoes")
        XCTAssertEqual(suggestions.first?.source, "Catalog")
    }

    func testSuggestions_returnsCatalogSourceForKnownFoods() {
        let suggestions = IngredientAutocompleteEngine.suggestions(for: "salmon", limit: 5)

        XCTAssertFalse(suggestions.isEmpty)
        XCTAssertEqual(suggestions.first?.name, "Salmon")
        XCTAssertEqual(suggestions.first?.source, "Catalog")
    }

    func testSuggestions_returnsCustomSourceForAdditionalCandidates() {
        let suggestions = IngredientAutocompleteEngine.suggestions(
            for: "ghost",
            limit: 5,
            additionalCandidates: ["Ghost Pepper"]
        )

        XCTAssertEqual(suggestions.first?.name, "Ghost Pepper")
        XCTAssertEqual(suggestions.first?.source, "Custom")
    }

    func testSuggestions_deduplicatesRepeatedCandidates() {
        let suggestions = IngredientAutocompleteEngine.suggestions(
            for: "ghost",
            limit: 5,
            additionalCandidates: ["Ghost Pepper", "Ghost Pepper", "ghost pepper"]
        )

        XCTAssertEqual(suggestions.map(\.name), ["Ghost Pepper"])
    }

    func testSuggestions_respectsLimit() {
        let suggestions = IngredientAutocompleteEngine.suggestions(
            for: "pep",
            limit: 2,
            additionalCandidates: ["Pepper Jack", "Pepper", "Pepperoncini", "Peppermint"]
        )

        XCTAssertLessThanOrEqual(suggestions.count, 2)
    }

    func testRankedNames_returnsOnlyNamesInRankedOrder() {
        let names = IngredientAutocompleteEngine.rankedNames(
            for: "berry",
            limit: 3,
            additionalCandidates: ["Berry Blend", "Blueberry"]
        )

        XCTAssertEqual(Array(names.prefix(2)), ["Berry Blend", "Blueberry"])
    }
}