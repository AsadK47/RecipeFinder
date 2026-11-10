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

/// "Start from this text" when an import can't find a recipe: the cook keeps their text instead of hitting a dead end.
@Suite struct UnparsedTextPrefillTests {

    @Test("Name is the first non-empty line, trimmed")
    func nameFromFirstLine() {
        let prefill = RecipeWizardView.PrefilledRecipeData(unparsedText: "\n\n  Nan's Lemon Cake  \nzest 2 lemons\nbake")
        #expect(prefill.name == "Nan's Lemon Cake")
    }

    @Test("Full text is kept as notes and as the original source")
    func keepsFullText() {
        let text = "Lemon cake\nzest 2 lemons\nbake 40 min"
        let prefill = RecipeWizardView.PrefilledRecipeData(unparsedText: text)
        #expect(prefill.notes == text)
        #expect(prefill.sourceText == text)
    }

    @Test("Ingredients and steps start empty for the cook to fill")
    func leavesRowsEmpty() {
        let prefill = RecipeWizardView.PrefilledRecipeData(unparsedText: "Soup\nstuff")
        #expect(prefill.ingredients == nil)
        #expect(prefill.instructions == nil)
    }

    @Test("A very long first line is cut to a usable name")
    func capsLongName() {
        let prefill = RecipeWizardView.PrefilledRecipeData(unparsedText: String(repeating: "a", count: 300))
        #expect(prefill.name?.count == RecipeWizardView.PrefilledRecipeData.maxUnparsedNameLength)
    }

    @Test("Blank text gives no name and no source")
    func blankText() {
        let prefill = RecipeWizardView.PrefilledRecipeData(unparsedText: "  \n ")
        #expect(prefill.name == nil)
        #expect(prefill.sourceText == nil)
    }
}
