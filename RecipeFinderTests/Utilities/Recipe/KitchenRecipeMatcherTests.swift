import Testing
import Foundation
@testable import RecipeFinder

@Suite("KitchenRecipeMatcher")
struct KitchenRecipeMatcherTests {

    // MARK: - Fixtures

    private func ingredient(_ name: String) -> Ingredient {
        Ingredient(baseQuantity: 1.0, unit: "", name: name)
    }

    private func recipe(_ ingredientNames: [String]) -> RecipeModel {
        RecipeModel(
            name: "Test Recipe",
            category: "Test",
            difficulty: "Easy",
            prepTime: "10 min",
            cookingTime: "20 min",
            baseServings: 4,
            currentServings: 4,
            ingredients: ingredientNames.map(ingredient),
            prePrepInstructions: [],
            instructions: [],
            notes: ""
        )
    }

    // MARK: - normalizedTerm

    @Test(
        "Normalises to the lowercased main ingredient term",
        arguments: [
            ("Chicken Breast", "chicken breast"),
            ("Onion, diced", "onion"),
            ("Garlic", "garlic")
        ]
    )
    func normalizesTerm(input: String, expected: String) {
        #expect(KitchenRecipeMatcher.normalizedTerm(input) == expected)
    }

    // MARK: - ingredientMatches

    @Test("Exact terms match")
    func exactMatch() {
        #expect(KitchenRecipeMatcher.ingredientMatches("garlic", "garlic"))
    }

    @Test("A longer term matches when it contains the other (both ≥ 3 chars)")
    func substringMatch() {
        #expect(KitchenRecipeMatcher.ingredientMatches("chicken breast", "chicken"))
        #expect(KitchenRecipeMatcher.ingredientMatches("rice", "ice"))
    }

    @Test("Terms shorter than 3 characters only match exactly")
    func shortTermsDoNotSubstringMatch() {
        #expect(!KitchenRecipeMatcher.ingredientMatches("b", "butter"))
    }

    // MARK: - matchCount

    @Test("Counts recipe ingredients matching the kitchen set")
    func countsMatches() {
        let r = recipe(["Chicken Breast", "Garlic", "Onion"])
        #expect(KitchenRecipeMatcher.matchCount(recipe: r, kitchenIngredients: ["garlic", "chicken"]) == 2)
    }

    // MARK: - quickMatches

    @Test("Returns only recipes sharing an ingredient, ranked by match count")
    func ranksBySharedIngredients() {
        let a = recipe(["Chicken Breast", "Garlic", "Onion"])   // 2 matches
        let b = recipe(["Salmon", "Lemon"])                      // 0 matches
        let c = recipe(["Garlic", "Butter", "Flour"])           // 1 match

        let result = KitchenRecipeMatcher.quickMatches(
            recipes: [b, c, a],
            kitchenItemNames: ["Garlic", "Chicken"]
        )

        #expect(result.map { $0.id } == [a.id, c.id])
    }

    @Test("An empty kitchen yields no matches")
    func emptyKitchenYieldsNothing() {
        let a = recipe(["Garlic"])
        #expect(KitchenRecipeMatcher.quickMatches(recipes: [a], kitchenItemNames: []).isEmpty)
    }
}
