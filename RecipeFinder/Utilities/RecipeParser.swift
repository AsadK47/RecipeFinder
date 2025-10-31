//
//  RecipeParser.swift
//  RecipeFinder
//
//  Intelligent recipe parser that extracts structured data from HTML/text
//

import Foundation

struct RecipeParser {
    
    // Parse Result
    struct ParsedRecipe {
        var name: String?
        var description: String?
        var ingredients: [String] = []
        var instructions: [String] = []
        var prepTime: Int? // minutes
        var cookTime: Int? // minutes
        var servings: Int?
        var difficulty: String?
        var cuisine: String?
        var category: String?
        var confidence: Double = 0.0 // 0.0 to 1.0
    }
    
    /// Parse recipe from HTML or plain text
    static func parse(html: String) -> ParsedRecipe {
        var result = ParsedRecipe()
        var confidenceScore = 0.0
        let maxScore = 8.0 // Total number of extraction attempts
        
        // Clean HTML to plain text
        let text = cleanHTML(html)
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        // 1. Extract recipe name (title)
        if let name = extractRecipeName(from: html, text: text) {
            result.name = name
            confidenceScore += 1.0
        }
        
        // 2. Extract description
        if let description = extractDescription(from: text, lines: lines) {
            result.description = description
            confidenceScore += 0.5
        }
        
        // 3. Extract prep time
        if let prepTime = extractTime(from: text, type: .prep) {
            result.prepTime = prepTime
            confidenceScore += 1.0
        }
        
        // 4. Extract cook time
        if let cookTime = extractTime(from: text, type: .cook) {
            result.cookTime = cookTime
            confidenceScore += 1.0
        }
        
        // 5. Extract servings
        if let servings = extractServings(from: text) {
            result.servings = servings
            confidenceScore += 1.0
        }
        
        // 6. Extract ingredients
        let ingredients = extractIngredients(from: text, lines: lines)
        if !ingredients.isEmpty {
            result.ingredients = ingredients
            confidenceScore += 1.5
        }
        
        // 7. Extract instructions
        let instructions = extractInstructions(from: text, lines: lines)
        if !instructions.isEmpty {
            result.instructions = instructions
            confidenceScore += 1.5
        }
        
        // 8. Extract difficulty
        if let difficulty = extractDifficulty(from: text) {
            result.difficulty = difficulty
            confidenceScore += 0.5
        }
        
        result.confidence = confidenceScore / maxScore
        return result
    }
    
    // Clean HTML to plain text
    private static func cleanHTML(_ html: String) -> String {
        var text = html
        
        // Remove script and style tags
        text = text.replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?</script>", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?</style>", with: "", options: .regularExpression)
        
        // Replace <br> with newlines
        text = text.replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "</p>", with: "\n\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "</div>", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "</li>", with: "\n", options: .regularExpression)
        
        // Remove all HTML tags
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        // Decode HTML entities
        text = decodeHTMLEntities(text)
        
