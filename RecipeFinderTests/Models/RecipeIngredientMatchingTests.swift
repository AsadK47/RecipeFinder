import Testing
import Foundation
@testable import RecipeFinder

/// Word-boundary correctness for the "what can I make?" matching. These pin the
/// bug that naïve substring matching caused: short pantry terms matching inside
/// unrelated longer words ("ice" in "rice", "gin" in "ginger").
@Suite("RecipeModel ingredient matching")
struct RecipeIngredientMatchingTests {

    private func recipe(_ ingredientNames: [String]) -> RecipeModel {
        RecipeModel(
            name: "R",
            category: "Main",
            difficulty: "Basic",
            prepTime: "10 min",
            cookingTime: "20 min",
            baseServings: 4,
            ingredients: ingredientNames.map { Ingredient(baseQuantity: 1, unit: "cup", name: $0) },
            prePrepInstructions: [],
            instructions: [],
            notes: "",
            isFavorite: false,
            tags: [],
            dietaryInfo: DietaryInfo()
        )
    }

    @Test("Exact pantry term matches", arguments: [
        (["Garlic"], ["garlic"], 1.0),
        (["Garlic", "Onion"], ["garlic"], 0.5),
        (["Garlic", "Onion"], ["garlic", "onion"], 1.0),
        (["Chicken Breast"], ["chicken"], 1.0),
        // Singular/plural should match either direction.
        (["Eggs"], ["egg"], 1.0),
        (["Egg"], ["eggs"], 1.0),
        (["Tomatoes"], ["tomato"], 1.0),
        (["Carrots", "Onions"], ["carrot", "onion"], 1.0)
    ])
    func matchesLegitimateIngredients(recipeIngredients: [String], pantry: [String], expected: Double) {
        let pct = recipe(recipeIngredients).ingredientMatchPercentage(availableIngredients: Set(pantry))
        #expect(abs(pct - expected) < 0.001)
    }

    @Test("Short pantry term does not match inside a longer word", arguments: [
        (["Rice"], ["ice"]),
        (["Ginger"], ["gin"]),
        (["Boiling Water"], ["oil"]),
        (["Spinach"], ["pin"])
    ])
    func rejectsSubstringFalsePositives(recipeIngredients: [String], pantry: [String]) {
        let pct = recipe(recipeIngredients).ingredientMatchPercentage(availableIngredients: Set(pantry))
        #expect(pct == 0.0)
    }

    @Test("Missing ingredients respect word boundaries")
    func missingIngredients_wordBoundary() {
        // Pantry has "ice"; the recipe needs "Rice" — it must still be reported missing.
        let missing = recipe(["Rice", "Garlic"]).missingIngredients(from: ["ice", "garlic"])
        #expect(missing.map(\.name) == ["Rice"])
    }
}
