import Foundation

/// Converts `RecipeImporter.ExtractedRecipeData` into a `RecipeModel` with no wizard step.
struct RecipeImportBuilder {

    // MARK: - Public API

    func build(from data: RecipeImporter.ExtractedRecipeData) -> RecipeModel {
        let ingredients = data.rawIngredients
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { parseIngredient($0) }

        return RecipeModel(
            name: data.name,
            category: data.category ?? "Main",
            difficulty: data.difficulty ?? "Medium",
            prepTime: data.prepTimeMinutes.map { "\($0) minutes" } ?? "0 minutes",
            cookingTime: data.cookTimeMinutes.map { "\($0) minutes" } ?? "0 minutes",
            baseServings: data.servings ?? 4,
            // Leave empty rather than fabricate a "See recipe" placeholder, so the caller can surface the gap for review.
            ingredients: ingredients,
            prePrepInstructions: [],
            instructions: data.instructions.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty },
            notes: buildNotes(from: data),
            imageName: data.imageURL,
            isFavorite: false,
            cuisine: data.cuisine
        )
    }

    // MARK: - Ingredient parsing

    /// Delegates to shared `IngredientLineParser` so import and manual entry parse identically; missing amount stays 0, not a fake 1.
    func parseIngredient(_ fullIngredient: String) -> Ingredient {
        let parsed = IngredientLineParser.parse(fullIngredient)
        return Ingredient(baseQuantity: parsed.quantity, unit: parsed.unit, name: parsed.name)
    }

    // MARK: - Notes generation

    private static let importDateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; return f
    }()

    func buildNotes(from data: RecipeImporter.ExtractedRecipeData) -> String {
        var lines: [String] = []

        if let description = data.description, !description.isEmpty {
            let clean = description
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            lines.append(clean)
        }

        if !lines.isEmpty { lines.append("") }
        lines.append("Imported · \(Self.importDateFormatter.string(from: Date()))")
        lines.append(data.sourceURL.absoluteString)

        return lines.joined(separator: "\n")
    }

}