        // Clean up whitespace
        text = text.replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\n\\s*\\n\\s*\\n+", with: "\n\n", options: .regularExpression)
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Decode HTML entities
    private static func decodeHTMLEntities(_ text: String) -> String {
        var result = text
        let entities: [String: String] = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&#039;": "'",
            "&apos;": "'",
            "&nbsp;": " ",
            "&frac12;": "½",
            "&frac14;": "¼",
            "&frac34;": "¾"
        ]
        
        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        
        return result
    }
    
    // Extract recipe name
    private static func extractRecipeName(from html: String, text: String) -> String? {
        // Try <title> tag first
        if let titleMatch = html.range(of: "<title[^>]*>([^<]+)</title>", options: .regularExpression) {
            var title = String(html[titleMatch])
            title = title.replacingOccurrences(of: "<title[^>]*>", with: "", options: .regularExpression)
            title = title.replacingOccurrences(of: "</title>", with: "")
            title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Remove common suffixes
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
        
        // Try <h1> tag
        if let h1Match = html.range(of: "<h1[^>]*>([^<]+)</h1>", options: .regularExpression) {
            var h1 = String(html[h1Match])
            h1 = h1.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            h1 = h1.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !h1.isEmpty && h1.count < 100 {
                return h1
            }
        }
        
        // Fallback: First non-empty line
        if let firstLine = text.components(separatedBy: .newlines).first(where: { !$0.isEmpty && $0.count < 100 }) {
            return firstLine
        }
        
        return nil
    }
    
    // Extract description
    private static func extractDescription(from text: String, lines: [String]) -> String? {
        // Look for lines that seem like descriptions (after title, before ingredients)
        var descriptionLines: [String] = []
        var foundIngredients = false
        
        for (index, line) in lines.enumerated() {
            if index == 0 { continue } // Skip title
            
            // Stop if we hit ingredients
            if line.lowercased().contains("ingredient") || isIngredientLine(line) {
                foundIngredients = true
                break
            }
            
            // Look for descriptive text (sentences, not lists)
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
    
    // Time extraction types
    enum TimeType {
        case prep
        case cook
        case total
    }
    
    // Extract time (prep/cook/total)
    private static func extractTime(from text: String, type: TimeType) -> Int? {
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
                    
                    // Check if it's in hours
                    if match.lowercased().contains("hour") || match.lowercased().contains("hr") {
                        return value * 60 // Convert to minutes
                    }
                    return value
                }
            }
        }
        
        return nil
    }
    
    // Extract servings
    private static func extractServings(from text: String) -> Int? {
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
    
    // Extract ingredients
    private static func extractIngredients(from text: String, lines: [String]) -> [String] {
        var ingredients: [String] = []
        var uniqueIngredients = Set<String>()
        var inIngredientSection = false
        var emptyLineCount = 0
        var foundFirstIngredient = false
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines but track them
            if trimmed.isEmpty {
                if inIngredientSection && foundFirstIngredient {
                    emptyLineCount += 1
                    // If we've had 3+ empty lines, assume we've left the ingredient section
                    if emptyLineCount >= 3 {
                        break
                    }
                }
                continue
            } else {
                emptyLineCount = 0
            }
            
            // Detect ingredient section start
            if trimmed.lowercased().contains("ingredient") && trimmed.count < 50 {
                // If we already have ingredients, this might be a duplicate section - stop
                if ingredients.count > 5 {
                    break
                }
                inIngredientSection = true
                continue
            }
            
            // Detect section end (instructions, method, notes, nutrition, etc.)
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
            
            // Extract ingredient lines
            if inIngredientSection && isIngredientLine(trimmed) {
                let cleaned = cleanIngredientLine(trimmed)
                if !cleaned.isEmpty {
                    // Check for duplicates (case-insensitive)
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
    
    // Check if line is an ingredient
    private static func isIngredientLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Must have reasonable length
        guard trimmed.count >= 3 && trimmed.count < 200 else { return false }
        
        // Common ingredient indicators
        let indicators = [
            "cup", "tbsp", "tsp", "oz", "lb", "gram", "kg", "ml", "liter",
            "clove", "pinch", "dash", "sprig", "bunch", "piece", "slice",
            "diced", "chopped", "sliced", "minced", "crushed", "grated"
        ]
        
        let lowercased = trimmed.lowercased()
        for indicator in indicators {
            if lowercased.contains(indicator) {
                return true
            }
        }
        
        // Check against USDA food list by trying to normalize
        let normalized = IngredientNormalizer.normalize(trimmed)
        // If normalization significantly changed the text, it likely matched something valid
        if normalized != trimmed.capitalized && !normalized.isEmpty {
            return true
        }
        
        // Has numbers (quantities)
        if trimmed.range(of: "[0-9]", options: .regularExpression) != nil {
            return true
        }
        
        return false
    }
    
    // Clean ingredient line
    private static func cleanIngredientLine(_ line: String) -> String {
        var cleaned = line
        
        // Remove bullet points and list markers
        cleaned = cleaned.replacingOccurrences(of: "^[•\\-*]\\s*", with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "^[0-9]+\\.\\s*", with: "", options: .regularExpression)
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Extract instructions
    private static func extractInstructions(from text: String, lines: [String]) -> [String] {
        var instructions: [String] = []
        var uniqueInstructions = Set<String>()
        var inInstructionSection = false
        var emptyLineCount = 0
        var foundFirstInstruction = false
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines but track them
            if trimmed.isEmpty {
                if inInstructionSection && foundFirstInstruction {
                    emptyLineCount += 1
                    // If we've had 3+ empty lines, assume we've left the instruction section
                    if emptyLineCount >= 3 {
                        break
                    }
                }
                continue
            } else {
                emptyLineCount = 0
            }
            
            // Detect instruction section start
            if (trimmed.lowercased().contains("instruction") || 
                trimmed.lowercased().contains("method") ||
                trimmed.lowercased().contains("direction")) && trimmed.count < 50 {
                // If we already have instructions, this might be a duplicate section - stop
                if instructions.count > 3 {
                    break
                }
                inInstructionSection = true
                continue
            }
            
            // Detect section end (notes, nutrition, etc.)
            if inInstructionSection && foundFirstInstruction {
                let lower = trimmed.lowercased()
                if lower.contains("notes") ||
                   lower.contains("nutrition") ||
                   lower.contains("calories:") ||
                   lower.starts(with: "did you make") {
                    break
                }
            }
            
            // Extract instruction steps
            if inInstructionSection && isInstructionLine(trimmed) {
                let cleaned = cleanInstructionLine(trimmed)
                if !cleaned.isEmpty {
                    // Check for duplicates (case-insensitive)
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
    
    // Check if line is an instruction
    private static func isInstructionLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Must have reasonable length
        guard trimmed.count >= 10 && trimmed.count < 500 else { return false }
        
        // Action verbs common in cooking
        let actionVerbs = [
            "add", "mix", "stir", "cook", "bake", "heat", "boil", "simmer",
            "chop", "dice", "slice", "pour", "place", "remove", "combine",
            "preheat", "transfer", "serve", "garnish", "season", "prepare"
        ]
        
        let lowercased = trimmed.lowercased()
        for verb in actionVerbs {
            if lowercased.starts(with: verb) || lowercased.contains(" \(verb) ") {
                return true
            }
        }
        
        return false
    }
    
    // Clean instruction line
    private static func cleanInstructionLine(_ line: String) -> String {
        var cleaned = line
        
        // Remove step numbers and bullets
        cleaned = cleaned.replacingOccurrences(of: "^[•\\-*]\\s*", with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "^Step\\s*[0-9]+[:.)]?\\s*", with: "", options: [.regularExpression, .caseInsensitive])
        cleaned = cleaned.replacingOccurrences(of: "^[0-9]+[:.)]\\s*", with: "", options: .regularExpression)
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Extract difficulty
    private static func extractDifficulty(from text: String) -> String? {
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
