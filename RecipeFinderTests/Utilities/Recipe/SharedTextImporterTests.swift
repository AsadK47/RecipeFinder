import Testing
import Foundation
@testable import RecipeFinder

/// Free-text import decision with a stub interpreter (no on-device model); the importer returns reviewable data without building/persisting, so the wizard is the save gate.
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

    @Test func interpretedWhenInterpreterSucceeds() async {
        let sut = SharedTextImporter(interpreter: StubInterpreter(recipe: Self.sample))
        #expect(await sut.handle("some caption") == .interpreted(Self.sample))
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

    @Test func manualWhenNoSteps() async {
        // Name + ingredients but no steps isn't a usable recipe — fall back to manual rather than opening the
        // wizard with empty instructions the user can't save.
        let noSteps = InterpretedRecipe(name: "Soup", ingredients: ["1 onion"], steps: [],
                                        prepMinutes: nil, cookMinutes: nil, servings: nil, summary: nil)
        let sut = SharedTextImporter(interpreter: StubInterpreter(recipe: noSteps))
        #expect(await sut.handle("text") == .needsManualEntry("text"))
    }
}
