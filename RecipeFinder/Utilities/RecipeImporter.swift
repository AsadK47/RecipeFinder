import Foundation
import SwiftUI

// Schema.org Recipe Structure
struct SchemaRecipe: Codable {
    let name: String?
    let description: String?
    let image: ImageType?
    let recipeIngredient: [String]?
    let recipeInstructions: InstructionType?
    let prepTime: String?
    let cookTime: String?
    let totalTime: String?
    let recipeYield: YieldType?
    let recipeCategory: String?
    let recipeCuisine: String?
    let keywords: String?
    
    enum CodingKeys: String, CodingKey {
        case name, description, image
        case recipeIngredient, recipeInstructions
        case prepTime, cookTime, totalTime, recipeYield
        case recipeCategory, recipeCuisine, keywords
    }
    
    // Handle different image formats
    enum ImageType: Codable {
        case string(String)
        case object([String: String])
        case array([String])
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let string = try? container.decode(String.self) {
                self = .string(string)
            } else if let object = try? container.decode([String: String].self) {
                self = .object(object)
            } else if let array = try? container.decode([String].self) {
                self = .array(array)
            } else {
                self = .string("")
            }
        }
        
        var url: String? {
            switch self {
            case .string(let url): return url
            case .object(let dict): return dict["url"]
            case .array(let urls): return urls.first
            }
        }
    }
    
    // Handle different instruction formats
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
                // Split by newlines or periods
                return text.components(separatedBy: .newlines)
                    .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            case .array(let steps):
                return steps.compactMap { $0.text }
            }
        }
    }
    
    struct InstructionStep: Codable {
        let text: String?
        
        enum CodingKeys: String, CodingKey {
            case text
        }
    }
    
    // Handle different yield formats
    enum YieldType: Codable {
        case string(String)
        case int(Int)
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let int = try? container.decode(Int.self) {
                self = .int(int)
            } else if let string = try? container.decode(String.self) {
                self = .string(string)
            } else {
                self = .int(4)
            }
        }
        
        var servings: Int {
            switch self {
            case .int(let count): return count
            case .string(let text):
                // Extract first number from string like "Serves 4" or "4 servings"
                let numbers = text.components(separatedBy: CharacterSet.decimalDigits.inverted)
                    .compactMap { Int($0) }
                return numbers.first ?? 4
            }
        }
    }
}

