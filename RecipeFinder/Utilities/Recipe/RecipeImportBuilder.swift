import Foundation

/// Converts `RecipeImporter.ExtractedRecipeData` into a `RecipeModel` with no wizard step.
struct RecipeImportBuilder {

    // MARK: - Public API

    func build(from data: RecipeImporter.ExtractedRecipeData) -> RecipeModel {
        let ingredients = parseIngredients(data.rawIngredients)

        return RecipeModel(
            name: data.name,
            category: data.category ?? "Main",
            difficulty: RecipeWizardBuilder.normalizeDifficulty(data.difficulty ?? ""),
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
            cuisine: data.cuisine,
            sourceText: data.pageText
        )
    }

    // MARK: - Ingredient parsing

    /// Delegates to shared `IngredientLineParser` so import and manual entry parse identically; missing amount stays 0, not a fake 1.
    func parseIngredient(_ fullIngredient: String, section: String? = nil) -> Ingredient {
        let parsed = IngredientLineParser.parse(fullIngredient)
        return Ingredient(baseQuantity: parsed.quantity, unit: parsed.unit, name: parsed.name, section: section)
    }

    /// Ingredient lines → ingredients, with "For the sauce:" header lines grouping the lines below them.
    func parseIngredients(_ lines: [String]) -> [Ingredient] {
        IngredientSections.items(fromLines: lines) { parseIngredient($0, section: $1) }
    }

    // MARK: - Notes generation

    private static let importDateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; return f
    }()

    func buildNotes(from data: RecipeImporter.ExtractedRecipeData) -> String {
        var lines: [String] = []

        if let description = data.description, !description.isEmpty {
            let clean = description
                .trimmed
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            lines.append(clean)
        }

        if !lines.isEmpty { lines.append("") }
        lines.append("Imported · \(Self.importDateFormatter.string(from: Date()))")
        lines.append(data.sourceURL.absoluteString)

        return lines.joined(separator: "\n")
    }

}
