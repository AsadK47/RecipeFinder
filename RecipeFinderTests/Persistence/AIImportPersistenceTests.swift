import Testing
import Foundation
@testable import RecipeFinder

/// Integration across the AI import → persistence seam: an `InterpretedRecipe` maps to wizard prefill, assembles via `RecipeWizardBuilder`, saves to Core Data, and fetches back with no field lost.
@MainActor
@Suite struct AIImportPersistenceTests {

    private func makeController() -> PersistenceController {
        PersistenceController(inMemory: true, userID: { "test-user" })
    }

    /// Mirrors the wizard's accept-prefill path: parse ingredients into `IngredientItem`s, wrap instructions as `EditableStep`s, then `RecipeWizardBuilder.assemble`.
    private func buildRecipe(from prefill: RecipeWizardView.PrefilledRecipeData) -> RecipeModel {
        let ingredientItems = (prefill.ingredients ?? []).map { line in
            let p = WizardIngredientParser.parse(line)
            return RecipeWizardView.IngredientItem(quantity: p.quantity, unit: p.unit, name: p.name)
        }
        let steps = (prefill.instructions ?? []).map { EditableStep(text: $0) }
        return RecipeWizardBuilder.assemble(
            recipeId: UUID(),
            name: prefill.name ?? "Imported Recipe",
            category: prefill.category ?? "Main",
            difficulty: prefill.difficulty.map { RecipeWizardBuilder.normalizeDifficulty($0) } ?? "Basic",
            prepTime: prefill.prepTime ?? 0,
            cookTime: prefill.cookTime ?? 0,
            servings: prefill.servings ?? 2,
            ingredientItems: ingredientItems,
            prePrepSteps: [],
            mainInstructions: steps,
            notes: prefill.notes ?? "",
            imageReference: nil,
            isFavorite: false
        )
    }

    // MARK: - Full round-trip

    @Test func fullRoundTrip_savesAndReloadsAllCoreFields() throws {
        let interpreted = InterpretedRecipe(
            name: "Tomato Soup",
            ingredients: ["400 g tomatoes", "1 onion", "500 ml stock"],
            steps: ["Sauté the onion", "Add tomatoes and stock", "Simmer 20 min", "Blend"],
            prepMinutes: 10, cookMinutes: 25, servings: 4,
            summary: "A warming weekday soup"
        )
        let prefill = RecipeWizardView.PrefilledRecipeData(interpreted: interpreted)
        let controller = makeController()

        controller.saveRecipeModel(buildRecipe(from: prefill))

        let saved = try #require(controller.fetchRecipes().first)
        #expect(saved.name == "Tomato Soup")
        #expect(saved.ingredients.count == 3)
        #expect(saved.instructions.count == 4)
        #expect(saved.baseServings == 4)
        #expect(saved.prepTime == "10 minutes")
        #expect(saved.cookingTime == "25 minutes")
        #expect(saved.notes == "A warming weekday soup")
    }

    @Test func roundTrip_blankSummary_storesEmptyNotes() throws {
        let interpreted = InterpretedRecipe(
            name: "Plain Omelette",
            ingredients: ["3 eggs", "1 tbsp butter"],
            steps: ["Beat eggs", "Melt butter", "Cook omelette"],
            prepMinutes: nil, cookMinutes: nil, servings: nil, summary: "   "
        )
        let prefill = RecipeWizardView.PrefilledRecipeData(interpreted: interpreted)
        let controller = makeController()

        controller.saveRecipeModel(buildRecipe(from: prefill))

        let saved = try #require(controller.fetchRecipes().first)
        #expect(saved.notes.isEmpty)
        #expect(saved.baseServings == 2)     // falls back to default
        #expect(saved.prepTime == "0 minutes")
        #expect(saved.cookingTime == "0 minutes")
    }

    @Test func roundTrip_ingredientsAreCorrectlyParsed() throws {
        let interpreted = InterpretedRecipe(
            name: "Garlic Pasta",
            ingredients: ["200 g spaghetti", "3 cloves garlic", "2 tbsp olive oil"],
            steps: ["Boil pasta", "Fry garlic", "Toss together"],
            prepMinutes: 5, cookMinutes: 15, servings: 2, summary: nil
        )
        let controller = makeController()
        controller.saveRecipeModel(buildRecipe(from: RecipeWizardView.PrefilledRecipeData(interpreted: interpreted)))

        let saved = try #require(controller.fetchRecipes().first)
        let names = Set(saved.ingredients.map { $0.name.lowercased() })
        #expect(names.contains("spaghetti"))
        #expect(names.contains("garlic"))
        #expect(names.contains("olive oil"))
    }

    @Test func roundTrip_blankIngredientLinesAreFiltered() throws {
        let interpreted = InterpretedRecipe(
            name: "Simple Salad",
            ingredients: ["100 g lettuce", "   ", ""],
            steps: ["Toss"],
            prepMinutes: nil, cookMinutes: nil, servings: nil, summary: nil
        )
        let controller = makeController()
        controller.saveRecipeModel(buildRecipe(from: RecipeWizardView.PrefilledRecipeData(interpreted: interpreted)))

        let saved = try #require(controller.fetchRecipes().first)
        #expect(saved.ingredients.count == 1)
    }
}
