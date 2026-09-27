import Testing
import Foundation
@testable import RecipeFinder

/// Integration across the photo OCR → persistence seam: raw OCR text routes through the heuristic `TextRecipeParser` path, assembles via `RecipeWizardBuilder`, saves to in-memory Core Data, and fetches back preserving name, ingredients, and instructions.
@MainActor
@Suite struct PhotoOCRImportPersistenceTests {

    /// Simulates the on-device model being unavailable so the router always
    /// falls back to the heuristic text parser.
    private struct UnavailableStub: RecipeTextInterpreting {
        func interpret(_ text: String) async throws -> InterpretedRecipe? { nil }
    }

    private func makeController() -> PersistenceController {
        PersistenceController(inMemory: true, userID: { "test-user" })
    }

    /// Converts wizard prefill to a `RecipeModel` the same way the wizard view
    /// does when the user accepts the pre-populated fields and taps Save.
    private func buildRecipe(from prefill: RecipeWizardView.PrefilledRecipeData) -> RecipeModel {
        let items = (prefill.ingredients ?? []).map { line -> RecipeWizardView.IngredientItem in
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
            ingredientItems: items,
            prePrepSteps: [],
            mainInstructions: steps,
            notes: prefill.notes ?? "",
            imageReference: nil,
            isFavorite: false
        )
    }

    // MARK: - Full round-trip

    @Test func ocrText_parsesAndSavesToStore() async throws {
        let ocrText = """
        Scrambled Eggs
        Ingredients
        3 eggs
        1 tbsp butter
        pinch of salt
        Instructions
        Beat the eggs well.
        Melt butter in a pan on low heat.
        Add eggs and stir gently until just set.
        """
        let router = RecipeTextImportRouter(interpreter: UnavailableStub())
        let prefill = try #require(await router.prefill(for: ocrText))

        let controller = makeController()
        controller.saveRecipeModel(buildRecipe(from: prefill))

        let saved = try #require(controller.fetchRecipes().first)
        #expect(saved.name == "Scrambled Eggs")
        #expect(!saved.ingredients.isEmpty)
        #expect(!saved.instructions.isEmpty)
    }

    @Test func ocrText_ingredientNamesAreParsedCorrectly() async throws {
        let ocrText = """
        Garlic Pasta
        Ingredients
        200 g spaghetti
        3 cloves garlic
        2 tbsp olive oil
        Instructions
        Boil pasta until al dente.
        Fry garlic in olive oil.
        Toss together and serve.
        """
        let router = RecipeTextImportRouter(interpreter: UnavailableStub())
        let prefill = try #require(await router.prefill(for: ocrText))

        let controller = makeController()
        controller.saveRecipeModel(buildRecipe(from: prefill))

        let saved = try #require(controller.fetchRecipes().first)
        let names = Set(saved.ingredients.map { $0.name.lowercased() })
        #expect(names.contains("spaghetti"))
        #expect(names.contains("garlic"))
        #expect(names.contains("olive oil"))
    }

    @Test func ocrText_emptyOrGarbage_returnsNilPrefill() async {
        let router = RecipeTextImportRouter(interpreter: UnavailableStub())
        let prefill = await router.prefill(for: "xyzzy no recipe here")
        #expect(prefill == nil)
    }

    @Test func ocrText_savedRecipeSurvivesDeleteAndRefetch() async throws {
        let ocrText = """
        French Toast
        Ingredients
        2 slices bread
        1 egg
        1 tbsp milk
        Instructions
        Dip bread in egg mixture.
        Fry until golden.
        """
        let router = RecipeTextImportRouter(interpreter: UnavailableStub())
        let prefill = try #require(await router.prefill(for: ocrText))

        let controller = makeController()
        let recipe = buildRecipe(from: prefill)
        controller.saveRecipeModel(recipe)
        #expect(controller.fetchRecipes().count == 1)

        controller.deleteRecipe(withId: recipe.id)
        #expect(controller.fetchRecipes().isEmpty)
    }
}
