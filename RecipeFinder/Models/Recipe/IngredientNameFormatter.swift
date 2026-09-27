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

        let lowercased = result.lowercased()
        if let commaIndex = lowercased.firstIndex(of: ",") {
            let mainPart = String(result[..<commaIndex]).trimmingCharacters(in: .whitespaces)
            return removeLeadingPrepWords(mainPart)
        }

        return removeLeadingPrepWords(result)
    }
    
    static func extractPreparationNotes(_ name: String) -> String? {
        var notes: [String] = []
        let lowercased = name.lowercased()
        
        if let commaIndex = lowercased.firstIndex(of: ",") {
            let prepPart = String(name[name.index(after: commaIndex)...])
                .trimmingCharacters(in: .whitespaces)
            notes.append(prepPart.lowercased())
        }
        
        let words = name.components(separatedBy: .whitespaces)
        for word in words {
            let cleanWord = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
            if preparationKeywords.contains(cleanWord.lowercased()) {
                notes.append(cleanWord.lowercased())
            }
        }
        
        let uniqueNotes = Array(Set(notes)).sorted()
        return uniqueNotes.isEmpty ? nil : uniqueNotes.joined(separator: ", ")
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
