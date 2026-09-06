import Testing
import Foundation
@testable import RecipeFinder

/// The `InterpretedRecipe` → wizard-prefill mapping that seeds the review step
/// for AI/text/photo imports.
@Suite struct PrefilledRecipeDataMappingTests {

    @Test func mapsCoreFields() {
        let interpreted = InterpretedRecipe(
            name: "Tomato Soup",
            ingredients: ["400 g tomatoes", "1 onion"],
            steps: ["Simmer", "Blend"],
            prepMinutes: 10, cookMinutes: 20, servings: 4, summary: "Cosy soup"
        )
        let prefill = RecipeWizardView.PrefilledRecipeData(interpreted: interpreted)

        #expect(prefill.name == "Tomato Soup")
        #expect(prefill.ingredients == ["400 g tomatoes", "1 onion"])
        #expect(prefill.instructions == ["Simmer", "Blend"])
        #expect(prefill.prepTime == 10)
        #expect(prefill.cookTime == 20)
        #expect(prefill.servings == 4)
        #expect(prefill.notes == "Cosy soup")
        // Free text rarely states these reliably — left for the user.
        #expect(prefill.category == nil)
        #expect(prefill.difficulty == nil)
    }

    @Test func filtersBlankLinesAndSummary() {
        let interpreted = InterpretedRecipe(
            name: "Bread",
            ingredients: ["flour", "   ", ""],
            steps: ["Mix", "  "],
            prepMinutes: nil, cookMinutes: nil, servings: nil, summary: "   "
        )
        let prefill = RecipeWizardView.PrefilledRecipeData(interpreted: interpreted)

        #expect(prefill.ingredients == ["flour"])
        #expect(prefill.instructions == ["Mix"])
        #expect(prefill.servings == nil)
        #expect(prefill.notes == nil)
    }
}
