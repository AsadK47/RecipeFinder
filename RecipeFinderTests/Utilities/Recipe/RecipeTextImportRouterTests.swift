import Testing
import Foundation
@testable import RecipeFinder

/// The shared text→prefill routing used by the paste-text, photo, and share
/// entry points. Interpreter injected so no model or network is touched.
@MainActor
@Suite struct RecipeTextImportRouterTests {

    struct StubInterpreter: RecipeTextInterpreting {
        var recipe: InterpretedRecipe?
        func interpret(_ text: String) async throws -> InterpretedRecipe? { recipe }
    }

    @Test func usesInterpreterWhenItSucceeds() async {
        let sample = InterpretedRecipe(name: "Tomato Soup", ingredients: ["1 onion"], steps: ["Simmer"],
                                       prepMinutes: nil, cookMinutes: nil, servings: 2, summary: nil)
        let router = RecipeTextImportRouter(interpreter: StubInterpreter(recipe: sample))

        let prefill = await router.prefill(for: "anything")
        #expect(prefill?.name == "Tomato Soup")
        #expect(prefill?.servings == 2)
    }

    @Test func fallsBackToTextParserWhenInterpreterDeclines() async {
        let caption = """
        Tomato Soup
        Ingredients
        2 tomatoes
        1 onion
        Method
        Simmer everything for 20 minutes
        """
        let router = RecipeTextImportRouter(interpreter: StubInterpreter(recipe: nil))

        let prefill = await router.prefill(for: caption)
        #expect(prefill?.name == "Tomato Soup")
        #expect(prefill?.ingredients?.isEmpty == false)
        #expect(prefill?.instructions?.isEmpty == false)
    }

    @Test func returnsNilWhenNothingParseable() async {
        let router = RecipeTextImportRouter(interpreter: StubInterpreter(recipe: nil))
        #expect((await router.prefill(for: "hi")) == nil)
    }

    // MARK: - Original text kept for re-import (Import 1/5)

    @Test func interpretedPrefillKeepsTheOriginalText() async {
        let sample = InterpretedRecipe(name: "Tomato Soup", ingredients: ["1 onion"], steps: ["Simmer"],
                                       prepMinutes: nil, cookMinutes: nil, servings: 2, summary: nil)
        let router = RecipeTextImportRouter(interpreter: StubInterpreter(recipe: sample))
        let prefill = await router.prefill(for: "Tomato Soup — the pasted caption")
        #expect(prefill?.sourceText == "Tomato Soup — the pasted caption")
    }

    @Test func parsedPrefillKeepsTheOriginalText() async {
        let caption = "Tomato Soup\nIngredients\n2 tomatoes\n1 onion\nMethod\nSimmer everything for 20 minutes"
        let router = RecipeTextImportRouter(interpreter: StubInterpreter(recipe: nil))
        let prefill = await router.prefill(for: caption)
        #expect(prefill?.sourceText == caption)
    }
}