// Recipe Importer
class RecipeImporter: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var debugInfo: String?
    @Published var importedRecipe: RecipeModel?
    
    // swiftlint:disable:next function_body_length
    func importRecipe(from urlString: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            debugInfo = nil
            importedRecipe = nil
        }
        
        debugLog("🌐 Starting import from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            debugLog("❌ Invalid URL")
            await MainActor.run {
                errorMessage = "Invalid URL"
                debugInfo = "The URL format is not valid"
                isLoading = false
            }
            return
        }
        
        do {
            // Fetch HTML content
            debugLog("📥 Fetching HTML content...")
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                debugLog("✅ HTTP Status: \(httpResponse.statusCode)")
                await MainActor.run {
                    debugInfo = "HTTP Status: \(httpResponse.statusCode), Size: \(data.count) bytes"
                }
            }
            
            debugLog("✅ Received \(data.count) bytes")
            
            guard let html = String(data: data, encoding: .utf8) else {
                debugLog("❌ Failed to decode HTML")
                throw ImportError.invalidHTML
            }
            
            debugLog("✅ HTML decoded, length: \(html.count) characters")
            
            // Extract Schema.org JSON-LD
            debugLog("🔍 Extracting Schema.org recipe data...")
            guard let schemaRecipe = extractSchemaRecipe(from: html) else {
                debugLog("❌ No schema recipe found")
                await MainActor.run {
                    debugInfo = "HTML: \(html.count) chars. No Schema.org recipe data found. This site may use a different format."
                }
                throw ImportError.noSchemaFound
            }
            
            debugLog("✅ Schema recipe extracted: \(schemaRecipe.name ?? "unnamed")")
            
            // Convert to RecipeModel
            debugLog("🔄 Converting to RecipeModel...")
            let recipe = try convertToRecipeModel(schemaRecipe, sourceURL: url)
            debugLog("✅ Recipe converted successfully!")
            
            await MainActor.run {
                importedRecipe = recipe
                debugInfo = nil
                isLoading = false
            }
            
        } catch ImportError.noSchemaFound {
            debugLog("❌ Import failed: No schema found")
            await MainActor.run {
                errorMessage = "This website doesn't support automatic import"
                debugInfo = "Try sites like AllRecipes, Food Network, or Serious Eats. Or copy the recipe manually."
                isLoading = false
            }
        } catch ImportError.missingRequiredField(let field) {
            debugLog("❌ Import failed: Missing field \(field)")
            await MainActor.run {
                errorMessage = "Recipe data is incomplete"
                debugInfo = "Missing required field: \(field)"
                isLoading = false
            }
        } catch {
            debugLog("❌ Import failed: \(error)")
            await MainActor.run {
                errorMessage = "Failed to import recipe"
                debugInfo = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    private func extractSchemaRecipe(from html: String) -> SchemaRecipe? {
        // Find JSON-LD script tags with more flexible pattern
        // This pattern handles various formatting and whitespace
        let pattern = #"<script[^>]*type\s*=\s*["\']application/ld\+json["\'][^>]*>(.*?)</script>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            debugLog("❌ Failed to create regex")
            return nil
        }
        
        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, range: range)
        debugLog("🔍 Found \(matches.count) JSON-LD script tags")
        
        // If no JSON-LD found, try to find recipe data in other formats
        if matches.isEmpty {
            debugLog("⚠️ No JSON-LD found, trying alternate patterns...")
            return tryAlternatePatterns(in: html)
        }
        
        for (index, match) in matches.enumerated() {
            guard let jsonRange = Range(match.range(at: 1), in: html) else { 
                debugLog("  ⚠️ Skipping match #\(index + 1) - couldn't extract range")
                continue 
            }
            let jsonString = String(html[jsonRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty or very short JSON
            guard jsonString.count > 10 else {
                debugLog("  ⚠️ Skipping match #\(index + 1) - too short (\(jsonString.count) chars)")
                continue
            }
            
            guard let jsonData = jsonString.data(using: .utf8) else { 
                debugLog("  ⚠️ Skipping match #\(index + 1) - couldn't convert to data")
                continue 
            }
            
            debugLog("📋 Processing JSON-LD block #\(index + 1) (\(jsonString.count) chars)")
            
            // Show first 200 chars of JSON for debugging
            let preview = String(jsonString.prefix(200))
            debugLog("  📄 JSON preview: \(preview)...")
            
            // Try to decode as single recipe
            do {
                let recipe = try JSONDecoder().decode(SchemaRecipe.self, from: jsonData)
                if recipe.name != nil {
                    debugLog("✅ Found recipe (single object): \(recipe.name ?? "")")
                    return recipe
                } else {
                    debugLog("  ⚠️ Decoded but no name field")
                }
            } catch {
                debugLog("  ⚠️ Not a single recipe: \(error.localizedDescription)")
            }
            
            // Try to decode as array and find Recipe type
            do {
                let array = try JSONDecoder().decode([SchemaRecipe].self, from: jsonData)
                if let recipe = array.first(where: { $0.name != nil }) {
                    debugLog("✅ Found recipe (array): \(recipe.name ?? "")")
                    return recipe
                } else {
                    debugLog("  ⚠️ Array decoded but no recipe with name found")
                }
            } catch {
                debugLog("  ⚠️ Not an array: \(error.localizedDescription)")
            }
            
            // Try to decode as wrapper object with @graph
            if let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                debugLog("📊 Decoded as dictionary, keys: \(json.keys.joined(separator: ", "))")
                
                if let graph = json["@graph"] as? [[String: Any]] {
                    debugLog("📈 Found @graph with \(graph.count) items")
                    
                    for (itemIndex, item) in graph.enumerated() {
                        // Check if this item is a Recipe
                        let isRecipe: Bool
                        let typeName: String
                        
                        if let typeString = item["@type"] as? String {
                            typeName = typeString
                            isRecipe = typeString == "Recipe"
                        } else if let typeArray = item["@type"] as? [String] {
                            typeName = typeArray.joined(separator: ", ")
                            isRecipe = typeArray.contains("Recipe")
                        } else {
                            typeName = "unknown"
                            isRecipe = false
                        }
                        
                        if itemIndex < 3 || isRecipe { // Only log first 3 or recipes
                            debugLog("  Item #\(itemIndex + 1): type=\(typeName), isRecipe=\(isRecipe)")
                        }
                        
                        if isRecipe {
                            if let name = item["name"] as? String, !name.isEmpty {
                                debugLog("  ✅ Found Recipe with name: \(name)")
                                // Found a recipe, try to decode it
                                if let itemData = try? JSONSerialization.data(withJSONObject: item) {
                                    do {
                                        let recipe = try JSONDecoder().decode(SchemaRecipe.self, from: itemData)
                                        debugLog("  ✅ Successfully decoded recipe!")
                                        return recipe
                                    } catch {
                                        debugLog("  ❌ Failed to decode recipe: \(error)")
                                    }
                                }
                            } else {
                                debugLog("  ⚠️ Recipe found but no name")
                            }
                        }
                    }
                } else {
                    debugLog("  ℹ️ No @graph found in this JSON")
                }
            }
        }
        
        debugLog("❌ No valid recipe found in any JSON-LD block")
        return nil
    }
    
    private func tryAlternatePatterns(in html: String) -> SchemaRecipe? {
        debugLog("🔍 Trying alternate recipe detection patterns...")
        
        // Pattern 1: Look for JSON embedded in JavaScript variables
        let jsPatterns = [
            #"var\s+recipe\s*=\s*(\{[^;]+\});"#,
            #"window\.recipe\s*=\s*(\{[^;]+\});"#,
            #"recipe:\s*(\{[^}]+\})"#
        ]
        
        for pattern in jsPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                let jsonString = String(html[range])
                debugLog("  📋 Found potential recipe in JS variable")
                if let data = jsonString.data(using: .utf8),
                   let recipe = try? JSONDecoder().decode(SchemaRecipe.self, from: data),
                   recipe.name != nil {
                    debugLog("  ✅ Successfully decoded recipe from JS")
                    return recipe
                }
            }
        }
        
        // Pattern 2: Look for WordPress/Elementor recipe format
        if html.contains("wp-content") || html.contains("elementor") {
            debugLog("  ℹ️ Detected WordPress/Elementor site - checking for recipe card")
            return tryWordPressRecipe(in: html)
        }
        
        debugLog("  ❌ No alternate patterns found")
        return nil
    }
    
    private func tryWordPressRecipe(in html: String) -> SchemaRecipe? {
        // Try to extract from common WordPress recipe card plugins
        // This is a simplified version - would need enhancement for production
        debugLog("  🔍 Checking for WordPress recipe card...")
        
        // Look for WP Recipe Maker format
        if html.contains("wprm-recipe") {
            debugLog("  ℹ️ Found WP Recipe Maker format (not yet supported)")
        }
        
        // Look for Tasty Recipes format
        if html.contains("tasty-recipes") {
            debugLog("  ℹ️ Found Tasty Recipes format (not yet supported)")
        }
        
        return nil
    }
    
    private func convertToRecipeModel(_ schema: SchemaRecipe, sourceURL: URL) throws -> RecipeModel {
        guard let name = schema.name else {
            throw ImportError.missingRequiredField("name")
        }
        
        // Parse ingredients
        let ingredients = (schema.recipeIngredient ?? []).compactMap { ingredientString in
            IngredientParser.parse(ingredientString)
        }
        
        guard !ingredients.isEmpty else {
            throw ImportError.missingRequiredField("ingredients")
        }
        
        // Parse instructions
        let instructions = schema.recipeInstructions?.steps ?? []
        guard !instructions.isEmpty else {
            throw ImportError.missingRequiredField("instructions")
        }
        
        // Parse times
        let prepTime = parseTime(schema.prepTime) ?? "15 minutes"
        let cookTime = parseTime(schema.cookTime) ?? parseTime(schema.totalTime) ?? "30 minutes"
        
        // Parse servings
        let servings = schema.recipeYield?.servings ?? 4
        
        // Determine category and difficulty
        let category = determineCategory(from: schema)
        let difficulty = "Medium" // Default, could be smarter
        
        // Handle image
        let imageName = downloadImage(from: schema.image?.url, recipeName: name)
        
        return RecipeModel(
            name: name,
            category: category,
            difficulty: difficulty,
            prepTime: prepTime,
            cookingTime: cookTime,
            baseServings: servings,
            currentServings: servings,
            ingredients: ingredients,
            prePrepInstructions: [], // Could parse from description
            instructions: instructions,
            notes: schema.description ?? "",
            imageName: imageName
        )
    }
    
    private func parseTime(_ isoTime: String?) -> String? {
        guard let time = isoTime else { return nil }
        
        // Parse ISO 8601 duration (PT15M, PT1H30M, etc.)
        let pattern = #"PT(?:(\d+)H)?(?:(\d+)M)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: time, range: NSRange(time.startIndex..., in: time)) else {
            return nil
        }
        
        var totalMinutes = 0
        
        if let hoursRange = Range(match.range(at: 1), in: time),
           let hours = Int(time[hoursRange]) {
            totalMinutes += hours * 60
        }
        
        if let minutesRange = Range(match.range(at: 2), in: time),
           let minutes = Int(time[minutesRange]) {
            totalMinutes += minutes
        }
        
        return "\(totalMinutes) minutes"
    }
    
    private func determineCategory(from schema: SchemaRecipe) -> String {
        if let category = schema.recipeCategory {
            return category
        }
        
        if let cuisine = schema.recipeCuisine {
            return cuisine
        }
        
        if let keywords = schema.keywords {
            // Try to extract category from keywords
            let categories = ["Breakfast", "Lunch", "Dinner", "Dessert", "Snack", "Appetizer"]
            for cat in categories where keywords.localizedCaseInsensitiveContains(cat) {
                return cat
            }
        }
        
        return "Main Course"
    }
    
    private func downloadImage(from urlString: String?, recipeName: String) -> String? {
        // For now, return nil - image downloading will be implemented separately
        // This would involve downloading the image and saving it to Assets
        return nil
    }
}

