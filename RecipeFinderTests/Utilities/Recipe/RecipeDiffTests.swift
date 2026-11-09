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

    // MARK: - Re-import from original (Import 1/5)

    private func prefill(
        name: String? = "Test Recipe", ingredients: [String]? = nil, instructions: [String]? = nil,
        prepTime: Int? = nil, cookTime: Int? = nil
    ) -> RecipeWizardView.PrefilledRecipeData {
        RecipeWizardView.PrefilledRecipeData(
            name: name, description: nil, ingredients: ingredients, instructions: instructions,
            prepTime: prepTime, cookTime: cookTime, servings: nil, difficulty: nil, notes: nil,
            category: nil, isFavorite: nil, imageURL: nil
        )
    }

    @Test func reimportProposesOnlyTheFieldsTheNewParseChanged() {
        let stored = recipe(ingredients: [Ingredient(baseQuantity: 1, unit: "", name: "Fry the onions")],
                            instructions: ["Fry the onions"])
        let diff = RecipeDiff.reimport(stored: stored, prefill: prefill(ingredients: ["1 onion"], instructions: ["Fry the onions"]))
        #expect(diff.changed == [.ingredients])
        #expect(diff.upstream.ingredients.first?.name == "Onion")
    }

    @Test func reimportNeverProposesBlankingFieldsTheParseMissed() {
        let stored = recipe(ingredients: [Ingredient(baseQuantity: 1, unit: "", name: "onion")], instructions: ["Fry."])
        let diff = RecipeDiff.reimport(stored: stored, prefill: prefill(name: nil, prepTime: 0))
        #expect(!diff.hasChanges)
    }

    @Test func reimportKeepsPersonalDataWhenApplied() {
        var stored = recipe(instructions: ["Old step"])
        stored.rating = 5
        stored.sourceText = "the original"
        let applied = RecipeDiff.reimport(stored: stored, prefill: prefill(instructions: ["New step"]))
            .applying(selections: [.instructions])
        #expect(applied.instructions == ["New step"])
        #expect(applied.rating == 5)
        #expect(applied.notes == stored.notes)
        #expect(applied.sourceText == "the original")
    }

    private struct DecliningInterpreter: RecipeTextInterpreting {
        func interpret(_ text: String) async throws -> InterpretedRecipe? { nil }
    }

    @MainActor
    @Test func routerOutputOnTheOriginalTextFeedsTheDiff() async throws {
        let original = "Tomato Soup\nIngredients\n2 tomatoes\n1 onion\nMethod\nSimmer everything for 20 minutes"
        let stored = recipe(name: "Tomato Soup", instructions: ["Simmer everything for 20 minutes"])
        let parsed = try #require(await RecipeTextImportRouter(interpreter: DecliningInterpreter()).prefill(for: original))
        let diff = RecipeDiff.reimport(stored: stored, prefill: parsed)
        #expect(diff.changed.contains(.ingredients))
        #expect(!diff.changed.contains(.name))
    }
}
