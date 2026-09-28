import Foundation

struct IngredientNameFormatter {
    
    private static let preparationKeywords = [
        "diced", "chopped", "sliced", "minced", "grated", "shredded",
        "cut", "bite-sized", "pieces", "cubed", "julienned",
        "boneless", "skinless", "trimmed", "peeled", "seeded",
        "fresh", "dried", "frozen", "canned", "cooked",
        "room temperature", "softened", "melted", "beaten"
    ]

    // NSRegularExpression is expensive to construct — cache once instead of allocating per ingredient row.
    private static let leadingRangeRegex = try? NSRegularExpression(pattern: #"^[-–]\s+"#, options: [])
    private static let qtyUnitRegex = try? NSRegularExpression(
        pattern: #"^[\d/\.\-]+\s+(tbsp|tsp|cups?|ml|l|g|kg|oz|lbs?|inch(?:es)?)\s+"#,
        options: [.caseInsensitive]
    )

    static func formatForDisplay(_ name: String) -> String {
        return name.capitalized
    }

    static func extractMainName(_ name: String) -> String {
        var result = name

        // Strip leading range prefix like "- 1 cup " or "– 1 "
        if let regex = leadingRangeRegex,
           let match = regex.firstMatch(in: result, options: [], range: NSRange(result.startIndex..., in: result)),
           let range = Range(match.range, in: result) {
            result = String(result[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        }

        // Strip leading quantity+unit (handles already-saved strings like "1/4 tsp kosher salt", "1 cup oil")
        if let regex = qtyUnitRegex,
           let match = regex.firstMatch(in: result, options: [], range: NSRange(result.startIndex..., in: result)),
           let range = Range(match.range, in: result) {
            result = String(result[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        }

        // Strip a leading bare quantity/count with no unit ("1 chicken breast" → "chicken breast", "2-3 eggs" → "eggs"); the amount has its own column.
        result = result.replacingOccurrences(
            of: #"^\d+(?:[./]\d+)?(?:\s*[-–—]\s*\d+(?:[./]\d+)?)?\s+(?=\S)"#,
            with: "",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespaces)

        // Strip parenthetical content (handles nested and unclosed parens)
        if let parenStart = result.firstIndex(of: "(") {
            result = String(result[..<parenStart]).trimmingCharacters(in: .whitespaces)
        }

        // Strip trailing orphaned closing paren with no matching open paren
        if result.hasSuffix(")") && !result.contains("(") {
            result = String(result.dropLast()).trimmingCharacters(in: .whitespaces)
        }

        // Strip "such as ..." and "like ..." alternative descriptions common in recipe writing
        for phrase in [" such as ", " like a ", " like "] {
            if let range = result.range(of: phrase, options: .caseInsensitive) {
                result = String(result[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                break
            }
        }

        if let commaIndex = result.firstIndex(of: ",") {
            let mainPart = String(result[..<commaIndex]).trimmingCharacters(in: .whitespaces)
            return removeLeadingPrepWords(mainPart)
        }

        return removeLeadingPrepWords(result)
    }
    
    static func extractPreparationNotes(_ name: String) -> String? {
        let parts = name.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        var phrases: [String] = []

        // Comma clauses after the main name are the prep detail ("chicken breast, cut into cubes" → "cut into cubes").
        phrases.append(contentsOf: parts.dropFirst().map { $0.lowercased() })

        // Plus any prep keyword in the descriptor before the first comma ("boneless skinless chicken" → boneless, skinless).
        let head = parts.first ?? name
        for word in head.components(separatedBy: .whitespaces) {
            let clean = word.trimmingCharacters(in: CharacterSet.punctuationCharacters).lowercased()
            if preparationKeywords.contains(clean) { phrases.append(clean) }
        }

        // Dedupe: drop empties, exact repeats, and any phrase already contained in a longer kept one ("cut" ⊂ "cut into cubes").
        var kept: [String] = []
        for phrase in phrases where !phrase.isEmpty {
            if kept.contains(where: { $0.contains(phrase) }) { continue }
            kept.removeAll { phrase.contains($0) }
            kept.append(phrase)
        }

        return kept.isEmpty ? nil : kept.joined(separator: ", ")
    }
    
    private static func removeLeadingPrepWords(_ text: String) -> String {
        var words = text.components(separatedBy: .whitespaces)
        
        while let firstWord = words.first {
            let cleanedWord = firstWord.trimmingCharacters(in: CharacterSet.punctuationCharacters)
            if preparationKeywords.contains(cleanedWord.lowercased()) {
                words.removeFirst()
            } else {
                break
            }
        }
        
        return words.joined(separator: " ")
    }
}
