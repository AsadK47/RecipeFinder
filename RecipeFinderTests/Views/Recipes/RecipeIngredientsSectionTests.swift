import Testing
import SwiftUI
import ViewInspector
@testable import RecipeFinder

/// Regression for the edit crash: after a recipe edit adds ingredients, SwiftUI renders the section with the new
/// recipe before `RecipeDetailView.onChange(of: recipe)` resizes `ingredientsState`, so rows must read it safely.
@MainActor
@Suite struct RecipeIngredientsSectionTests {

    private func make(ingredients: [Ingredient], state: [Bool]) -> RecipeIngredientsSection {
        RecipeIngredientsSection(
            recipe: RecipeModel(name: "Scones", category: "Baking", difficulty: "Easy", prepTime: "10 minutes",
                                cookingTime: "20 minutes", baseServings: 4, ingredients: ingredients,
                                prePrepInstructions: [], instructions: ["Bake."], notes: ""),
            ingredientsState: state,
            measurementSystem: .metric,
            isExpanded: true,
            onToggleSection: {},
            onToggleMeasurement: {},
            onToggleIngredient: { _ in },
            onAddToShopping: { _ in },
            onAddAllToShopping: {},
            isInShoppingList: { _ in false },
            onEditIngredient: { _ in },
            onSubstitute: nil,
            onEditIngredients: {}
        )
    }

    @Test("Renders every ingredient when the checked-state array is shorter (post-edit frame) instead of crashing")
    func rendersWithStaleShorterState() throws {
        let ingredients = [
            Ingredient(baseQuantity: 200, unit: "g", name: "flour"),
            Ingredient(baseQuantity: 2, unit: "tsp", name: "matcha"),
            Ingredient(baseQuantity: 50, unit: "g", name: "butter"),
        ]
        let view = try make(ingredients: ingredients, state: [false]).inspect()
        _ = try view.find(text: "Butter")
    }
}

/// Recipe detail facts card: when values are too long for one row, they split into two balanced rows.
@MainActor @Suite struct RecipeFactRowsTests {
    @Test(arguments: [
        (4, [[0, 1], [2, 3]]),
        (5, [[0, 1, 2], [3, 4]]),
        (1, [[0]]),
        (0, []),
    ])
    func factsSplitIntoTwoBalancedRows(count: Int, expected: [[Int]]) {
        #expect(RecipeDetailView.factRows(count: count) == expected)
    }
}
