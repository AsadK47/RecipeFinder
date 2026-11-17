import Testing
import SwiftUI
import ViewInspector
@testable import RecipeFinder

/// Regression for the edit crash: after a recipe edit adds ingredients, SwiftUI renders the section with the new
/// recipe before `RecipeDetailView.onChange(of: recipe)` resizes `ingredientsState`, so rows must read it safely.
@MainActor
@Suite struct RecipeIngredientsSectionTests {

    private func make(ingredients: [Ingredient], state: [Bool],
                      onStartCooking: (() -> Void)? = nil) -> RecipeIngredientsSection {
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
            onEditIngredients: {},
            onStartCooking: onStartCooking
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

    private let scones = [
        Ingredient(baseQuantity: 200, unit: "g", name: "flour"),
        Ingredient(baseQuantity: 50, unit: "g", name: "butter"),
    ]

    @Test("Nothing ticked: no Got it group and no start-cooking prompt")
    func nothingTickedShowsPlainList() throws {
        let view = try make(ingredients: scones, state: [false, false], onStartCooking: {}).inspect()
        #expect(throws: (any Error).self) { try view.find(text: "Got it") }
        #expect(throws: (any Error).self) { try view.find(text: "All set — start cooking?") }
    }

    @Test("A ticked row shows under Got it")
    func tickedRowShowsGotIt() throws {
        let view = try make(ingredients: scones, state: [true, false], onStartCooking: {}).inspect()
        _ = try view.find(text: "Got it")
        #expect(throws: (any Error).self) { try view.find(text: "All set — start cooking?") }
    }

    @Test("Everything ticked offers cooking mode, and its button starts cooking")
    func allTickedOffersCooking() throws {
        var started = false
        let view = try make(ingredients: scones, state: [true, true], onStartCooking: { started = true }).inspect()
        _ = try view.find(text: "All set — start cooking?")
        try view.find(viewWithAccessibilityIdentifier: "recipe.ingredients.startCooking").find(ViewType.Button.self).tap()
        #expect(started)
    }

    @Test("Tapping a displayed row ticks that ingredient, not the one at that position in the recipe")
    func tappingRowTicks() throws {
        var toggled: [Int] = []
        let section = RecipeIngredientsSection(
            recipe: RecipeModel(name: "Scones", category: "Baking", difficulty: "Easy", prepTime: "10 minutes",
                                cookingTime: "20 minutes", baseServings: 4, ingredients: scones,
                                prePrepInstructions: [], instructions: ["Bake."], notes: ""),
            // Butter (index 1) is still to get, so it shows first; flour (index 0) sits in Got it below it.
            ingredientsState: [true, false], measurementSystem: .metric, isExpanded: true,
            onToggleSection: {}, onToggleMeasurement: {}, onToggleIngredient: { toggled.append($0) },
            onAddToShopping: { _ in }, onAddAllToShopping: {}, isInShoppingList: { _ in false },
            onEditIngredient: { _ in }, onSubstitute: nil, onEditIngredients: {}
        )
        let rows = try section.inspect().findAll(ViewType.Button.self, where: {
            try $0.accessibilityIdentifier() == "recipe.ingredient.row"
        })
        #expect(rows.count == 2)
        try #require(rows.count == 2)
        try rows[0].tap()
        #expect(toggled == [1])
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
        #expect(RecipeDetailCopy.factRows(count: count) == expected)
    }
}

/// Confetti + the success haptic fire once everything on the recipe is ticked — never for a recipe with no steps,
/// where ticking the ingredients alone would celebrate beside "start cooking?".
@Suite struct RecipeCompletionTests {
    @Test(arguments: [
        ([true, true], [Bool](), [true], true),
        ([true, false], [Bool](), [true], false),
        ([true], [false], [true], false),
        ([true], [Bool](), [false, true], false),
        ([true, true], [Bool](), [Bool](), false),   // no method steps: not "complete"
    ])
    func recipeComplete(ingredients: [Bool], prePrep: [Bool], instructions: [Bool], expected: Bool) {
        #expect(RecipeDetailView.isRecipeComplete(ingredients: ingredients, prePrep: prePrep,
                                                  instructions: instructions) == expected)
    }
}
