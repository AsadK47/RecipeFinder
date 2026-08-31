import Testing
import Foundation
@testable import RecipeFinder

@Suite("RecipeWizardBuilder")
struct RecipeWizardBuilderTests {

    // MARK: - normalizeDifficulty

    @Test(
        "Free-text difficulty maps onto the wizard's three levels",
        arguments: [
            ("easy", "Basic"),
            ("Beginner", "Basic"),
            ("basic", "Basic"),
            ("hard", "Expert"),
            ("Advanced", "Expert"),
            ("EXPERT", "Expert"),
            ("medium", "Intermediate"),
            ("", "Intermediate"),
            ("something odd", "Intermediate")
        ]
    )
    func normalizesDifficulty(input: String, expected: String) {
        #expect(RecipeWizardBuilder.normalizeDifficulty(input) == expected)
    }

    // MARK: - makeIngredients

    @Test("Blank-name rows are dropped and blank quantities default to 1.0")
    func mapsIngredientsDroppingBlankRows() {
        let items = [
            RecipeWizardView.IngredientItem(quantity: "2", unit: "cups", name: "flour"),
            RecipeWizardView.IngredientItem(quantity: "", unit: "", name: ""),
            RecipeWizardView.IngredientItem(quantity: "", unit: "pinch", name: "salt")
        ]

        let ingredients = RecipeWizardBuilder.makeIngredients(from: items)

        // `Ingredient` capitalizes names via its name formatter; assert the
        // formatted form so the test tracks the type's real behaviour.
        #expect(ingredients.count == 2)
        #expect(ingredients[0].name == "Flour")
        #expect(ingredients[0].baseQuantity == 2.0)
        #expect(ingredients[1].name == "Salt")
        #expect(ingredients[1].baseQuantity == 1.0)
    }

    // MARK: - validate

    @Test("A fully valid draft passes validation")
    func validatesGoodDraft() throws {
        try RecipeWizardBuilder.validate(
            name: "Pancakes",
            servings: 4,
            ingredientItems: [RecipeWizardView.IngredientItem(quantity: "2", unit: "cups", name: "flour")],
            mainInstructions: [EditableStep(text: "Mix and cook")]
        )
    }

    @Test("A short name is rejected")
    func rejectsShortName() {
        #expect(throws: (any Error).self) {
            try RecipeWizardBuilder.validate(
                name: "Ab",
                servings: 4,
                ingredientItems: [RecipeWizardView.IngredientItem(quantity: "2", unit: "cups", name: "flour")],
                mainInstructions: [EditableStep(text: "Mix and cook")]
            )
        }
    }

    @Test("Out-of-range servings are rejected")
    func rejectsBadServings() {
        #expect(throws: (any Error).self) {
            try RecipeWizardBuilder.validate(
                name: "Pancakes",
                servings: 0,
                ingredientItems: [RecipeWizardView.IngredientItem(quantity: "2", unit: "cups", name: "flour")],
                mainInstructions: [EditableStep(text: "Mix and cook")]
            )
        }
    }

    @Test("No ingredients throws the ingredient error with its original wording")
    func rejectsMissingIngredients() {
        #expect(throws: RecipeWizardBuilder.BuilderError.missingIngredients) {
            try RecipeWizardBuilder.validate(
                name: "Pancakes",
                servings: 4,
                ingredientItems: [RecipeWizardView.IngredientItem(quantity: "", unit: "", name: "")],
                mainInstructions: [EditableStep(text: "Mix and cook")]
            )
        }
        #expect(RecipeWizardBuilder.BuilderError.missingIngredients.errorDescription == "Please add at least one ingredient")
    }

    @Test("No cooking instructions throws the instruction error with its original wording")
    func rejectsMissingInstructions() {
        #expect(throws: RecipeWizardBuilder.BuilderError.missingInstructions) {
            try RecipeWizardBuilder.validate(
                name: "Pancakes",
                servings: 4,
                ingredientItems: [RecipeWizardView.IngredientItem(quantity: "2", unit: "cups", name: "flour")],
                mainInstructions: [EditableStep(text: "   ")]
            )
        }
        #expect(RecipeWizardBuilder.BuilderError.missingInstructions.errorDescription == "Please add at least one cooking instruction")
    }

    // MARK: - assemble

    @Test("Assembling formats times, carries servings, and drops blank steps")
    func assemblesRecipe() {
        let id = UUID()
        let recipe = RecipeWizardBuilder.assemble(
            recipeId: id,
            name: "Pancakes",
            category: "Breakfast",
            difficulty: "Basic",
            prepTime: 10,
            cookTime: 20,
            servings: 3,
            ingredientItems: [RecipeWizardView.IngredientItem(quantity: "2", unit: "cups", name: "flour")],
            prePrepSteps: [EditableStep(text: "Sift flour"), EditableStep(text: "  ")],
            mainInstructions: [EditableStep(text: "Mix"), EditableStep(text: "Cook")],
            notes: "Serve warm",
            imageReference: "/tmp/img.jpg",
            isFavorite: true
        )

        #expect(recipe.id == id)
        #expect(recipe.name == "Pancakes")
        #expect(recipe.category == "Breakfast")
        #expect(recipe.prepTime == "10 minutes")
        #expect(recipe.cookingTime == "20 minutes")
        #expect(recipe.baseServings == 3)
        #expect(recipe.currentServings == 3)
        #expect(recipe.ingredients.count == 1)
        #expect(recipe.prePrepInstructions == ["Sift flour"])
        #expect(recipe.instructions == ["Mix", "Cook"])
        #expect(recipe.notes == "Serve warm")
        #expect(recipe.imageName == "/tmp/img.jpg")
        #expect(recipe.isFavorite == true)
    }
}
