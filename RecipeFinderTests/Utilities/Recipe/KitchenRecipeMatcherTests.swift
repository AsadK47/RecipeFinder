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

    @Test("A shared whole word matches (multi-word ingredient vs its main term)")
    func sharedWholeWordMatches() {
        #expect(KitchenRecipeMatcher.ingredientMatches("chicken breast", "chicken"))
        #expect(KitchenRecipeMatcher.ingredientMatches("olive oil", "oil"))
    }

    @Test("A short term is not matched as a substring of a longer word")
    func substringOfLongerWordDoesNotMatch() {
        // The reported bug: adding "gin" should not match "ginger" recipes.
        #expect(!KitchenRecipeMatcher.ingredientMatches("ginger", "gin"))
        #expect(!KitchenRecipeMatcher.ingredientMatches("rice", "ice"))
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

    @Test("Prepared terms match exactly like raw terms")
    func preparedTermsMatchLikeRawTerms() {
        let terms = ["rice", "ice", "egg", "eggs", "tomatoes", "tomato", "gin", "ginger", "red onion", "onion",
                     "berries", "berry", "chicken breast", "breast"]
        for a in terms {
            for b in terms {
                let prepared = KitchenRecipeMatcher.ingredientMatches(
                    KitchenRecipeMatcher.MatchTerm(a), KitchenRecipeMatcher.MatchTerm(b))
                #expect(prepared == KitchenRecipeMatcher.ingredientMatches(a, b), "\(a) vs \(b)")
            }
        }
    }

    @Test func aCachedMatchTermMatchesLikeAFreshOne() {
        let fresh = KitchenRecipeMatcher.MatchTerm(KitchenRecipeMatcher.normalizedTerm("2 large eggs"))
        let cached = KitchenRecipeMatcher.matchTerm("2 large eggs")
        #expect(cached?.term == fresh.term)
        #expect(cached?.words == fresh.words)
        #expect(KitchenRecipeMatcher.matchTerm("   ") == nil)
    }

    @Test func aPreparedPantryFindsTheSameMissingIngredients() {
        let recipe = RecipeModel(
            name: "Omelette", category: "Breakfast", difficulty: "Basic", prepTime: "5 min", cookingTime: "5 min",
            baseServings: 1,
            ingredients: ["eggs", "cheddar cheese", "chives"].map { Ingredient(baseQuantity: 1, unit: "", name: $0) },
            prePrepInstructions: [], instructions: ["Cook"], notes: ""
        )
        let pantry: Set<String> = ["egg", "cheese"]
        let prepared = recipe.missingIngredients(fromPrepared: RecipeModel.normalizedPantry(pantry)).map(\.name)
        #expect(prepared == recipe.missingIngredients(from: pantry).map(\.name))
        #expect(prepared.map { $0.lowercased() } == ["chives"])
    }
}
