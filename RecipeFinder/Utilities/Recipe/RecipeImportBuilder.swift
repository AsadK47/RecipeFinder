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

    /// Builds a `RecipeModel` from free-text interpretation (e.g. on-device AI).
    /// Reuses `parseIngredient` for ingredient lines; category/difficulty default
    /// since free text rarely states them reliably.
    func build(from recipe: InterpretedRecipe) -> RecipeModel {
        let ingredients = recipe.ingredients
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { parseIngredient($0) }

        return RecipeModel(
            name: recipe.name,
            category: "Main",
            difficulty: "Medium",
            prepTime: recipe.prepMinutes.map { "\($0) minutes" } ?? "0 minutes",
            cookingTime: recipe.cookMinutes.map { "\($0) minutes" } ?? "0 minutes",
            baseServings: recipe.servings ?? 4,
            ingredients: ingredients.isEmpty
                ? [Ingredient(baseQuantity: 1, unit: "", name: "See recipe")]
                : ingredients,
            prePrepInstructions: [],
            instructions: recipe.steps.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty },
            notes: interpretedNotes(from: recipe),
            imageName: nil,
            isFavorite: false
        )
    }

    private func interpretedNotes(from recipe: InterpretedRecipe) -> String {
        var lines: [String] = []
        if let summary = recipe.summary?.trimmingCharacters(in: .whitespacesAndNewlines), !summary.isEmpty {
            lines.append(summary)
            lines.append("")
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        lines.append("Imported · \(formatter.string(from: Date()))")
        return lines.joined(separator: "\n")
    }

    // MARK: - Ingredient parsing

    func parseIngredient(_ fullIngredient: String) -> Ingredient {
        let trimmed = normaliseUnicodeFractions(fullIngredient).trimmingCharacters(in: .whitespaces)
        var quantity = ""
        var remaining = trimmed

        // Normalise glued quantity+unit like "200g" → "200 g" so later patterns can split them
        let gluedPattern = #"^(\d+(?:\.\d+)?)(tbsp|tsp|cups?|ml|l|g|kg|oz|lbs?|cloves?|pieces?|pinch|dash|inch(?:es)?)(?=\s|$)"#
        if let regex = try? NSRegularExpression(pattern: gluedPattern, options: .caseInsensitive) {
            let ns = remaining as NSString
            if let match = regex.firstMatch(in: remaining, options: [],
                                            range: NSRange(location: 0, length: ns.length)) {
                let amt = ns.substring(with: match.range(at: 1))
                let unt = ns.substring(with: match.range(at: 2))
                let rest = ns.substring(from: match.range.location + match.range.length)
                remaining = "\(amt) \(unt)\(rest)"
            }
        }

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

        // Handle mixed numbers like "1 3/4" before the simple quantity pattern
        if quantity.isEmpty {
            let mixedPattern = #"^(\d+\s+\d+/\d+)\s+"#
            if let regex = try? NSRegularExpression(pattern: mixedPattern, options: []) {
                let ns = remaining as NSString
                if let match = regex.firstMatch(in: remaining, options: [],
                                                range: NSRange(location: 0, length: ns.length)) {
                    quantity = ns.substring(with: match.range(at: 1))
                    remaining = ns.substring(from: match.range.location + match.range.length)
                }
            }
        }

        if quantity.isEmpty {
            let quantityPattern = #"^([\d\./\-]+)\s+"#
            if let regex = try? NSRegularExpression(pattern: quantityPattern, options: []) {
                let ns = remaining as NSString
                if let match = regex.firstMatch(in: remaining, options: [],
                                                range: NSRange(location: 0, length: ns.length)) {
                    quantity = ns.substring(with: match.range(at: 1))
                    remaining = ns.substring(from: match.range.location + match.range.length)
                }
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

        return Ingredient(baseQuantity: parseQuantity(quantity), unit: unit, name: name)
    }

    // MARK: - Quantity parsing

    /// Converts a quantity string to a Double.
    /// Handles plain integers/decimals ("2", "1.5"), pure fractions ("1/4", "3/4"),
    /// and mixed-number strings ("1 1/2"). Returns 1.0 as a safe fallback.
    private func parseQuantity(_ s: String) -> Double {
        let trimmed = s.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return 1.0 }

        // Plain integer or decimal — "2", "1.5"
        if let d = Double(trimmed) { return d }

        // Mixed number — "1 1/2": split on whitespace then add
        let spaceParts = trimmed.split(separator: " ", maxSplits: 1).map(String.init)
        if spaceParts.count == 2,
           let whole = Double(spaceParts[0]) {
            if let frac = parseFraction(spaceParts[1]) {
                return whole + frac
            }
        }

        // Pure fraction — "1/4"
        if let frac = parseFraction(trimmed) { return frac }

        return 1.0
    }

    /// Parses a "numerator/denominator" string to Double. Returns nil if not a valid fraction.
    private func parseFraction(_ s: String) -> Double? {
        let parts = s.split(separator: "/", maxSplits: 1).map(String.init)
        guard parts.count == 2,
              let num = Double(parts[0].trimmingCharacters(in: .whitespaces)),
              let den = Double(parts[1].trimmingCharacters(in: .whitespaces)),
              den != 0 else { return nil }
        return num / den
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        lines.append("Imported · \(dateFormatter.string(from: Date()))")
        lines.append(data.sourceURL.absoluteString)

        return lines.joined(separator: "\n")
    }

}
