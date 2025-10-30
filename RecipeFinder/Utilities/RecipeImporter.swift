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
    
    /// Match ingredient texts against USDA food database
    private func matchUSDAIngredients(from texts: [String]) -> [String] {
        let usdaFoods = USDAFoodsList.getAllFoods()
        
        var matched: [String] = []
        
        for text in texts {
            let cleanText = text.lowercased()
                .replacingOccurrences(of: "[^a-z ]", with: "", options: .regularExpression)
            
            // Try exact match first
            if let exactMatch = usdaFoods.first(where: { cleanText.contains($0.lowercased()) }) {
                if !matched.contains(exactMatch) {
                    matched.append(exactMatch)
                    debugLog("  ✓ Exact: \(exactMatch)")
                    continue
                }
            }
            
            // Try fuzzy matching - look for any USDA food mentioned
            let words = cleanText.components(separatedBy: .whitespaces).filter { $0.count > 2 }
            for word in words {
                if let fuzzyMatch = usdaFoods.first(where: { 
                    let food = $0.lowercased()
                    return food.contains(word) || word.contains(food)
                }) {
                    if !matched.contains(fuzzyMatch) {
                        matched.append(fuzzyMatch)
                        debugLog("  ≈ Fuzzy: \(fuzzyMatch) (from '\(word)')")
                        break
                    }
                }
            }
        }
        
        return matched
    }
    
    /// Extract from HTML when no Schema.org data available
    private func extractFromHTML(_ html: String) -> (name: String, ingredients: [String], instructions: [String]) {
        // Strip HTML tags
        let text = html.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Try to find recipe name (look for common patterns)
        let namePatterns = ["Recipe:", "recipe:", "RECIPE:"]
        var name = "Imported Recipe"
        for pattern in namePatterns {
            if let range = text.range(of: pattern) {
                let start = text.index(range.upperBound, offsetBy: 1, limitedBy: text.endIndex) ?? range.upperBound
                let end = text.index(start, offsetBy: 100, limitedBy: text.endIndex) ?? text.endIndex
                let extracted = text[start..<end]
                if let lineEnd = extracted.firstIndex(of: "\n") {
                    name = String(extracted[..<lineEnd]).trimmingCharacters(in: .whitespaces)
                    break
                }
            }
        }
        
        // Extract ingredient-like lines (lines with numbers, units, food words)
        let lines = text.components(separatedBy: .newlines)
        let ingredientLines = lines.filter { line in
            let hasNumber = line.range(of: #"\d"#, options: .regularExpression) != nil
            let hasCommonUnits = ["cup", "tbsp", "tsp", "oz", "lb", "gram", "ml"].contains(where: { line.lowercased().contains($0) })
            return hasNumber || hasCommonUnits || line.count < 100 // Short lines likely ingredients
        }.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        // Extract instruction-like lines (longer sentences)
        let instructionLines = lines.filter { line in
            let words = line.components(separatedBy: .whitespaces)
            return words.count > 5 && words.count < 50 // Instructions are medium length
        }
        
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
