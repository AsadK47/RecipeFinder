import Foundation

/// A recipe parsed out of free-form text (a social caption, pasted notes, OCR
/// output) before it becomes a `RecipeModel`. Foundation-only so the
/// interpretation seam is testable with a fake, independent of whether
/// on-device FoundationModels is available.
struct InterpretedRecipe: Equatable, Sendable {
    var name: String
    var ingredients: [String]
    var steps: [String]
    var prepMinutes: Int?
    var cookMinutes: Int?
    var servings: Int?
    var summary: String?
}

/// Turns free text into a structured recipe. The production implementation is
/// backed by the on-device foundation model (iOS 26+); tests inject a fake, and
/// pre-26 devices use an implementation that always declines so callers fall
/// back to manual entry.
protocol RecipeTextInterpreting: Sendable {
    /// Returns a structured recipe, or `nil` when the text isn't a recipe or the
    /// model is unavailable — callers fall back to manual entry.
    func interpret(_ text: String) async throws -> InterpretedRecipe?
}

/// Used on devices without the on-device model (pre-iOS 26 or Apple Intelligence
/// off): always declines, so the caller routes to manual entry.
struct UnavailableRecipeTextInterpreter: RecipeTextInterpreting {
    func interpret(_ text: String) async throws -> InterpretedRecipe? { nil }
}
