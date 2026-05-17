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

    func parseIngredient(_ fullIngredient: String) -> Ingredient {
        let trimmed = normaliseUnicodeFractions(fullIngredient).trimmingCharacters(in: .whitespaces)
        var quantity = ""
        var remaining = trimmed

        // Normalise range amounts like "3/4 – 1" — take the upper bound
        let rangePattern = #"^[\d/\.]+\s*[-–]\s*([\d/\.]+)\s+"#
        if let regex = try? NSRegularExpression(pattern: rangePattern, options: []) {
            let ns = remaining as NSString
            if let match = regex.firstMatch(in: remaining, options: [],
                                            range: NSRange(location: 0, length: ns.length)) {
                quantity = ns.substring(with: match.range(at: 1))
                remaining = ns.substring(from: match.range.location + match.range.length)
            }
        }

        let quantityPattern = #"^([\d\./\-]+)\s+"#
        if let regex = try? NSRegularExpression(pattern: quantityPattern, options: []) {
            let ns = remaining as NSString
            if let match = regex.firstMatch(in: remaining, options: [],
                                            range: NSRange(location: 0, length: ns.length)) {
                quantity = ns.substring(with: match.range(at: 1))
                remaining = ns.substring(from: match.range.location + match.range.length)
            }
        }

        let unitPattern = #"^(tbsp|tsp|cups?|ml|l|liter|liters|g|kg|oz|lbs?|cloves?|pieces?|pinch|dash|inch(?:es)?)(?:\s+|$)"#
        var unit = ""
        if let regex = try? NSRegularExpression(pattern: unitPattern, options: .caseInsensitive) {
            let ns = remaining as NSString
            if let match = regex.firstMatch(in: remaining, options: [],
                                            range: NSRange(location: 0, length: ns.length)) {
                unit = ns.substring(with: match.range(at: 1))
                remaining = ns.substring(from: match.range.location + match.range.length)
            }
        }

        var name = remaining.trimmingCharacters(in: .whitespaces)
        if let commaIndex = name.firstIndex(of: ",") {
            name = String(name[..<commaIndex])
        }
        name = name.trimmingCharacters(in: .whitespaces)

        if quantity.isEmpty && unit.isEmpty && name.isEmpty {
            name = trimmed
        }

        return Ingredient(baseQuantity: Double(quantity) ?? 1.0, unit: unit, name: name)
    }

    // MARK: - Unicode fraction normalisation

    private func normaliseUnicodeFractions(_ s: String) -> String {
        let map: [(Character, String)] = [
            ("¼", "1/4"), ("½", "1/2"), ("¾", "3/4"),
            ("⅓", "1/3"), ("⅔", "2/3"),
            ("⅛", "1/8"), ("⅜", "3/8"), ("⅝", "5/8"), ("⅞", "7/8"),
            ("⅕", "1/5"), ("⅖", "2/5"), ("⅗", "3/5"), ("⅘", "4/5"),
            ("⅙", "1/6"), ("⅚", "5/6"),
        ]
        var result = s
        for (char, replacement) in map {
            result = result.replacingOccurrences(of: String(char), with: replacement + " ")
        }
        return result
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
        let domain = data.sourceURL.host?.replacingOccurrences(of: "www.", with: "") ?? "Unknown"
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        lines.append("Imported from \(domain) · \(dateFormatter.string(from: Date()))")

        return lines.joined(separator: "\n")
    }

}
