import Foundation

/// Decides how a free-text share becomes a recipe: try the on-device
/// interpreter for a one-tap import, otherwise hand the text back for manual
/// review. Pure and injectable so the decision + mapping are unit-tested without
/// the model.
struct SharedTextImporter {
    enum Outcome: Equatable {
        /// The interpreter produced a usable recipe — save it directly.
        case imported(RecipeModel)
        /// Couldn't interpret it — route to the manual/wizard flow with the text.
        case needsManualEntry(String)
    }

    private let interpreter: RecipeTextInterpreting
    private let builder: RecipeImportBuilder

    init(interpreter: RecipeTextInterpreting, builder: RecipeImportBuilder = RecipeImportBuilder()) {
        self.interpreter = interpreter
        self.builder = builder
    }

    func handle(_ text: String) async -> Outcome {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .needsManualEntry(text) }

        do {
            if let interpreted = try await interpreter.interpret(trimmed),
               !interpreted.name.trimmingCharacters(in: .whitespaces).isEmpty,
               interpreted.ingredients.contains(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
                return .imported(builder.build(from: interpreted))
            }
        } catch {
            // Any model error (unavailable, guardrail, context limit) → manual.
        }
        return .needsManualEntry(text)
    }
}
