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
        #expect(recipe.tags.isEmpty)
    }

    @Test("Tags are carried through to the assembled recipe", arguments: [
        (["spicy", "quick"], ["spicy", "quick"]),
        ([], []),
        (["Comfort Food"], ["Comfort Food"])
    ] as [([String], [String])])
    func assemblesWithTags(tags: [String], expected: [String]) {
        let recipe = RecipeWizardBuilder.assemble(
            recipeId: UUID(),
            name: "Pasta",
            category: "Main",
            difficulty: "Basic",
            prepTime: 5,
            cookTime: 15,
            servings: 2,
            ingredientItems: [RecipeWizardView.IngredientItem(quantity: "200", unit: "g", name: "pasta")],
            prePrepSteps: [],
            mainInstructions: [EditableStep(text: "Boil and serve")],
            notes: "",
            imageReference: nil,
            isFavorite: false,
            tags: tags
        )
        #expect(recipe.tags == expected)
    }

    @Test("Editing keeps fields the wizard doesn't edit: sample flag, rating, dietary info, cook history")
    func mergeEditPreservesUneditedFields() {
        var stored = RecipeModel(name: "Tandoori Chicken", category: "Main", difficulty: "Medium",
                                 prepTime: "10 minutes", cookingTime: "30 minutes", baseServings: 4,
                                 ingredients: [], prePrepInstructions: [], instructions: ["Grill."],
                                 notes: "https://example.com/tandoori", isSampleRecipe: true,
                                 cookCount: 3, lastCookedAt: Date(timeIntervalSince1970: 1_000), rating: 4)
        stored.dietaryInfo.isGlutenFree = true

        // What the wizard hands back: its own fields edited, everything else at defaults.
        let edited = RecipeModel(id: stored.id, name: "Tandoori Chicken (mine)", category: "Main",
                                 difficulty: "Intermediate", prepTime: "15 minutes", cookingTime: "30 minutes",
                                 baseServings: 2, ingredients: [], prePrepInstructions: [],
                                 instructions: ["Marinate.", "Grill."], notes: stored.notes)

        let merged = RecipeWizardBuilder.mergeEdit(edited, onto: stored)

        #expect(merged.name == "Tandoori Chicken (mine)")
        #expect(merged.instructions == ["Marinate.", "Grill."])
        #expect(merged.isSampleRecipe)
        #expect(merged.rating == 4)
        #expect(merged.dietaryInfo.isGlutenFree)
        #expect(merged.cookCount == 3)
        #expect(merged.lastCookedAt == stored.lastCookedAt)
        // Regression: an edited bundled recipe must not start re-checking its source site.
        #expect(!merged.shouldAutoRefreshFromSource)
    }

    @Test("Fraction quantities parse instead of silently saving as 1", arguments: [
        ("1/2", 0.5), ("1 1/2", 1.5), ("⅓", 1.0 / 3.0), ("0.44", 0.44), ("", 1.0),
    ])
    func parsesFractionQuantities(text: String, expected: Double) {
        let item = RecipeWizardView.IngredientItem(quantity: text, unit: "cup", name: "flour")
        let quantity = RecipeWizardBuilder.makeIngredients(from: [item]).first?.baseQuantity ?? -1
        #expect(abs(quantity - expected) < 0.0001)
    }

    @Test("Edit round-trip: a ⅓ cup ingredient keeps its amount through the editor")
    func fractionRoundTripsThroughEditor() {
        let line = "\(FractionFormatter.format(1.0 / 3.0)) cup sugar"
        let parsed = WizardIngredientParser.parse(line)
        let item = RecipeWizardView.IngredientItem(quantity: parsed.quantity, unit: parsed.unit, name: parsed.name)
        let quantity = RecipeWizardBuilder.makeIngredients(from: [item]).first?.baseQuantity ?? -1
        #expect(abs(quantity - 1.0 / 3.0) < 0.0001)
    }

    @Test("Editor prefill from a recipe keeps its fields (shared by Edit and URL-import review)")
    func prefillFromRecipe() {
        let recipe = RecipeModel(name: "Scones", category: "Baking", difficulty: "Basic", prepTime: "0 minutes",
                                 cookingTime: "20 minutes", baseServings: 6,
                                 ingredients: [Ingredient(baseQuantity: 1.0 / 3.0, unit: "cup", name: "sugar")],
                                 prePrepInstructions: [], instructions: ["Bake."],
                                 notes: "https://example.com/scones", imageName: "https://example.com/scones.jpg")
        let prefill = RecipeWizardView.PrefilledRecipeData(recipe: recipe)
        #expect(prefill.name == "Scones")
        #expect(prefill.prepTime == 0)          // unknown stays unknown — no invented 15 min
        #expect(prefill.cookTime == 20)
        #expect(prefill.servings == 6)
        #expect(prefill.imageURL == "https://example.com/scones.jpg")
        #expect(prefill.ingredients?.first?.hasPrefix(FractionFormatter.format(1.0 / 3.0)) == true)
    }
}
