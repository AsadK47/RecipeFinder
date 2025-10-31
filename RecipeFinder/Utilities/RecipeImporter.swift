import Foundation
import SwiftUI

/// Smart Recipe Importer - Extracts text from HTML and matches against USDA foods
/// Then feeds clean data into Recipe Wizard for guaranteed quality
class RecipeImporter: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var extractedData: ExtractedRecipeData?
    
    struct ExtractedRecipeData: Equatable {
        let name: String
        let matchedIngredients: [String]  // USDA-matched ingredients
        let rawText: String  // For preview/editing
        let instructions: [String]
        let sourceURL: URL
    }
    
    private func debugLog(_ message: String) {
        #if DEBUG
        print("[RecipeImporter] \(message)")
        #endif
    }
    
    /// Main import function - extracts recipe data and matches USDA ingredients
    func importRecipe(from urlString: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            extractedData = nil
        }
        
        debugLog("🌐 Starting smart import from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            await MainActor.run {
                errorMessage = "Invalid URL"
                isLoading = false
            }
            return
        }
        
        do {
            // 1. Fetch HTML
            debugLog("📥 Fetching HTML...")
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else {
                throw ImportError.invalidHTML
            }
            debugLog("✅ HTML fetched: \(html.count) chars")
            
            // 2. Extract recipe data (try Schema.org first, then fallback to text extraction)
            debugLog("🔍 Extracting recipe data...")
            let schemaRecipe = extractSchemaRecipe(from: html)
            
            let recipeName: String
            let ingredientTexts: [String]
            let instructions: [String]
            
            if let schema = schemaRecipe {
                recipeName = schema.name ?? "Imported Recipe"
                ingredientTexts = schema.recipeIngredient ?? []
                instructions = schema.recipeInstructions?.steps ?? []
                debugLog("✅ Extracted via Schema.org: \(ingredientTexts.count) ingredients")
            } else {
                // Fallback: extract from HTML text
                debugLog("⚠️ No Schema.org data, extracting from HTML text...")
                let extracted = extractFromHTML(html)
                recipeName = extracted.name
                ingredientTexts = extracted.ingredients
                instructions = extracted.instructions
                debugLog("✅ Extracted from HTML: \(ingredientTexts.count) ingredient lines")
            }
            
            // 3. Match ingredients against USDA food list
            debugLog("🎯 Matching ingredients against USDA foods...")
            let matchedIngredients = matchUSDAIngredients(from: ingredientTexts)
            debugLog("✅ Matched \(matchedIngredients.count) USDA ingredients")
            
            // 4. Return extracted data for Recipe Wizard
            let extracted = ExtractedRecipeData(
                name: recipeName,
                matchedIngredients: matchedIngredients,
                rawText: ingredientTexts.joined(separator: "\n"),
                instructions: instructions,
                sourceURL: url
            )
            
            await MainActor.run {
                extractedData = extracted
                isLoading = false
            }
            
        } catch {
            debugLog("❌ Import failed: \(error)")
            await MainActor.run {
                errorMessage = "Failed to import: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    /// Match ingredient texts against USDA food database - ENHANCED VERSION
    private func matchUSDAIngredients(from texts: [String]) -> [String] {
        let usdaFoods = USDAFoodsList.getAllFoods()
        let usdaLowercased = usdaFoods.map { $0.lowercased() }
        
        var matched: [String] = []
        var matchedLower: Set<String> = []
        
        // Common cooking words to skip
        let skipWords = Set(["and", "the", "with", "for", "into", "from", "about", "approximately", "roughly", "optional", "fresh", "dried", "chopped", "diced", "sliced", "minced", "grated", "shredded", "melted", "softened", "room", "temperature", "large", "small", "medium", "to", "taste", "as", "needed", "cup", "cups", "tbsp", "tsp", "tablespoon", "tablespoons", "teaspoon", "teaspoons", "ounce", "ounces", "oz", "pound", "pounds", "lb", "lbs", "gram", "grams", "g", "kg", "kilogram", "ml", "milliliter", "liter", "l", "pinch", "dash", "clove", "cloves"])
        
        for text in texts {
            let cleanText = text.lowercased()
                .replacingOccurrences(of: #"[^\w\s]"#, with: " ", options: .regularExpression)
                .replacingOccurrences(of: #"\d+\.?\d*"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)
            
            let words = cleanText.components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty && $0.count > 2 && !skipWords.contains($0) }
            
            // Strategy 1: Try exact multi-word matches first (e.g., "chicken breast")
            if words.count >= 2 {
                for i in 0..<words.count-1 {
                    let twoWords = "\(words[i]) \(words[i+1])"
                    if let matchIndex = usdaLowercased.firstIndex(where: { $0 == twoWords || $0.contains(twoWords) }) {
                        let match = usdaFoods[matchIndex]
                        if !matchedLower.contains(match.lowercased()) {
                            matched.append(match)
                            matchedLower.insert(match.lowercased())
                            debugLog("  ✓ Multi-word: \(match) from '\(twoWords)'")
                            break
                        }
                    }
                }
            }
            
            // Strategy 2: Try exact single food match
            for food in usdaFoods {
                let foodLower = food.lowercased()
                if cleanText == foodLower || cleanText.contains(" \(foodLower) ") || cleanText.starts(with: "\(foodLower) ") || cleanText.hasSuffix(" \(foodLower)") {
                    if !matchedLower.contains(foodLower) {
                        matched.append(food)
                        matchedLower.insert(foodLower)
                        debugLog("  ✓ Exact: \(food)")
                        break
                    }
                }
            }
            
            // Strategy 3: Look through individual words for food matches
            for word in words {
                // Skip if already found a match for this ingredient text
                if matched.count > matchedLower.count { break }
                
                // Try to find a food that matches or contains this word
                if let matchIndex = usdaLowercased.firstIndex(where: { foodLower in
                    let foodWords = foodLower.components(separatedBy: .whitespaces)
                    return foodWords.contains(word) || word.contains(foodLower) || foodLower.contains(word)
                }) {
                    let match = usdaFoods[matchIndex]
                    if !matchedLower.contains(match.lowercased()) {
                        matched.append(match)
                        matchedLower.insert(match.lowercased())
                        debugLog("  ≈ Fuzzy: \(match) from word '\(word)'")
                        break
                    }
                }
            }
            
            // Strategy 4: Partial matching - look for foods contained in the text
            if matched.count == matchedLower.count { // No match yet
                for (index, foodLower) in usdaLowercased.enumerated() {
                    if cleanText.contains(foodLower) && foodLower.count > 3 {
                        let match = usdaFoods[index]
                        if !matchedLower.contains(foodLower) {
                            matched.append(match)
                            matchedLower.insert(foodLower)
                            debugLog("  ~ Partial: \(match)")
                            break
                        }
                    }
                }
            }
        }
        
        debugLog("✅ Total matched: \(matched.count) unique ingredients")
        return matched
    }
    
    /// Extract from HTML when no Schema.org data available - ENHANCED VERSION
    private func extractFromHTML(_ html: String) -> (name: String, ingredients: [String], instructions: [String]) {
        // Strip HTML tags but preserve line breaks
        var text = html.replacingOccurrences(of: "<br[^>]*>", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "</p>", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "</li>", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "</div>", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "&nbsp;", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && $0.count > 3 }
        
        // SMART RECIPE NAME EXTRACTION
        var name = "Imported Recipe"
        
        // Try <title> tag first
        if let titleRange = html.range(of: "<title[^>]*>([^<]+)</title>", options: .regularExpression) {
            let titleText = String(html[titleRange])
            if let extracted = titleText.range(of: ">([^<]+)<", options: .regularExpression) {
                let rawTitle = String(titleText[extracted])
                    .replacingOccurrences(of: ">", with: "")
                    .replacingOccurrences(of: "<", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                // Clean up title (remove site names, separators)
                let cleaned = rawTitle
                    .components(separatedBy: ["|", "-", "–", "—"])
                    .first?
                    .trimmingCharacters(in: .whitespaces) ?? rawTitle
                
                if cleaned.count > 3 && cleaned.count < 100 {
                    name = cleaned
                }
            }
        }
        
        // Fallback: Look for <h1> tags
        if name == "Imported Recipe" {
            if let h1Range = html.range(of: "<h1[^>]*>([^<]+)</h1>", options: .regularExpression) {
                let h1Text = String(html[h1Range])
                if let extracted = h1Text.range(of: ">([^<]+)<", options: .regularExpression) {
                    let rawH1 = String(h1Text[extracted])
                        .replacingOccurrences(of: ">", with: "")
                        .replacingOccurrences(of: "<", with: "")
                        .trimmingCharacters(in: .whitespaces)
                    if rawH1.count > 3 && rawH1.count < 100 {
                        name = rawH1
                    }
                }
            }
        }
        
        // SMART INGREDIENT EXTRACTION
        var ingredientLines: [String] = []
        
        // Look for sections with "ingredient" in nearby text
        var inIngredientSection = false
        var foundIngredientHeader = false
        
        for (index, line) in lines.enumerated() {
            let lowercased = line.lowercased()
            
            // Check if this is an ingredient section header
            if lowercased.contains("ingredient") && line.count < 50 {
                inIngredientSection = true
                foundIngredientHeader = true
                continue
            }
            
            // Check if we've left the ingredient section
            if inIngredientSection && 
               (lowercased.contains("instruction") || 
                lowercased.contains("direction") || 
                lowercased.contains("preparation") ||
                lowercased.contains("method")) {
                inIngredientSection = false
            }
            
            // Extract ingredient-like lines
            if inIngredientSection || !foundIngredientHeader {
                let hasNumber = line.range(of: #"[\d/]"#, options: .regularExpression) != nil
                let hasUnit = ["cup", "cups", "tbsp", "tsp", "teaspoon", "tablespoon", "oz", "ounce", "lb", "pound", "gram", "g", "kg", "ml", "liter", "clove", "pinch", "dash", "slice"].contains(where: { lowercased.contains($0) })
                let hasFoodWord = ["chicken", "beef", "pork", "fish", "egg", "flour", "sugar", "salt", "pepper", "oil", "butter", "cheese", "milk", "cream", "tomato", "onion", "garlic", "rice", "pasta", "bread"].contains(where: { lowercased.contains($0) })
                let isShort = line.count < 150
                
                if (hasNumber && hasUnit) || (hasNumber && hasFoodWord) || (hasFoodWord && isShort) {
                    // Skip if it looks like a title or instruction
                    if !lowercased.contains("step") && !lowercased.contains("preheat") {
                        ingredientLines.append(line)
                    }
                }
            }
            
            if ingredientLines.count >= 30 { break }
        }
        
        // SMART INSTRUCTION EXTRACTION
        var instructionLines: [String] = []
        var inInstructionSection = false
        var currentInstruction = ""
        
        for line in lines {
            let lowercased = line.lowercased()
            
            // Check if this is an instruction section header
            if (lowercased.contains("instruction") || 
                lowercased.contains("direction") || 
                lowercased.contains("preparation") ||
                lowercased.contains("method") ||
                lowercased.contains("step")) && line.count < 50 {
                inInstructionSection = true
                continue
            }
            
            if inInstructionSection {
                // Look for instruction-like content
                let hasVerb = ["add", "mix", "stir", "cook", "heat", "bake", "boil", "fry", "season", "place", "pour", "combine", "whisk", "blend", "chop", "cut", "slice", "dice", "preheat", "serve"].contains(where: { lowercased.contains($0) })
                let isReasonableLength = line.count > 20 && line.count < 500
                let startsWithNumber = line.first?.isNumber == true
                
                if (hasVerb && isReasonableLength) || startsWithNumber {
                    // If previous instruction was building up, save it
                    if !currentInstruction.isEmpty {
                        instructionLines.append(currentInstruction)
                        currentInstruction = ""
                    }
                    
                    currentInstruction = line
                    
                    // If line seems complete, add it
                    if line.hasSuffix(".") || line.hasSuffix("!") || startsWithNumber {
                        instructionLines.append(currentInstruction)
                        currentInstruction = ""
                    }
                } else if !currentInstruction.isEmpty && isReasonableLength {
                    // Continue building current instruction
                    currentInstruction += " " + line
                    if line.hasSuffix(".") || line.hasSuffix("!") {
                        instructionLines.append(currentInstruction)
                        currentInstruction = ""
                    }
                }
            }
            
            if instructionLines.count >= 25 { break }
        }
        
        // Add any remaining instruction
        if !currentInstruction.isEmpty {
            instructionLines.append(currentInstruction)
        }
        
        // If we didn't find enough, try broader search
        if ingredientLines.count < 3 {
            ingredientLines = lines.filter { line in
                let lowercased = line.lowercased()
                let hasNumber = line.range(of: #"[\d/]"#, options: .regularExpression) != nil
                let hasUnit = ["cup", "tbsp", "tsp", "oz", "gram", "ml"].contains(where: { lowercased.contains($0) })
                return hasNumber && hasUnit && line.count < 150
            }
        }
        
        if instructionLines.count < 3 {
            instructionLines = lines.filter { line in
                let lowercased = line.lowercased()
                let hasVerb = ["add", "mix", "cook", "heat", "bake", "place"].contains(where: { lowercased.contains($0) })
                let words = line.components(separatedBy: .whitespaces)
                return hasVerb && words.count > 8 && words.count < 60
            }
        }
        
        debugLog("📝 Extracted: name='\(name)', \(ingredientLines.count) ingredients, \(instructionLines.count) instructions")
        
        return (name, Array(ingredientLines.prefix(30)), Array(instructionLines.prefix(20)))
    }
    
    // Keep Schema.org extraction for sites that support it
    private func extractSchemaRecipe(from html: String) -> SchemaRecipe? {
        let pattern = #"<script[^>]*type\s*=\s*["\']application/ld\+json["\'][^>]*>(.*?)</script>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return nil
        }
        
        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, range: range)
        
        for match in matches {
            guard let jsonRange = Range(match.range(at: 1), in: html) else { continue }
            let jsonString = String(html[jsonRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            guard let jsonData = jsonString.data(using: .utf8) else { continue }
            
            // Try single recipe
            if let recipe = try? JSONDecoder().decode(SchemaRecipe.self, from: jsonData), recipe.name != nil {
                return recipe
            }
            
            // Try array
            if let array = try? JSONDecoder().decode([SchemaRecipe].self, from: jsonData),
               let recipe = array.first(where: { $0.name != nil }) {
                return recipe
            }
            
            // Try @graph
            if let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               let graph = json["@graph"] as? [[String: Any]] {
                for item in graph {
                    let isRecipe: Bool
                    if let typeString = item["@type"] as? String {
                        isRecipe = typeString == "Recipe"
                    } else if let typeArray = item["@type"] as? [String] {
                        isRecipe = typeArray.contains("Recipe")
                    } else {
                        isRecipe = false
                    }
                    
                    if isRecipe, let itemData = try? JSONSerialization.data(withJSONObject: item),
                       let recipe = try? JSONDecoder().decode(SchemaRecipe.self, from: itemData) {
                        return recipe
                    }
                }
            }
        }
        
        return nil
    }
}

// Simplified Schema.org Recipe Structure (only what we need)
struct SchemaRecipe: Codable {
    let name: String?
    let recipeIngredient: [String]?
    let recipeInstructions: InstructionType?
    
    enum InstructionType: Codable {
        case string(String)
        case array([InstructionStep])
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let string = try? container.decode(String.self) {
                self = .string(string)
            } else if let array = try? container.decode([InstructionStep].self) {
                self = .array(array)
            } else {
                self = .string("")
            }
        }
        
        var steps: [String] {
            switch self {
            case .string(let text):
                return text.components(separatedBy: .newlines)
                    .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            case .array(let steps):
                return steps.compactMap { $0.text }
            }
        }
    }
    
    struct InstructionStep: Codable {
        let text: String?
    }
}

// Errors
enum ImportError: LocalizedError {
    case invalidHTML
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidHTML:
            return "Could not read webpage content"
        case .noData:
            return "No recipe data found on this page"
        }
    }
}
