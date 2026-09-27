#if canImport(FoundationModels)
import Foundation
import FoundationModels

/// On-device (private/free/offline) recipe interpretation via Apple's FoundationModels guided generation; gated to iOS 26+ and `interpret` returns nil when the model can't run (AI off, downloading, ineligible) so callers fall back.
@available(iOS 26.0, *)
struct FoundationModelsRecipeInterpreter: RecipeTextInterpreting {

    /// Guided-generation shape the model fills in; kept small/clearly-named for the on-device context window.
    @Generable
    struct GeneratedRecipe {
        @Guide(description: "The dish's name")
        var name: String
        @Guide(description: "Every ingredient with its quantity and unit, one entry each, e.g. '200 g plain flour'")
        var ingredients: [String]
        @Guide(description: "The method as ordered steps, one step per entry")
        var steps: [String]
        @Guide(description: "Preparation time in whole minutes")
        var prepMinutes: Int?
        @Guide(description: "Cooking time in whole minutes")
        var cookMinutes: Int?
        @Guide(description: "How many servings the recipe makes")
        var servings: Int?
        @Guide(description: "A one-sentence summary of the dish")
        var summary: String?
    }

    func interpret(_ text: String) async throws -> InterpretedRecipe? {
        guard SystemLanguageModel.default.isAvailable else { return nil }

        let instructions = """
        Extract a single cooking recipe from the text the user provides. Only use \
        information present in the text — never invent ingredients, steps, times, or \
        servings. If the text is not a recipe, return empty ingredients and steps.
        """
        let session = LanguageModelSession(instructions: instructions)
        let response = try await session.respond(to: text, generating: GeneratedRecipe.self)
        let generated = response.content

        let name = generated.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let ingredients = generated.ingredients.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !name.isEmpty, !ingredients.isEmpty else { return nil }

        return InterpretedRecipe(
            name: name,
            ingredients: ingredients,
            steps: generated.steps.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty },
            prepMinutes: generated.prepMinutes,
            cookMinutes: generated.cookMinutes,
            servings: generated.servings,
            summary: generated.summary
        )
    }
}
#endif
