import Foundation

/// Recipe parsed from free-form text (caption, notes, OCR) before it becomes a `RecipeModel`; Foundation-only so the seam is testable with a fake regardless of FoundationModels availability.
struct InterpretedRecipe: Equatable, Sendable {
    var name: String
    var ingredients: [String]
    var steps: [String]
    var prepMinutes: Int?
    var cookMinutes: Int?
    var servings: Int?
    var summary: String?
}

/// Turns free text into a structured recipe; production uses the on-device model (iOS 26+), tests a fake, and pre-26 devices an always-declining impl so callers fall back to manual entry.
protocol RecipeTextInterpreting: Sendable {
    /// Structured recipe, or nil when the text isn't a recipe or the model is unavailable — callers fall back to manual entry.
    func interpret(_ text: String) async throws -> InterpretedRecipe?
}

/// Always-declining interpreter for devices without the on-device model (pre-iOS 26 or Apple Intelligence off); routes the caller to manual entry.
struct UnavailableRecipeTextInterpreter: RecipeTextInterpreting {
    func interpret(_ text: String) async throws -> InterpretedRecipe? { nil }
}
