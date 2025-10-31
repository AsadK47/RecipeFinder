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
        
        // Check for WPRM (WP Recipe Maker) plugin format first
        if let wprm = extractWPRM(from: html) {
            return wprm
        }
        
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
    
    // WPRM Plugin Support
    
    /// Extract recipe from WPRM (WP Recipe Maker) plugin format
    /// This plugin is used by many WordPress recipe sites
    private static func extractWPRM(from html: String) -> ParsedRecipe? {
        // Check if this is a WPRM recipe
        guard html.contains("wprm-recipe") || html.contains("wp-recipe-maker") else {
            return nil
        }
        
        var result = ParsedRecipe()
        result.confidence = 0.95 // High confidence for structured data
        
        // Extract recipe name from wprm-recipe-name class
        if let nameMatch = html.range(of: "class=\"wprm-recipe-name[^\"]*\">([^<]+)<", options: .regularExpression) {
            let matched = String(html[nameMatch])
            if let contentRange = matched.range(of: ">([^<]+)<", options: .regularExpression) {
                var name = String(matched[contentRange])
                    .replacingOccurrences(of: ">", with: "")
                    .replacingOccurrences(of: "<", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                // Decode HTML entities
                name = decodeHTMLEntities(name)
                result.name = name
            }
        }
        
        // Extract times - look for the time values in the class structure
        // The actual time value is in a span like: <span class="wprm-recipe-prep_time-minutes">15</span>
        let prepTimePattern = #"wprm-recipe-prep_time-minutes[^>]*>(\d+)<"#
        if let regex = try? NSRegularExpression(pattern: prepTimePattern, options: []) {
            let nsString = html as NSString
            if let match = regex.firstMatch(in: html, options: [], range: NSRange(location: 0, length: nsString.length)) {
                let minutesRange = match.range(at: 1)
                let minutesStr = nsString.substring(with: minutesRange)
                if let minutes = Int(minutesStr) {
                    result.prepTime = minutes
                }
            }
        }
        
        let cookTimePattern = #"wprm-recipe-cook_time-minutes[^>]*>(\d+)<"#
        if let regex = try? NSRegularExpression(pattern: cookTimePattern, options: []) {
            let nsString = html as NSString
            if let match = regex.firstMatch(in: html, options: [], range: NSRange(location: 0, length: nsString.length)) {
                let minutesRange = match.range(at: 1)
                let minutesStr = nsString.substring(with: minutesRange)
                if let minutes = Int(minutesStr) {
                    result.cookTime = minutes
                }
            }
        }
        
        // Fallback: Try data-minutes attribute if above patterns don't work
        if result.prepTime == nil {
            let prepDataPattern = #"wprm-recipe-prep[^>]*?data-minutes="(\d+)""#
            if let regex = try? NSRegularExpression(pattern: prepDataPattern, options: []) {
                let nsString = html as NSString
                if let match = regex.firstMatch(in: html, options: [], range: NSRange(location: 0, length: nsString.length)) {
                    let minutesRange = match.range(at: 1)
                    let minutesStr = nsString.substring(with: minutesRange)
                    if let minutes = Int(minutesStr) {
                        result.prepTime = minutes
                    }
                }
            }
        }
        
        if result.cookTime == nil {
            let cookDataPattern = #"wprm-recipe-cook[^>]*?data-minutes="(\d+)""#
            if let regex = try? NSRegularExpression(pattern: cookDataPattern, options: []) {
                let nsString = html as NSString
                if let match = regex.firstMatch(in: html, options: [], range: NSRange(location: 0, length: nsString.length)) {
                    let minutesRange = match.range(at: 1)
                    let minutesStr = nsString.substring(with: minutesRange)
                    if let minutes = Int(minutesStr) {
                        result.cookTime = minutes
                    }
                }
            }
        }
        
        // Extract servings - the value is in the text content of the servings span
        // Pattern: <span class="wprm-recipe-servings..." data-recipe="22976">4</span>
        let servingsPattern = #"wprm-recipe-servings[^>]*data-recipe="\d+"[^>]*>(\d+)<"#
        if let regex = try? NSRegularExpression(pattern: servingsPattern, options: []) {
            let nsString = html as NSString
            if let match = regex.firstMatch(in: html, options: [], range: NSRange(location: 0, length: nsString.length)) {
                let servingsRange = match.range(at: 1)
                let servingsStr = nsString.substring(with: servingsRange)
                if let servings = Int(servingsStr), servings >= 1 && servings <= 100 {
                    result.servings = servings
                }
            }
        }
        
        // Fallback: Try data-servings attribute
        if result.servings == nil {
            let dataServingsPattern = #"wprm-recipe-servings[^>]*?data-servings="(\d+)""#
            if let regex = try? NSRegularExpression(pattern: dataServingsPattern, options: []) {
                let nsString = html as NSString
                if let match = regex.firstMatch(in: html, options: [], range: NSRange(location: 0, length: nsString.length)) {
                    let servingsRange = match.range(at: 1)
                    let servingsStr = nsString.substring(with: servingsRange)
                    if let servings = Int(servingsStr), servings >= 1 && servings <= 100 {
                        result.servings = servings
                    }
                }
            }
        }
        
        // Extract ingredients from wprm-recipe-ingredient with proper parsing
        var ingredients: [String] = []
        
        // Pattern to match each ingredient <li> tag
        let ingredientPattern = #"<li[^>]*class="[^"]*wprm-recipe-ingredient[^"]*"[^>]*>([\s\S]*?)</li>"#
        
        if let regex = try? NSRegularExpression(pattern: ingredientPattern, options: []) {
            let nsString = html as NSString
            let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for match in matches {
                let liContent = nsString.substring(with: match.range)
                
                var amount = ""
                var unit = ""
                var name = ""
                var notes = ""
                
                // Extract amount from wprm-recipe-ingredient-amount
                let amountPattern = #"class="wprm-recipe-ingredient-amount">([^<]+)<"#
                if let amountRegex = try? NSRegularExpression(pattern: amountPattern, options: []) {
                    let amountMatches = amountRegex.matches(in: liContent, options: [], range: NSRange(location: 0, length: (liContent as NSString).length))
                    if let firstMatch = amountMatches.first, firstMatch.numberOfRanges > 1 {
                        let amountRange = firstMatch.range(at: 1)
                        amount = (liContent as NSString).substring(with: amountRange).trimmingCharacters(in: .whitespaces)
                    }
                }
                
                // Extract unit from wprm-recipe-ingredient-unit
                let unitPattern = #"class="wprm-recipe-ingredient-unit">([^<]+)<"#
                if let unitRegex = try? NSRegularExpression(pattern: unitPattern, options: []) {
                    let unitMatches = unitRegex.matches(in: liContent, options: [], range: NSRange(location: 0, length: (liContent as NSString).length))
                    if let firstMatch = unitMatches.first, firstMatch.numberOfRanges > 1 {
                        let unitRange = firstMatch.range(at: 1)
                        unit = (liContent as NSString).substring(with: unitRange).trimmingCharacters(in: .whitespaces)
                    }
                }
                
                // Extract name from wprm-recipe-ingredient-name
                let namePattern = #"class="wprm-recipe-ingredient-name">([^<]+)<"#
                if let nameRegex = try? NSRegularExpression(pattern: namePattern, options: []) {
                    let nameMatches = nameRegex.matches(in: liContent, options: [], range: NSRange(location: 0, length: (liContent as NSString).length))
                    if let firstMatch = nameMatches.first, firstMatch.numberOfRanges > 1 {
                        let nameRange = firstMatch.range(at: 1)
                        name = (liContent as NSString).substring(with: nameRange).trimmingCharacters(in: .whitespaces)
                    }
                }
                
                // Extract notes from wprm-recipe-ingredient-notes (optional)
                let notesPattern = #"class="wprm-recipe-ingredient-notes[^\"]*\">([^<]+)<"#
                if let notesRegex = try? NSRegularExpression(pattern: notesPattern, options: []) {
                    let notesMatches = notesRegex.matches(in: liContent, options: [], range: NSRange(location: 0, length: (liContent as NSString).length))
                    if let firstMatch = notesMatches.first, firstMatch.numberOfRanges > 1 {
                        let notesRange = firstMatch.range(at: 1)
                        notes = (liContent as NSString).substring(with: notesRange).trimmingCharacters(in: .whitespaces)
                    }
                }
                
                // Build the full ingredient string
                
                var fullIngredient = ""
                if !amount.isEmpty {
                    fullIngredient += amount + " "
                }
                if !unit.isEmpty {
                    fullIngredient += unit + " "
                }
                if !name.isEmpty {
                    fullIngredient += name
                }
                if !notes.isEmpty {
                    fullIngredient += ", " + notes
                }
                
                // Decode HTML entities
                fullIngredient = decodeHTMLEntities(fullIngredient.trimmingCharacters(in: .whitespaces))
                
                if !fullIngredient.isEmpty && !ingredients.contains(fullIngredient) {
                    ingredients.append(fullIngredient)
                }
            }
        }
        
        result.ingredients = ingredients
        
        // Extract instructions from wprm-recipe-instruction-text
        var instructions: [String] = []
        
        // Pattern to match the entire instruction list item
        let instructionPattern = #"<li[^>]*class="[^"]*wprm-recipe-instruction[^"]*"[^>]*>([\s\S]*?)</li>"#
        
        if let regex = try? NSRegularExpression(pattern: instructionPattern, options: []) {
            let nsString = html as NSString
            let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for match in matches {
                let liContent = nsString.substring(with: match.range)
                
                // Look for the instruction-text div and extract its content
                let textPattern = #"wprm-recipe-instruction-text[^>]*>([\s\S]*?)</div>"#
                if let textRegex = try? NSRegularExpression(pattern: textPattern, options: []) {
                    let textMatches = textRegex.matches(in: liContent, options: [], range: NSRange(location: 0, length: (liContent as NSString).length))
                    
                    if let textMatch = textMatches.first {
                        let textRange = textMatch.range(at: 1)
                        var instruction = (liContent as NSString).substring(with: textRange)
                        
                        // Clean up: remove HTML tags, normalize whitespace, decode entities
                        instruction = instruction.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
                        instruction = instruction.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                        instruction = decodeHTMLEntities(instruction)
                        instruction = instruction.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if !instruction.isEmpty && instruction.count >= 10 {
                            instructions.append(instruction)
                        }
                    }
                }
            }
        }
        
        result.instructions = instructions
        
        // Extract cuisine
        if let cuisineMatch = html.range(of: "wprm-recipe-cuisine[^>]*>([^<]+)<", options: .regularExpression) {
            let matched = String(html[cuisineMatch])
            if let contentRange = matched.range(of: ">([^<]+)<", options: .regularExpression) {
                let cuisine = String(matched[contentRange])
                    .replacingOccurrences(of: ">", with: "")
                    .replacingOccurrences(of: "<", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                result.cuisine = cuisine
            }
        }
        
        // Extract course (category)
        if let courseMatch = html.range(of: "wprm-recipe-course[^>]*>([^<]+)<", options: .regularExpression) {
            let matched = String(html[courseMatch])
            if let contentRange = matched.range(of: ">([^<]+)<", options: .regularExpression) {
                let course = String(matched[contentRange])
                    .replacingOccurrences(of: ">", with: "")
                    .replacingOccurrences(of: "<", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                result.category = course
            }
        }
        
        // Only return if we found the essential data
        if result.name != nil && !result.ingredients.isEmpty && !result.instructions.isEmpty {
            return result
        }
        
        // If we found some data but not instructions, try fallback extraction
        if result.name != nil && !result.ingredients.isEmpty {
            // Try to extract instructions using general method
            let text = cleanHTML(html)
            let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            let fallbackInstructions = extractInstructions(from: text, lines: lines)
            
            if !fallbackInstructions.isEmpty {
                result.instructions = fallbackInstructions
                return result
            }
        }
        
        return nil
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
        
        // Common named entities
        let entities: [String: String] = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&apos;": "'",
            "&nbsp;": " ",
            "&frac12;": "½",
            "&frac14;": "¼",
            "&frac34;": "¾",
            "&ndash;": "–",
            "&mdash;": "—",
            "&hellip;": "…"
        ]
        
        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        
        // Decode numeric entities like &#39; and &#039;
        // Pattern: &#\d+;
        let numericPattern = "&#(\\d+);"
        if let regex = try? NSRegularExpression(pattern: numericPattern, options: []) {
            let nsString = result as NSString
            let matches = regex.matches(in: result, options: [], range: NSRange(location: 0, length: nsString.length))
            
            // Process matches in reverse to avoid index issues
            for match in matches.reversed() {
                let fullRange = match.range
                let numberRange = match.range(at: 1)
                let numberStr = nsString.substring(with: numberRange)
                
                if let charCode = Int(numberStr),
                   let unicode = UnicodeScalar(charCode) {
                    let char = String(Character(unicode))
                    let fullMatch = nsString.substring(with: fullRange)
                    result = result.replacingOccurrences(of: fullMatch, with: char)
                }
            }
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
