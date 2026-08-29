import Foundation

/// Free-text heuristics for `RecipeParser`: recipe name, description, times,
/// servings, and difficulty. Used when no structured data (JSON-LD / WPRM) is
/// available.
extension RecipeParser {

    static func extractRecipeName(from html: String, text: String) -> String? {
        if let titleMatch = html.range(of: "<title[^>]*>([^<]+)</title>", options: .regularExpression) {
            var title = String(html[titleMatch])
            title = title.replacingOccurrences(of: "<title[^>]*>", with: "", options: .regularExpression)
            title = title.replacingOccurrences(of: "</title>", with: "")
            title = title.trimmingCharacters(in: .whitespacesAndNewlines)

            let suffixes = [" - Recipe", " Recipe", " | RecipeName", " - Cooking", " | Food"]
            for suffix in suffixes {
                if title.hasSuffix(suffix) {
                    title = String(title.dropLast(suffix.count))
                }
            }

            if !title.isEmpty && title.count < 100 {
                return title
            }
        }

        if let h1Match = html.range(of: "<h1[^>]*>([^<]+)</h1>", options: .regularExpression) {
            var h1 = String(html[h1Match])
            h1 = h1.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            h1 = h1.trimmingCharacters(in: .whitespacesAndNewlines)

            if !h1.isEmpty && h1.count < 100 {
                return h1
            }
        }

        if let firstLine = text.components(separatedBy: .newlines).first(where: { !$0.isEmpty && $0.count < 100 }) {
            return firstLine
        }

        return nil
    }

    static func extractDescription(from text: String, lines: [String]) -> String? {
        var descriptionLines: [String] = []

        for (index, line) in lines.enumerated() {
            if index == 0 { continue }

            if line.lowercased().contains("ingredient") || isIngredientLine(line) {
                break
            }

            if line.count > 30 && line.count < 300 && !line.hasPrefix("-") && !line.hasPrefix("•") {
                descriptionLines.append(line)
            }

            if descriptionLines.count >= 3 { break }
        }

        if !descriptionLines.isEmpty {
            return descriptionLines.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return nil
    }

    enum TimeType {
        case prep
        case cook
        case total
    }

    static func extractTime(from text: String, type: TimeType) -> Int? {
        let patterns: [String]

        switch type {
        case .prep:
            patterns = [
                "prep time:?\\s*([0-9]+)\\s*(min|minute|minutes|hour|hours|hr|hrs)",
                "preparation time:?\\s*([0-9]+)\\s*(min|minute|minutes|hour|hours|hr|hrs)"
            ]
        case .cook:
            patterns = [
                "cook time:?\\s*([0-9]+)\\s*(min|minute|minutes|hour|hours|hr|hrs)",
                "cooking time:?\\s*([0-9]+)\\s*(min|minute|minutes|hour|hours|hr|hrs)",
                "bake time:?\\s*([0-9]+)\\s*(min|minute|minutes|hour|hours|hr|hrs)"
            ]
        case .total:
            patterns = [
                "total time:?\\s*([0-9]+)\\s*(min|minute|minutes|hour|hours|hr|hrs)"
            ]
        }

        for pattern in patterns {
            if let range = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let match = String(text[range])
                if let valueRange = match.range(of: "[0-9]+", options: .regularExpression),
                   let value = Int(match[valueRange]) {

                    if match.lowercased().contains("hour") || match.lowercased().contains("hr") {
                        return value * 60
                    }
                    return value
                }
            }
        }

        return nil
    }

    static func extractServings(from text: String) -> Int? {
        let patterns = [
            "serves:?\\s*([0-9]+)",
            "servings:?\\s*([0-9]+)",
            "yield:?\\s*([0-9]+)\\s*servings",
            "makes:?\\s*([0-9]+)\\s*servings"
        ]

        for pattern in patterns {
            if let range = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let match = String(text[range])
                if let valueRange = match.range(of: "[0-9]+", options: .regularExpression),
                   let value = Int(match[valueRange]) {
                    return value
                }
            }
        }

        return nil
    }

    static func extractDifficulty(from text: String) -> String? {
        let difficulties = ["easy", "medium", "moderate", "hard", "difficult", "beginner", "intermediate", "advanced"]

        let lowercased = text.lowercased()
        for difficulty in difficulties {
            if lowercased.range(of: "difficulty:?\\s*\(difficulty)", options: .regularExpression) != nil ||
               lowercased.range(of: "level:?\\s*\(difficulty)", options: .regularExpression) != nil {
                return difficulty.capitalized
            }
        }

        return nil
    }
}
