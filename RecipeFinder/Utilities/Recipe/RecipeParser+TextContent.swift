import Foundation

/// Free-text heuristics for `RecipeParser`: scanning cleaned page text for the
/// ingredient and instruction sections. Used when no structured data is present.
extension RecipeParser {

    static func extractIngredients(from text: String, lines: [String]) -> [String] {
        var ingredients: [String] = []
        var uniqueIngredients = Set<String>()
        var inIngredientSection = false
        var emptyLineCount = 0
        var foundFirstIngredient = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.isEmpty {
                if inIngredientSection && foundFirstIngredient {
                    emptyLineCount += 1
                    if emptyLineCount >= 3 {
                        break
                    }
                }
                continue
            } else {
                emptyLineCount = 0
            }

            if trimmed.lowercased().contains("ingredient") && trimmed.count < 50 {
                if ingredients.count > 5 {
                    break
                }
                inIngredientSection = true
                continue
            }

            if inIngredientSection && foundFirstIngredient {
                let lower = trimmed.lowercased()
                if lower.contains("instruction") || 
                   lower.contains("method") ||
                   lower.contains("direction") ||
                   lower.contains("notes") ||
                   lower.contains("nutrition") ||
                   lower.contains("calories:") ||
                   lower.starts(with: "prep time") ||
                   lower.starts(with: "cook time") ||
                   lower.starts(with: "total time") {
                    break
                }
            }

            if inIngredientSection && isIngredientLine(trimmed) {
                let cleaned = cleanIngredientLine(trimmed)
                if !cleaned.isEmpty {
                    let normalizedKey = cleaned.lowercased()
                    if !uniqueIngredients.contains(normalizedKey) {
                        ingredients.append(cleaned)
                        uniqueIngredients.insert(normalizedKey)
                        foundFirstIngredient = true
                    }
                }
            }
        }

        return ingredients
    }

    static func isIngredientLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.count >= 3 && trimmed.count < 200 else { return false }

        let indicators = [
            "cup", "cups", "tbsp", "tsp", "teaspoon", "tablespoon", "oz", "ounce", "lb", "pound",
            "gram", "grams", "kg", "kilogram", "ml", "milliliter", "liter", "l",
            "clove", "cloves", "pinch", "dash", "sprig", "bunch", "piece", "pieces", "slice", "slices",
            "diced", "chopped", "sliced", "minced", "crushed", "grated", "shredded",
            "fresh", "dried", "frozen", "canned", "whole", "ground",
            "optional", "to taste", "as needed", "for serving",
            "½", "¼", "¾", "⅓", "⅔", "⅛", "⅜", "⅝", "⅞"
        ]

        let lowercased = trimmed.lowercased()

        for indicator in indicators {
            if lowercased.contains(indicator) {
                return true
            }
        }

        let numberPattern = "^[0-9]|\\s[0-9]|^[½¼¾⅓⅔⅛⅜⅝⅞]|\\s[½¼¾⅓⅔⅛⅜⅝⅞]"
        if lowercased.range(of: numberPattern, options: .regularExpression) != nil {
            return true
        }

        if trimmed.count < 80 {
            let foodWords = ["oil", "salt", "pepper", "sugar", "butter", "egg", "flour", "water", "milk", "cheese", "onion", "garlic", "tomato", "chicken", "beef", "pork", "rice", "pasta"]
            for food in foodWords {
                if lowercased.contains(food) {
                    return true
                }
            }
        }

        return false
    }

    private static func cleanIngredientLine(_ line: String) -> String {
        var cleaned = line

        cleaned = cleaned.replacingOccurrences(of: "^[•\\-*]\\s*", with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "^[0-9]+\\.\\s*", with: "", options: .regularExpression)

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func extractInstructions(from text: String, lines: [String]) -> [String] {
        var instructions: [String] = []
        var uniqueInstructions = Set<String>()
        var inInstructionSection = false
        var emptyLineCount = 0
        var foundFirstInstruction = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.isEmpty {
                if inInstructionSection && foundFirstInstruction {
                    emptyLineCount += 1
                    if emptyLineCount >= 3 {
                        break
                    }
                }
                continue
            } else {
                emptyLineCount = 0
            }

            if (trimmed.lowercased().contains("instruction") || 
                trimmed.lowercased().contains("method") ||
                trimmed.lowercased().contains("direction")) && trimmed.count < 50 {
                if instructions.count > 3 {
                    break
                }
                inInstructionSection = true
                continue
            }

            if inInstructionSection && foundFirstInstruction {
                let lower = trimmed.lowercased()
                if lower.contains("notes") ||
                   lower.contains("nutrition") ||
                   lower.contains("calories:") ||
                   lower.starts(with: "did you make") {
                    break
                }
            }

            if inInstructionSection && isInstructionLine(trimmed) {
                let cleaned = cleanInstructionLine(trimmed)
                if !cleaned.isEmpty {
                    let normalizedKey = cleaned.lowercased()
                    if !uniqueInstructions.contains(normalizedKey) {
                        instructions.append(cleaned)
                        uniqueInstructions.insert(normalizedKey)
                        foundFirstInstruction = true
                    }
                }
            }
        }

        return instructions
    }

    static func isInstructionLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.count >= 10 && trimmed.count < 500 else { return false }

        let lowercased = trimmed.lowercased()

        // Reject bare section header labels that sometimes appear inside the section
        let headers = ["instructions", "method", "directions", "steps", "preparation"]
        let stripped = lowercased.replacingOccurrences(of: ":", with: "").trimmingCharacters(in: .whitespaces)
        if headers.contains(stripped) { return false }

        // Numbered steps are always instructions regardless of content
        if trimmed.range(of: #"^(step\s*\d+|\d+[.)])\s*"#,
                         options: [.regularExpression, .caseInsensitive]) != nil {
            return true
        }

        // Structural markers — time, temperature, connective phrases — are a
        // reliable signal without depending on a finite verb whitelist.
        let cookingPhrases = [
            "until", "for about", "minutes", "hours", "degrees", "°f", "°c",
            "in a", "on a", "into the", "to the", "with the",
            "and cook", "and bake", "and stir", "then add", "then place"
        ]
        for phrase in cookingPhrases where trimmed.count > 20 {
            if lowercased.contains(phrase) { return true }
        }

        // Within a confirmed instruction section, any sentence of instruction-like
        // length is almost certainly a cooking step. Navigation links and labels
        // are typically very short; a finite verb whitelist is not needed here.
        return trimmed.count >= 15
    }

    private static func cleanInstructionLine(_ line: String) -> String {
        var cleaned = line

        cleaned = cleaned.replacingOccurrences(of: "^[•\\-*]\\s*", with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "^Step\\s*[0-9]+[:.)]?\\s*", with: "", options: [.regularExpression, .caseInsensitive])
        cleaned = cleaned.replacingOccurrences(of: "^[0-9]+[:.)]\\s*", with: "", options: .regularExpression)

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
