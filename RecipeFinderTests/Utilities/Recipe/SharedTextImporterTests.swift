import Testing
import Foundation
@testable import RecipeFinder

/// Tests the free-text import decision + mapping without the on-device model,
/// by injecting a stub interpreter.
@Suite struct SharedTextImporterTests {

    struct DummyError: Error {}

    /// Sendable stub: returns a canned recipe, nil, or throws.
    struct StubInterpreter: RecipeTextInterpreting {
        var recipe: InterpretedRecipe?
        var error: DummyError?
        init(recipe: InterpretedRecipe? = nil, error: DummyError? = nil) {
            self.recipe = recipe
            self.error = error
        }
        func interpret(_ text: String) async throws -> InterpretedRecipe? {
            if let error { throw error }
            return recipe
        }
    }

    private static let sample = InterpretedRecipe(
        name: "Tomato Soup",
        ingredients: ["400 g tomatoes", "1 onion"],
        steps: ["Simmer", "Blend"],
        prepMinutes: 10, cookMinutes: 20, servings: 4, summary: "Cosy soup"
    )

    // MARK: - Use case

    @Test func importsWhenInterpreterSucceeds() async {
        let sut = SharedTextImporter(interpreter: StubInterpreter(recipe: Self.sample))
        guard case let .imported(recipe) = await sut.handle("some caption") else {
            Issue.record("expected .imported"); return
        }
        #expect(recipe.name == "Tomato Soup")
        #expect(recipe.ingredients.count == 2)
        #expect(recipe.baseServings == 4)
    }

    @Test func manualWhenInterpreterDeclines() async {
        let sut = SharedTextImporter(interpreter: StubInterpreter(recipe: nil))
        #expect(await sut.handle("text") == .needsManualEntry("text"))
    }

    @Test func manualWhenNoIngredients() async {
        let empty = InterpretedRecipe(name: "X", ingredients: [], steps: ["a"],
                                      prepMinutes: nil, cookMinutes: nil, servings: nil, summary: nil)
        let sut = SharedTextImporter(interpreter: StubInterpreter(recipe: empty))
        #expect(await sut.handle("text") == .needsManualEntry("text"))
    }

    @Test func manualWhenInterpreterThrows() async {
        let sut = SharedTextImporter(interpreter: StubInterpreter(error: DummyError()))
        #expect(await sut.handle("text") == .needsManualEntry("text"))
    }

    @Test func manualWhenTextBlank() async {
        let sut = SharedTextImporter(interpreter: StubInterpreter(recipe: Self.sample))
        #expect(await sut.handle("   ") == .needsManualEntry("   "))
    }

    // MARK: - Builder mapping

    @Test func builderMapsInterpretedFields() {
        let recipe = RecipeImportBuilder().build(from: Self.sample)
        #expect(recipe.name == "Tomato Soup")
        #expect(recipe.baseServings == 4)
        #expect(recipe.prepTime == "10 minutes")
        #expect(recipe.cookingTime == "20 minutes")
        #expect(recipe.instructions == ["Simmer", "Blend"])
        #expect(recipe.ingredients.contains { $0.name.localizedCaseInsensitiveContains("onion") })
        #expect(recipe.notes.contains("Cosy soup"))
    }

    @Test func builderDefaultsServingsWhenMissing() {
        let noServings = InterpretedRecipe(name: "Bread", ingredients: ["flour"], steps: [],
                                           prepMinutes: nil, cookMinutes: nil, servings: nil, summary: nil)
        #expect(RecipeImportBuilder().build(from: noServings).baseServings == 4)
    }
}