// Ingredient Parser
struct IngredientParser {
    static func parse(_ ingredientString: String) -> Ingredient? {
        let normalized = ingredientString.trimmingCharacters(in: .whitespaces)
        
        // Pattern to match: "2 cups flour" or "1/2 teaspoon salt" or "2-3 cloves garlic"
        let pattern = #"^([\d./\-]+)?\s*([a-zA-Z]+)?\s*(.+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: normalized, range: NSRange(normalized.startIndex..., in: normalized)) else {
            // No quantity found, treat as simple ingredient
            return Ingredient(baseQuantity: 1, unit: "", name: normalized)
        }
        
        var quantity: Double = 1.0
        var unit = ""
        var name = normalized
        
        // Extract quantity
        if let quantityRange = Range(match.range(at: 1), in: normalized) {
            let quantityStr = String(normalized[quantityRange]).trimmingCharacters(in: .whitespaces)
            quantity = parseFraction(quantityStr)
        }
        
        // Extract unit
        if let unitRange = Range(match.range(at: 2), in: normalized) {
            unit = String(normalized[unitRange]).trimmingCharacters(in: .whitespaces)
        }
        
        // Extract name (everything else)
        if let nameRange = Range(match.range(at: 3), in: normalized) {
            name = String(normalized[nameRange]).trimmingCharacters(in: .whitespaces)
        }
        
        return Ingredient(baseQuantity: quantity, unit: unit, name: name)
    }
    
    private static func parseFraction(_ string: String) -> Double {
        // Handle fractions like "1/2", "2-3", "1.5"
        if string.contains("/") {
            let parts = string.components(separatedBy: "/")
            if parts.count == 2,
               let numerator = Double(parts[0]),
               let denominator = Double(parts[1]) {
                return numerator / denominator
            }
        }
        
        if string.contains("-") {
            // Take average of range like "2-3"
            let parts = string.components(separatedBy: "-")
            if parts.count == 2,
               let min = Double(parts[0]),
               let max = Double(parts[1]) {
                return (min + max) / 2
            }
        }
        
        return Double(string) ?? 1.0
    }
}

// Errors
enum ImportError: LocalizedError {
    case invalidHTML
    case noSchemaFound
    case missingRequiredField(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidHTML:
            return "Could not read webpage content"
        case .noSchemaFound:
            return "No recipe data found on this page"
        case .missingRequiredField(let field):
            return "Recipe is missing required field: \(field)"
        }
    }
}
