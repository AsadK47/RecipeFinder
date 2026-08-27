import Testing
@testable import RecipeFinder

@Suite("IngredientNormalizer")
struct IngredientNormalizerTests {

    // MARK: - Known normalization map

    /// Each case is an ingredient string and the canonical name it should
    /// normalize to. Adding a row here adds a test case — no new function needed.
    @Test("Maps known variants to their canonical name", arguments: [
        (input: "minced beef",                    expected: "Ground Beef"),
        (input: "beef mince",                     expected: "Ground Beef"),
        (input: "ground beef meat",               expected: "Ground Beef"),
        (input: "sliced chicken breast",          expected: "Chicken Breast"),
        (input: "salmon fillet",                  expected: "Salmon"),
        (input: "salmon filet",                   expected: "Salmon"),
        (input: "peeled and deveined shrimp",     expected: "Shrimp"),
        (input: "cherry tomatoes halved",         expected: "Cherry Tomatoes"),
        (input: "red pepper flakes",              expected: "Red Pepper Flakes"),
        (input: "crushed red pepper",             expected: "Red Pepper Flakes"),
        (input: "canned diced tomatoes",          expected: "Diced Tomatoes"),
    ])
    func mapsKnownVariants(_ testCase: (input: String, expected: String)) {
        #expect(IngredientNormalizer.normalize(testCase.input) == testCase.expected)
    }

    // MARK: - Whitespace and case

    @Test("Trims surrounding whitespace")
    func trimsWhitespace() {
        let result = IngredientNormalizer.normalize("  chicken breast  ")
        #expect(!result.hasPrefix(" "))
        #expect(!result.hasSuffix(" "))
    }

    @Test("Capitalizes uppercase input")
    func capitalizesUppercase() {
        #expect(IngredientNormalizer.normalize("SALMON") == "Salmon")
    }

    // MARK: - Measurement word stripping

    @Test("Strips measurement words and quantities")
    func stripsMeasurementWords() {
        let result = IngredientNormalizer.normalize("2 cups chicken breast")
        #expect(!result.lowercased().contains("cup"))
        #expect(!result.contains("2"))
    }

    @Test("Strips leading numbers and units")
    func stripsLeadingNumbers() {
        let result = IngredientNormalizer.normalize("1/2 tsp salt")
        #expect(!result.contains("1/2"))
        #expect(!result.lowercased().contains("tsp"))
    }

    @Test("Strips parenthetical notes")
    func stripsParentheticals() {
        #expect(!IngredientNormalizer.normalize("chicken breast (boneless)").contains("(boneless)"))
    }

    // MARK: - Determinism

    @Test("Returns the same result when called twice")
    func deterministic() {
        let first = IngredientNormalizer.normalize("minced beef")
        let second = IngredientNormalizer.normalize("minced beef")
        #expect(first == second)
    }

    // MARK: - Batch normalize

    @Test("Batch normalize preserves count")
    func batchPreservesCount() {
        let results = IngredientNormalizer.normalize(["minced beef", "salmon fillet", "red pepper flakes"])
        #expect(results.count == 3)
    }

    @Test("Batch normalize applies the same rules as the scalar form")
    func batchMatchesScalar() {
        let inputs = ["minced beef", "salmon fillet"]
        let batch = IngredientNormalizer.normalize(inputs)
        #expect(batch[0] == IngredientNormalizer.normalize("minced beef"))
        #expect(batch[1] == IngredientNormalizer.normalize("salmon fillet"))
    }

    @Test("Batch normalize of empty array is empty")
    func batchEmpty() {
        #expect(IngredientNormalizer.normalize([]).isEmpty)
    }

    // MARK: - Unknown ingredient

    @Test("Unknown ingredient is returned capitalized")
    func unknownIngredient() {
        #expect(IngredientNormalizer.normalize("xyzzy spice") == "Xyzzy Spice")
    }
}
