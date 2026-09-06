import Foundation

/// Decides how a free-text share becomes a recipe: try the on-device
/// interpreter, otherwise hand the raw text back for the heuristic parser. Either
/// way the result is reviewed and edited in the wizard before it is saved — the
/// importer no longer builds or persists a recipe itself. Pure and injectable so
/// the decision is unit-tested without the on-device model.
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
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .needsManualEntry(text) }

        do {
            if let interpreted = try await interpreter.interpret(trimmed),
               !interpreted.name.trimmingCharacters(in: .whitespaces).isEmpty,
               interpreted.ingredients.contains(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
                return .interpreted(interpreted)
            }
        } catch {
            // Any model error (unavailable, guardrail, context limit) → manual.
        }
        return .needsManualEntry(text)
    }
}
