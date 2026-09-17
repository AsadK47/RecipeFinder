import Testing
import Foundation
@testable import RecipeFinder

@Suite struct RecipeDiffTests {
    private func recipe(
        name: String = "Test Recipe",
        ingredients: [Ingredient] = [],
        instructions: [String] = [],
        prepTime: String = "10 minutes",
        cookingTime: String = "20 minutes",
        difficulty: String = "Easy",
        category: String = "Main",
        cuisine: String? = nil,
        imageName: String? = nil
    ) -> RecipeModel {
        RecipeModel(
            name: name,
            category: category,
            difficulty: difficulty,
            prepTime: prepTime,
            cookingTime: cookingTime,
            baseServings: 4,
            ingredients: ingredients,
            prePrepInstructions: [],
            instructions: instructions,
            notes: "https://example.com"
        )
    }

    private func ingredient(_ name: String, qty: Double = 1, unit: String = "") -> Ingredient {
        Ingredient(baseQuantity: qty, unit: unit, name: name)
    }

    // MARK: - Compute

    @Test func noChangesWhenRecipesAreIdentical() {
        let r = recipe()
        let diff = RecipeDiff.compute(stored: r, upstream: r)
        #expect(!diff.hasChanges)
        #expect(diff.changed.isEmpty)
    }

    @Test func detectsNameChange() {
        let diff = RecipeDiff.compute(stored: recipe(name: "Old"), upstream: recipe(name: "New"))
        #expect(diff.changed == [.name])
    }

    @Test func detectsIngredientCountChange() {
        let stored   = recipe(ingredients: [ingredient("flour")])
        let upstream = recipe(ingredients: [ingredient("flour"), ingredient("water")])
        let diff = RecipeDiff.compute(stored: stored, upstream: upstream)
        #expect(diff.changed.contains(.ingredients))
    }

    @Test func sameIngredientContentNotFlaggedChanged() {
        // New UUIDs but identical content — should NOT appear in the changeset.
        let a = Ingredient(baseQuantity: 1, unit: "cup", name: "flour")
        let b = Ingredient(baseQuantity: 1, unit: "cup", name: "flour")
        let diff = RecipeDiff.compute(
            stored:   recipe(ingredients: [a]),
            upstream: recipe(ingredients: [b])
        )
        #expect(!diff.changed.contains(.ingredients))
    }

    @Test func detectsInstructionChange() {
        let diff = RecipeDiff.compute(
            stored:   recipe(instructions: ["Step 1"]),
            upstream: recipe(instructions: ["Step 1", "Step 2"])
        )
        #expect(diff.changed.contains(.instructions))
    }

    @Test func detectsPrepTimeChange() {
        let diff = RecipeDiff.compute(stored: recipe(prepTime: "5 minutes"), upstream: recipe(prepTime: "15 minutes"))
        #expect(diff.changed.contains(.prepTime))
    }

    @Test func detectsCookingTimeChange() {
        let diff = RecipeDiff.compute(stored: recipe(cookingTime: "20 min"), upstream: recipe(cookingTime: "40 min"))
        #expect(diff.changed.contains(.cookingTime))
    }

    @Test func detectsDifficultyChange() {
        let diff = RecipeDiff.compute(stored: recipe(difficulty: "Easy"), upstream: recipe(difficulty: "Hard"))
        #expect(diff.changed.contains(.difficulty))
    }

    @Test func detectsCategoryChange() {
        let diff = RecipeDiff.compute(stored: recipe(category: "Main"), upstream: recipe(category: "Dessert"))
        #expect(diff.changed.contains(.category))
    }

    // MARK: - Apply

    @Test func applyingNameSelectionReplacesName() {
        let stored   = recipe(name: "Old Name")
        let upstream = recipe(name: "New Name")
        let diff = RecipeDiff.compute(stored: stored, upstream: upstream)
        let result = diff.applying(selections: [.name])
        #expect(result.name == "New Name")
    }

    @Test func applyingEmptySelectionChangesNothing() {
        let stored   = recipe(name: "Old Name")
        let upstream = recipe(name: "New Name")
        let diff = RecipeDiff.compute(stored: stored, upstream: upstream)
        #expect(diff.applying(selections: []).name == "Old Name")
    }

    @Test func applyingPreservesStoredId() {
        let stored   = recipe(name: "Old")
        let upstream = recipe(name: "New")
        let diff = RecipeDiff.compute(stored: stored, upstream: upstream)
        #expect(diff.applying(selections: [.name]).id == stored.id)
    }

    @Test func applyingPreservesPersonalData() {
        var stored = recipe(name: "Old Name")
        stored.rating = 4
        stored.tags = ["vegan", "quick"]
        let upstream = recipe(name: "New Name")
        let diff = RecipeDiff.compute(stored: stored, upstream: upstream)
        let result = diff.applying(selections: [.name])
        #expect(result.name == "New Name")
        #expect(result.rating == 4)
        #expect(result.tags == ["vegan", "quick"])
        #expect(result.notes == stored.notes)
    }

    @Test func applyingIngredientsSwapsFullList() {
        let oldIngredients = [ingredient("flour", qty: 1, unit: "cup")]
        let newIngredients = [ingredient("flour", qty: 2, unit: "cups"), ingredient("sugar", qty: 1, unit: "tbsp")]
        let stored   = recipe(ingredients: oldIngredients)
        let upstream = recipe(ingredients: newIngredients)
        let diff = RecipeDiff.compute(stored: stored, upstream: upstream)
        let result = diff.applying(selections: [.ingredients])
        #expect(result.ingredients.count == 2)
    }
}
