import Foundation

/// Parses free-form recipe text — pasted notes, social media captions,
/// shared messages — into wizard prefill data for the user to review.
///
/// Two strategies, tried in order:
/// 1. Section headers ("Ingredients", "Instructions"/"Method"/"Directions"/
///    "Steps") split the text explicitly.
/// 2. Without headers, each line is classified: quantity- or bullet-led lines
///    are ingredients, numbered or sentence-like lines are instructions.
enum TextRecipeParser {

    static func parse(_ text: String) -> RecipeWizardView.PrefilledRecipeData? {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard lines.count >= 3 else { return nil }

        let servings = firstIntMatch(#"(?:serves|servings?|yield)\s*:?\s*(\d+)"#, in: text)
        let prepTime = firstIntMatch(#"prep(?:aration)?\s*time\s*:?\s*(\d+)"#, in: text)
        let cookTime = firstIntMatch(#"cook(?:ing)?\s*time\s*:?\s*(\d+)"#, in: text)

        var ingredients: [String]
        var instructions: [String]

        if let sections = splitBySectionHeaders(lines) {
            ingredients = sections.ingredients
            instructions = sections.instructions
        } else {
            (ingredients, instructions) = classifyLines(lines)
        }

        ingredients = ingredients.map(stripListMarker).filter { !$0.isEmpty && !isMetadataLine($0) }
        instructions = instructions.map(stripListMarker).filter { !$0.isEmpty && !isMetadataLine($0) }

        guard !ingredients.isEmpty, !instructions.isEmpty else { return nil }

        return RecipeWizardView.PrefilledRecipeData(
            name: title(from: lines),
            description: nil,
            ingredients: ingredients,
            instructions: instructions,
            prepTime: prepTime,
            cookTime: cookTime,
            servings: servings,
            difficulty: nil,
            notes: nil,
            category: nil,
            isFavorite: nil,
            imageURL: nil
        )
    }

    // MARK: - Title

    private static func title(from lines: [String]) -> String? {
        guard let first = lines.first(where: { !isSectionHeader($0) && !isMetadataLine($0) }) else {
            return nil
        }
        // Titles are short; a long first line is prose, not a name.
        guard first.count <= 80, !looksLikeIngredient(first) else { return nil }

        let cleaned = first
            .replacingOccurrences(of: #"^(recipe\s*:?\s*)"#, with: "", options: [.regularExpression, .caseInsensitive])
            .trimmingCharacters(in: .whitespaces)
        return cleaned.isEmpty ? nil : cleaned
    }

    // MARK: - Section-header strategy

    private static func splitBySectionHeaders(_ lines: [String]) -> (ingredients: [String], instructions: [String])? {
        var ingredientLines: [String] = []
        var instructionLines: [String] = []
        var current: Section?

        for line in lines {
            if matchesHeader(line, keywords: ["ingredients", "you will need", "you'll need"]) {
                current = .ingredients
                continue
            }
            if matchesHeader(line, keywords: ["instructions", "method", "directions", "steps", "preparation"]) {
                current = .instructions
                continue
            }

            switch current {
            case .ingredients: ingredientLines.append(line)
            case .instructions: instructionLines.append(line)
            case nil: break
            }
        }

        guard !ingredientLines.isEmpty || !instructionLines.isEmpty else { return nil }
        return (ingredientLines, instructionLines)
    }

    private enum Section {
        case ingredients
        case instructions
    }

    private static func isSectionHeader(_ line: String) -> Bool {
        matchesHeader(line, keywords: [
            "ingredients", "you will need", "you'll need",
            "instructions", "method", "directions", "steps", "preparation"
        ])
    }

    private static func matchesHeader(_ line: String, keywords: [String]) -> Bool {
        let normalized = line
            .lowercased()
            .trimmingCharacters(in: CharacterSet(charactersIn: " :#*-–—"))
        return keywords.contains(normalized)
    }

    // MARK: - Line-classification strategy

    private static func classifyLines(_ lines: [String]) -> (ingredients: [String], instructions: [String]) {
        var ingredients: [String] = []
        var instructions: [String] = []

        // Skip the title line when classifying.
        let bodyLines = lines.dropFirst()

        for line in bodyLines where !isMetadataLine(line) {
            if looksLikeInstruction(line) {
                instructions.append(line)
            } else if looksLikeIngredient(line) {
                ingredients.append(line)
            } else if line.count > 60 {
                // Long prose lines read as instructions.
                instructions.append(line)
            }
        }

        return (ingredients, instructions)
    }

    private static func looksLikeIngredient(_ line: String) -> Bool {
        // Quantity-led ("2 cups flour", "½ tsp salt") or bulleted ("- flour").
        line.range(of: #"^[-•*]?\s*(\d|[¼½¾⅓⅔⅛⅜⅝⅞⅕⅖⅗⅘⅙⅚])"#, options: .regularExpression) != nil
            || line.range(of: #"^[-•*]\s+\S"#, options: .regularExpression) != nil
    }

    private static func looksLikeInstruction(_ line: String) -> Bool {
        // Numbered steps: "1. Preheat…", "2) Mix…", "Step 3: …"
        line.range(of: #"^(step\s+\d+|\d+[\.\)])\s*"#, options: [.regularExpression, .caseInsensitive]) != nil
    }

    // MARK: - Cleanup

    private static func stripListMarker(_ line: String) -> String {
        line
            .replacingOccurrences(of: #"^(step\s+\d+\s*[:\.\)]?|\d+[\.\)])\s*"#, with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"^[-•*]\s*"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }

    private static func isMetadataLine(_ line: String) -> Bool {
        line.range(
            of: #"^(serves|servings?|yield|prep(?:aration)?\s*time|cook(?:ing)?\s*time|total\s*time)\b"#,
            options: [.regularExpression, .caseInsensitive]
        ) != nil
    }

    private static func firstIntMatch(_ pattern: String, in text: String) -> Int? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              match.numberOfRanges > 1,
              let valueRange = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return Int(text[valueRange])
    }
}
