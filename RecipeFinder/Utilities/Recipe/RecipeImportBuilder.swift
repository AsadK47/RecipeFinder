import Foundation

/// Converts `RecipeImporter.ExtractedRecipeData` into a `RecipeModel` without
/// requiring user interaction (no wizard step).
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
            ingredients: ingredients.isEmpty
                ? [Ingredient(baseQuantity: 1, unit: "", name: "See recipe")]
                : ingredients,
            prePrepInstructions: [],
            instructions: data.instructions.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty },
            notes: buildNotes(from: data),
            imageName: data.imageURL,
            isFavorite: false
        )
    }

    // MARK: - Ingredient parsing

    /// Delegates to the shared `IngredientLineParser` so import and manual entry
    /// parse identically. A missing amount stays 0 (unspecified), not a fake 1.
    func parseIngredient(_ fullIngredient: String) -> Ingredient {
        let parsed = IngredientLineParser.parse(fullIngredient)
        return Ingredient(baseQuantity: parsed.quantity, unit: parsed.unit, name: parsed.name)
    }

    // MARK: - Notes generation

    func buildNotes(from data: RecipeImporter.ExtractedRecipeData) -> String {
        var lines: [String] = []

        if let description = data.description, !description.isEmpty {
            let clean = description
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            lines.append(clean)
        }

        if let cuisine = data.cuisine, !cuisine.isEmpty {
            if !lines.isEmpty { lines.append("") }
            lines.append("Cuisine: \(cuisine)")
        }

        if !lines.isEmpty { lines.append("") }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        lines.append("Imported · \(dateFormatter.string(from: Date()))")
        lines.append(data.sourceURL.absoluteString)

        return lines.joined(separator: "\n")
    }

}
