import Foundation

private let logger = AppLogger.logger(category: "SharedTextImporter")

/// Decides how a free-text share becomes a recipe: on-device interpreter, else raw text back for the heuristic parser — always reviewed in the wizard before saving (never persists here). Pure/injectable so the decision is testable without the model.
struct SharedTextImporter {
    enum Outcome: Equatable {
        /// The interpreter produced a usable recipe — review it in the wizard.
        case interpreted(InterpretedRecipe)
        /// Couldn't interpret it — route to the manual/wizard flow with the text.
        case needsManualEntry(String)
    }

    private let interpreter: RecipeTextInterpreting

    init(interpreter: RecipeTextInterpreting) {
        self.interpreter = interpreter
    }

    func handle(_ text: String) async -> Outcome {
        let trimmed = text.trimmed
        guard !trimmed.isEmpty else { return .needsManualEntry(text) }

        do {
            if let interpreted = try await interpreter.interpret(trimmed),
               !interpreted.name.trimmingCharacters(in: .whitespaces).isEmpty,
               interpreted.ingredients.contains(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }),
               interpreted.steps.contains(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
                return .interpreted(interpreted)
            }
        } catch {
            // Any model error (unavailable, guardrail, context limit) → fall back to manual entry.
            logger.debug("⚠️ AI interpreter error (falling back to manual): \(error)")
        }
        return .needsManualEntry(text)
    }
}
