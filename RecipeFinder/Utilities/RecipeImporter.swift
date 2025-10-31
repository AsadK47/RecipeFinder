import Foundation
import SwiftUI

/// Smart Recipe Importer - Now powered by RecipeParser engine
class RecipeImporter: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var extractedData: ExtractedRecipeData?
    @Published var parseConfidence: Double = 0.0
    
    struct ExtractedRecipeData: Equatable {
        let name: String
        let description: String?
        let matchedIngredients: [String]  // USDA-matched ingredients
        let rawText: String  // For preview/editing
        let instructions: [String]
        let sourceURL: URL
        
        // Enhanced metadata
        let cookTimeMinutes: Int?
        let prepTimeMinutes: Int?
        let servings: Int?
        let difficulty: String?
        let category: String?
        let cuisine: String?
    }
    
    private func debugLog(_ message: String) {
        #if DEBUG
        print("[RecipeImporter] \(message)")
        #endif
    }
    
    // MARK: - Main Import Function with RecipeParser
    
    /// Import recipe from URL using intelligent RecipeParser
    func importRecipe(from url: URL) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            extractedData = nil
        }
        
        do {
            debugLog("🌐 Fetching recipe from: \(url.absoluteString)")
            
            // Fetch HTML
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw ImportError.invalidResponse
            }
            
            guard let html = String(data: data, encoding: .utf8) else {
                throw ImportError.invalidEncoding
            }
            
            debugLog("✅ HTML fetched (\(html.count) chars)")
            
            // Use RecipeParser to extract structured data
            let parsed = RecipeParser.parse(html: html)
            
            await MainActor.run {
                self.parseConfidence = parsed.confidence
                debugLog("🎯 Parse confidence: \(Int(parsed.confidence * 100))%")
            }
            
            // Validate minimum requirements
            guard let name = parsed.name, !name.isEmpty else {
                throw ImportError.missingRequiredData("Recipe name not found")
            }
            
            guard !parsed.ingredients.isEmpty else {
                throw ImportError.missingRequiredData("No ingredients found")
            }
            
            guard !parsed.instructions.isEmpty else {
                throw ImportError.missingRequiredData("No instructions found")
            }
            
            // Match ingredients against USDA database
            let matchedIngredients = matchIngredientsWithUSDA(parsed.ingredients)
            
            debugLog("✅ Matched \(matchedIngredients.count)/\(parsed.ingredients.count) ingredients with USDA")
            
            // Create extracted data
            let extractedData = ExtractedRecipeData(
                name: name,
                description: parsed.description,
                matchedIngredients: matchedIngredients,
                rawText: parsed.ingredients.joined(separator: "\n"),
                instructions: parsed.instructions,
                sourceURL: url,
                cookTimeMinutes: parsed.cookTime,
                prepTimeMinutes: parsed.prepTime,
                servings: parsed.servings,
                difficulty: parsed.difficulty,
                category: parsed.category,
                cuisine: parsed.cuisine
            )
            
            await MainActor.run {
                self.extractedData = extractedData
                self.isLoading = false
                debugLog("🎉 Import complete!")
            }
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                debugLog("❌ Import failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - USDA Ingredient Matching
    
    /// Match parsed ingredients against USDA food database
    private func matchIngredientsWithUSDA(_ ingredients: [String]) -> [String] {
        var matched: [String] = []
        
        for ingredient in ingredients {
            // Normalize the ingredient using IngredientNormalizer
            let normalized = IngredientNormalizer.normalize(ingredient)
            
            // Check if normalized ingredient exists in USDA database
            let usdaFoods = FoodsList.getAllFoods()
            if usdaFoods.contains(normalized) {
                matched.append(normalized)
            } else {
                // Try to extract just the food name (remove quantities/modifiers)
                let foodName = extractFoodName(from: ingredient)
                let normalizedFoodName = IngredientNormalizer.normalize(foodName)
                
                if usdaFoods.contains(normalizedFoodName) {
                    matched.append(normalizedFoodName)
                } else {
                    // Include the normalized version anyway for user review
                    matched.append(normalized)
                }
            }
        }
        
        return matched
    }
    
    /// Extract food name from ingredient line (remove quantities, units, modifiers)
    private func extractFoodName(from ingredient: String) -> String {
        var cleaned = ingredient.lowercased()
        
        // Remove quantities and units
        let quantityPattern = #"\b\d+[\d\/\.\s]*\s*(cup|tbsp|tsp|oz|lb|g|kg|ml|l)s?\b"#
        cleaned = cleaned.replacingOccurrences(of: quantityPattern, with: "", options: .regularExpression)
        
        // Remove modifiers
        let modifiers = ["diced", "chopped", "sliced", "minced", "crushed", "grated", "fresh", "dried", "frozen"]
        for modifier in modifiers {
            cleaned = cleaned.replacingOccurrences(of: "\\b\(modifier)\\b", with: "", options: .regularExpression)
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Error Types
    
    enum ImportError: LocalizedError {
        case invalidURL
        case invalidResponse
        case invalidEncoding
        case missingRequiredData(String)
        case parsingFailed(String)
        case invalidHTML
        case noData
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL provided"
            case .invalidResponse:
                return "Invalid response from server"
            case .invalidEncoding:
                return "Could not decode webpage content"
            case .missingRequiredData(let detail):
                return "Missing required data: \(detail)"
            case .parsingFailed(let detail):
                return "Failed to parse recipe: \(detail)"
            case .invalidHTML:
                return "Could not read webpage content"
            case .noData:
                return "No recipe data found on this page"
            }
        }
    }
    
    // MARK: - Legacy code below (kept for reference)
    
    /// Parse ISO 8601 duration format (e.g., "PT45M", "PT1H30M", "P1DT2H")
    /// Reference: https://en.wikipedia.org/wiki/ISO_8601#Durations
    private func parseISO8601Duration(_ duration: String?) -> Int? {
        guard let duration = duration?.uppercased() else { return nil }
        
        // ISO 8601 format: P[n]Y[n]M[n]DT[n]H[n]M[n]S
        // Examples: PT45M = 45 minutes, PT1H30M = 90 minutes, P1DT2H = 26 hours
        
        var totalMinutes = 0
        var currentNumber = ""
        var isTimePart = false
        
        for char in duration {
            if char == "P" {
                continue // Start marker
            } else if char == "T" {
                isTimePart = true
                continue
            } else if char.isNumber {
                currentNumber.append(char)
            } else if let value = Int(currentNumber) {
                switch char {
                case "D": // Days
                    totalMinutes += value * 24 * 60
                case "H": // Hours
                    totalMinutes += value * 60
                case "M": // Minutes (only if in time part)
                    if isTimePart {
                        totalMinutes += value
                    } else {
                        // Months - skip for recipe context
                    }
                case "W": // Weeks
                    totalMinutes += value * 7 * 24 * 60
                default:
                    break
                }
                currentNumber = ""
            }
        }
        
        return totalMinutes > 0 ? totalMinutes : nil
    }
    
    // MARK: - Natural Language Time Extraction
    
    /// Extract cooking time from natural language text
    /// Uses regex patterns and NLP heuristics
    /// Reference: Common recipe time formats from major recipe sites
    private func extractTimeFromText(_ text: String, keyword: String = "cook") -> Int? {
        let lowercased = text.lowercased()
        
        // Pattern 1: "Cook time: 45 minutes" or "Cooking time: 1 hour 30 minutes"
        let patterns = [
            #"\b\#(keyword)(?:ing)?\s*time[:\s]+(\d+)\s*(?:hour|hr|h)?\s*(\d+)?\s*(?:minute|min|m)\b"#,
            #"\b\#(keyword)[:\s]+(\d+)\s*(?:hour|hr|h)?\s*(\d+)?\s*(?:minute|min|m)\b"#,
            #"\b(\d+)\s*(?:hour|hr|h)?\s*(\d+)?\s*(?:minute|min|m)\s*\#(keyword)"#,
            #"\b\#(keyword)(?:ing)?\s*[:\-]\s*(\d+)\s*(?:min|minutes?|m)\b"#,
            #"\b\#(keyword)(?:ing)?\s*[:\-]\s*(\d+)\s*(?:hr|hours?|h)\b"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(lowercased.startIndex..., in: lowercased)
                if let match = regex.firstMatch(in: lowercased, range: range) {
                    var totalMinutes = 0
                    
                    // Extract hours if present
                    if match.numberOfRanges > 2, let hoursRange = Range(match.range(at: 2), in: lowercased) {
                        let hoursStr = String(lowercased[hoursRange])
                        if let hours = Int(hoursStr) {
                            totalMinutes += hours * 60
                        }
                    }
                    
                    // Extract minutes if present
                    if match.numberOfRanges > 3, let minutesRange = Range(match.range(at: 3), in: lowercased) {
                        let minutesStr = String(lowercased[minutesRange])
                        if let minutes = Int(minutesStr) {
                            totalMinutes += minutes
                        }
                    } else if match.numberOfRanges > 2 {
                        // Single number - determine if hours or minutes based on size
                        if let valueRange = Range(match.range(at: 2), in: lowercased) {
                            let valueStr = String(lowercased[valueRange])
                            if let value = Int(valueStr) {
                                // If pattern mentions "hour", it's hours; otherwise assume minutes
                                if pattern.contains("hour|hr|h") {
                                    totalMinutes += value * 60
                                } else {
                                    totalMinutes += value
                                }
                            }
                        }
                    }
                    
                    if totalMinutes > 0 {
                        return totalMinutes
                    }
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Intelligent Category Classification
    
    /// Multi-strategy category classification using:
    /// 1. Schema.org recipeCategory
    /// 2. Recipe name analysis (keyword matching)
    /// 3. Ingredient-based classification
    /// 4. Cuisine heuristics
    /// Reference: USDA Food Categories, culinary taxonomy
    private func classifyCategory(
        schemaCategory: String?,
        recipeName: String,
        ingredients: [String],
        cuisine: String?
    ) -> String {
        
        // Strategy 1: Use Schema.org category if available and valid
        if let schema = schemaCategory {
            let normalized = normalizeCategory(schema)
            if isValidCategory(normalized) {
                debugLog("📂 Category from Schema.org: \(normalized)")
                return normalized
            }
        }
        
        // Strategy 2: Name-based classification (keyword matching)
        if let nameCategory = classifyCategoryFromName(recipeName) {
            debugLog("📂 Category from name: \(nameCategory)")
            return nameCategory
        }
        
        // Strategy 3: Ingredient-based classification (machine learning approach)
        if let ingredientCategory = classifyCategoryFromIngredients(ingredients) {
            debugLog("📂 Category from ingredients: \(ingredientCategory)")
            return ingredientCategory
        }
        
        // Strategy 4: Cuisine-based default
        if let cuisine = cuisine?.lowercased() {
            if ["italian", "french", "american"].contains(cuisine) {
                return "Main"
            } else if ["mexican", "indian", "thai", "chinese"].contains(cuisine) {
                return "Main"
            }
        }
        
        // Default fallback
        debugLog("📂 Category: Using default (Main)")
        return "Main"
    }
    
    /// Normalize category strings from various sources to standard categories
    /// Maps common variations to canonical categories
    private func normalizeCategory(_ category: String) -> String {
        let lower = category.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Mapping of common variations to standard categories
        let categoryMap: [String: String] = [
            // Breakfast variations
            "breakfast": "Breakfast",
            "breakfast and brunch": "Breakfast",
            "brunch": "Breakfast",
            "morning": "Breakfast",
            
            // Appetizer/Starter variations
            "appetizer": "Starter",
            "appetizers": "Starter",
            "starter": "Starter",
            "starters": "Starter",
            "hors d'oeuvre": "Starter",
            "finger food": "Starter",
            "snack": "Starter",
            
            // Main course variations
            "main": "Main",
            "main course": "Main",
            "main dish": "Main",
            "entree": "Main",
            "entrée": "Main",
            "dinner": "Main",
            "lunch": "Main",
            
            // Side dish variations
            "side": "Side",
            "side dish": "Side",
            "sides": "Side",
            "accompaniment": "Side",
            
            // Soup variations
            "soup": "Soup",
            "soups": "Soup",
            "stew": "Soup",
            "chowder": "Soup",
            "bisque": "Soup",
            
            // Dessert variations
            "dessert": "Dessert",
            "desserts": "Dessert",
            "sweet": "Dessert",
            "sweets": "Dessert",
            "pastry": "Dessert",
            "cake": "Dessert",
            "cookie": "Dessert",
            "pie": "Dessert",
            
            // Drink variations
            "drink": "Drink",
            "drinks": "Drink",
            "beverage": "Drink",
            "beverages": "Drink",
            "cocktail": "Drink",
            "smoothie": "Drink"
        ]
        
        return categoryMap[lower] ?? "Main"
    }
    
    /// Check if category is valid (matches one of our 7 categories)
    private func isValidCategory(_ category: String) -> Bool {
        let validCategories = ["Breakfast", "Starter", "Main", "Side", "Soup", "Dessert", "Drink"]
        return validCategories.contains(category)
    }
    
    /// Classify category based on recipe name keywords
    /// Uses extensive keyword dictionary from major recipe sites
    private func classifyCategoryFromName(_ name: String) -> String? {
        let lower = name.lowercased()
        
        // Breakfast keywords (high confidence)
        let breakfastKeywords = [
            "pancake", "waffle", "french toast", "omelette", "omelet", "scrambled egg",
            "fried egg", "poached egg", "breakfast", "brunch", "cereal", "oatmeal",
            "porridge", "granola", "muesli", "bagel", "croissant", "muffin", "scone"
        ]
        if breakfastKeywords.contains(where: { lower.contains($0) }) {
            return "Breakfast"
        }
        
        // Dessert keywords (high confidence)
        let dessertKeywords = [
            "cake", "cookie", "brownie", "cupcake", "pie", "tart", "cheesecake",
            "pudding", "mousse", "ice cream", "sorbet", "gelato", "macaron",
            "tiramisu", "pavlova", "eclair", "profiterole", "dessert", "sweet",
            "chocolate chip", "sugar cookie", "shortbread", "biscotti", "fudge",
            "truffle", "bonbon", "candy", "caramel", "praline"
        ]
        if dessertKeywords.contains(where: { lower.contains($0) }) {
            return "Dessert"
        }
        
        // Soup keywords
        let soupKeywords = [
            "soup", "stew", "chowder", "bisque", "broth", "consomme", "gazpacho",
            "minestrone", "ramen", "pho", "chili", "gumbo"
        ]
        if soupKeywords.contains(where: { lower.contains($0) }) {
            return "Soup"
        }
        
        // Drink keywords
        let drinkKeywords = [
            "smoothie", "juice", "cocktail", "mocktail", "latte", "cappuccino",
            "espresso", "tea", "lemonade", "shake", "milkshake", "drink", "beverage"
        ]
        if drinkKeywords.contains(where: { lower.contains($0) }) {
            return "Drink"
        }
        
        // Starter/Appetizer keywords
        let starterKeywords = [
            "dip", "salsa", "guacamole", "hummus", "bruschetta", "crostini",
            "appetizer", "starter", "canapé", "tapas", "mezze", "antipasto",
            "spring roll", "dumpling", "wonton", "samosa", "pakora"
        ]
        if starterKeywords.contains(where: { lower.contains($0) }) {
            return "Starter"
        }
        
        // Side dish keywords
        let sideKeywords = [
            "side", "fries", "coleslaw", "potato salad", "mac and cheese",
            "roasted vegetables", "sautéed", "steamed vegetables"
        ]
        if sideKeywords.contains(where: { lower.contains($0) }) {
            return "Side"
        }
        
        return nil
    }
    
    /// Classify category based on ingredient composition
    /// Uses weighted scoring algorithm for classification confidence
    private func classifyCategoryFromIngredients(_ ingredients: [String]) -> String? {
        let ingredientText = ingredients.joined(separator: " ").lowercased()
        
        var scores: [String: Int] = [
            "Breakfast": 0,
            "Dessert": 0,
            "Soup": 0,
            "Drink": 0,
            "Main": 0
        ]
        
        // Breakfast indicators (eggs, bacon, etc.)
        if ingredientText.contains("egg") { scores["Breakfast"]! += 3 }
        if ingredientText.contains("bacon") { scores["Breakfast"]! += 3 }
        if ingredientText.contains("sausage") && !ingredientText.contains("italian") { scores["Breakfast"]! += 2 }
        if ingredientText.contains("maple syrup") { scores["Breakfast"]! += 4 }
        if ingredientText.contains("oat") { scores["Breakfast"]! += 2 }
        
        // Dessert indicators (flour + sugar + butter = baking)
        let hasFlour = ingredientText.contains("flour")
        let hasSugar = ingredientText.contains("sugar")
        let hasButter = ingredientText.contains("butter")
        let hasChocolate = ingredientText.contains("chocolate")
        let hasVanilla = ingredientText.contains("vanilla")
        
        if hasFlour && hasSugar && hasButter { scores["Dessert"]! += 5 }
        if hasChocolate { scores["Dessert"]! += 3 }
        if hasVanilla { scores["Dessert"]! += 2 }
        if ingredientText.contains("cream") && hasSugar { scores["Dessert"]! += 3 }
        
        // Soup indicators (broth/stock + vegetables)
        if ingredientText.contains("broth") || ingredientText.contains("stock") {
            scores["Soup"]! += 4
        }
        if ingredientText.contains("carrot") && ingredientText.contains("celery") {
            scores["Soup"]! += 3
        }
        
        // Drink indicators
        if ingredientText.contains("milk") && !hasFlour && ingredients.count <= 5 {
            scores["Drink"]! += 3
        }
        if ingredientText.contains("ice") && ingredients.count <= 6 {
            scores["Drink"]! += 4
        }
        
        // Main course indicators (protein-heavy)
        let proteins = ["chicken", "beef", "pork", "fish", "salmon", "shrimp", "lamb", "turkey"]
        if proteins.contains(where: { ingredientText.contains($0) }) {
            scores["Main"]! += 4
        }
        
        // Return highest scoring category if confidence is high enough
        if let maxScore = scores.values.max(), maxScore >= 4 {
            if let category = scores.first(where: { $0.value == maxScore })?.key {
                return category
            }
        }
        
        return nil
    }
    
    // MARK: - Difficulty Estimation
    
    /// Estimate recipe difficulty using complexity heuristics
    /// Factors: ingredient count, instruction complexity, technique keywords
    /// Reference: Culinary Institute of America skill classifications
    private func estimateDifficulty(
        ingredientCount: Int,
        instructionCount: Int,
        instructions: [String]
    ) -> String {
        
        var complexityScore = 0
        
        // Factor 1: Ingredient count (more ingredients = more complex)
        if ingredientCount > 15 {
            complexityScore += 2
        } else if ingredientCount > 10 {
            complexityScore += 1
        }
        
        // Factor 2: Number of steps
        if instructionCount > 10 {
            complexityScore += 2
        } else if instructionCount > 6 {
            complexityScore += 1
        }
        
        // Factor 3: Advanced technique keywords
        let advancedTechniques = [
            "sous vide", "flambé", "emulsify", "temper", "confit", "braise",
            "deglaze", "fold", "proof", "knead", "reduce", "clarify",
            "blanch", "julienne", "brunoise", "chiffonade", "supreme"
        ]
        
        let instructionText = instructions.joined(separator: " ").lowercased()
        let techniqueCount = advancedTechniques.filter { instructionText.contains($0) }.count
        
        if techniqueCount >= 3 {
            complexityScore += 3
        } else if techniqueCount >= 1 {
            complexityScore += 1
        }
        
        // Factor 4: Time-intensive processes
        if instructionText.contains("overnight") || instructionText.contains("24 hour") {
            complexityScore += 2
        } else if instructionText.contains("rest") || instructionText.contains("chill") {
            complexityScore += 1
        }
        
        // Classification based on score
        if complexityScore >= 5 {
            return "Expert"
        } else if complexityScore >= 2 {
            return "Intermediate"
        } else {
            return "Basic"
        }
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
                description: nil,
                matchedIngredients: matchedIngredients,
                rawText: ingredientTexts.joined(separator: "\n"),
                instructions: instructions,
                sourceURL: url,
                cookTimeMinutes: nil,
                prepTimeMinutes: nil,
                servings: nil,
                difficulty: nil,
                category: nil,
                cuisine: nil
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
        let usdaFoods = FoodsList.getAllFoods()
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
        
        for line in lines {
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

// Enhanced Schema.org Recipe Structure with full metadata extraction
struct SchemaRecipe: Codable {
    let name: String?
    let recipeIngredient: [String]?
    let recipeInstructions: InstructionType?
    let totalTime: String?           // ISO 8601 duration (e.g., "PT45M")
    let cookTime: String?             // ISO 8601 duration
    let prepTime: String?             // ISO 8601 duration
    let recipeCategory: CategoryType? // Can be string or array
    let recipeCuisine: String?        // "Italian", "Mexican", etc.
    let recipeYield: YieldType?       // Can be string or number
    let difficulty: String?           // Some sites include this
    
    // Support both string and array for category
    enum CategoryType: Codable {
        case string(String)
        case array([String])
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let string = try? container.decode(String.self) {
                self = .string(string)
            } else if let array = try? container.decode([String].self) {
                self = .array(array)
            } else {
                self = .string("")
            }
        }
        
        var firstValue: String? {
            switch self {
            case .string(let s): return s
            case .array(let arr): return arr.first
            }
        }
    }
    
    // Support both string and number for yield
    enum YieldType: Codable {
        case string(String)
        case number(Int)
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let number = try? container.decode(Int.self) {
                self = .number(number)
            } else if let string = try? container.decode(String.self) {
                self = .string(string)
            } else {
                self = .number(4)
            }
        }
        
        var servings: Int {
            switch self {
            case .number(let n): return n
            case .string(let s):
                // Extract number from string like "4 servings" or "Serves 6"
                let digits = s.filter { $0.isNumber }
                return Int(digits) ?? 4
            }
        }
    }
    
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
