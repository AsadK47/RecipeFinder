import Testing
@testable import RecipeFinder

@Suite struct IngredientSubstituteProviderTests {

    // MARK: - Known ingredients

    @Test("Known ingredient returns at least one substitute", arguments: [
        "buttermilk", "butter", "egg", "eggs", "milk",
        "plain flour", "baking powder", "bicarbonate of soda",
        "sugar", "honey", "vanilla extract", "soy sauce",
        "cream", "cocoa powder", "cornflour",
    ])
    func knownIngredient_returnsSubstitutes(ingredient: String) {
        #expect(!IngredientSubstituteProvider.substitutes(for: ingredient).isEmpty)
    }

    // MARK: - Unknown ingredient

    @Test func unknownIngredient_returnsEmpty() {
        #expect(IngredientSubstituteProvider.substitutes(for: "unobtanium crystal").isEmpty)
    }

    // MARK: - Normalisation

    @Test func lookup_isCaseInsensitive() {
        let lower = IngredientSubstituteProvider.substitutes(for: "buttermilk")
        let upper = IngredientSubstituteProvider.substitutes(for: "BUTTERMILK")
        let mixed = IngredientSubstituteProvider.substitutes(for: "Buttermilk")
        #expect(!lower.isEmpty)
        #expect(lower == upper)
        #expect(lower == mixed)
    }

    @Test func lookup_trimsWhitespace() {
        let trimmed = IngredientSubstituteProvider.substitutes(for: "buttermilk")
        let padded  = IngredientSubstituteProvider.substitutes(for: "  buttermilk  ")
        #expect(trimmed == padded)
    }

    // MARK: - Partial / fuzzy matching

    @Test func partialMatch_longIngredientName_resolves() {
        // "large eggs" should resolve via partial match on "eggs"
        let subs = IngredientSubstituteProvider.substitutes(for: "large eggs")
        #expect(!subs.isEmpty)
    }

    @Test("Prep words, amounts and comma notes don't change the lookup", arguments: [
        ("Unsalted butter, softened", "butter"),
        ("2 large eggs, beaten", "eggs"),
        ("Fresh buttermilk", "buttermilk"),
        ("full-fat buttermilk", "buttermilk"),
    ])
    func decoratedName_matchesPlainName(decorated: String, plain: String) {
        let subs = IngredientSubstituteProvider.substitutes(for: decorated)
        #expect(!subs.isEmpty)
        #expect(subs == IngredientSubstituteProvider.substitutes(for: plain))
    }

    @Test("Whole words only — a key inside another word doesn't match", arguments: ["eggplant", "butternut squash"])
    func substringOfAnotherWord_returnsEmpty(ingredient: String) {
        #expect(IngredientSubstituteProvider.substitutes(for: ingredient).isEmpty)
    }

    // MARK: - Spot checks on content

    @Test func buttermilk_includesVinegarOption() {
        let subs = IngredientSubstituteProvider.substitutes(for: "buttermilk")
        #expect(subs.contains { $0.contains("vinegar") })
    }

    @Test func egg_includesAquafaba() {
        let subs = IngredientSubstituteProvider.substitutes(for: "egg")
        #expect(subs.contains { $0.contains("aquafaba") })
    }

    @Test func bakingPowder_includesBicarb() {
        let subs = IngredientSubstituteProvider.substitutes(for: "baking powder")
        #expect(subs.contains { $0.lowercased().contains("bicarbonate") || $0.lowercased().contains("bicarb") })
    }
}
