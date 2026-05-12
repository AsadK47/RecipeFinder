import Foundation
import SwiftUI

private let logger = AppLogger.logger(category: "RecipeImporter")

final class RecipeImporter: ObservableObject, @unchecked Sendable {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var extractedData: ExtractedRecipeData?
    @Published var parseConfidence: Double = 0.0

    var isNetworkAvailable: () async -> Bool = { await NetworkMonitor.shared.isConnected }
    
    struct ExtractedRecipeData: Equatable {
        let name: String
        let description: String?
        let matchedIngredients: [String]
        let rawIngredients: [String]
        let rawText: String
        let instructions: [String]
        let sourceURL: URL
        
        let cookTimeMinutes: Int?
        let prepTimeMinutes: Int?
        let servings: Int?
        let difficulty: String?
        let category: String?
        let cuisine: String?
    }
    
    func importRecipe(from url: URL, redirectCount: Int = 0) async {
        guard redirectCount < 5 else {
            await MainActor.run {
                isLoading = false
                errorMessage = "Too many redirects. Please try a different URL."
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            extractedData = nil
        }
        
        let isConnected = await isNetworkAvailable()
        guard isConnected else {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = AppError.networkUnavailable.localizedDescription
            }
            return
        }
        
        do {
            logger.debug("🌐 Fetching recipe from: \(url.absoluteString)")
            
            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
            request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
            request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
            request.timeoutInterval = 30
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ImportError.invalidResponse
            }
            
            logger.debug("📊 HTTP Status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 301 || httpResponse.statusCode == 302 {
                if let location = httpResponse.value(forHTTPHeaderField: "Location"),
                   let redirectURL = URL(string: location, relativeTo: url) {
                    logger.debug("↪️ Following redirect \(redirectCount + 1)/5 to: \(redirectURL.absoluteString)")
                    await importRecipe(from: redirectURL, redirectCount: redirectCount + 1)
                    return
                }
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw ImportError.invalidResponse
            }
            
            guard let html = String(data: data, encoding: .utf8) else {
                throw ImportError.invalidEncoding
            }
            
            logger.debug("✅ HTML fetched (\(html.count) chars)")
            
            let parsed = RecipeParser.parse(html: html)
            
            await MainActor.run {
                self.parseConfidence = parsed.confidence
            }
            logger.debug("🎯 Parse confidence: \(Int(parsed.confidence * 100))%")
            
            guard let name = parsed.name, !name.isEmpty else {
                throw ImportError.missingRequiredData("Recipe name not found")
            }
            
            guard !parsed.ingredients.isEmpty else {
                throw ImportError.missingRequiredData("No ingredients found")
            }
            
            guard !parsed.instructions.isEmpty else {
                throw ImportError.missingRequiredData("No instructions found")
            }
            
            let matchedIngredients = matchIngredientsWithUSDA(parsed.ingredients)
            
            logger.debug("✅ Matched \(matchedIngredients.count)/\(parsed.ingredients.count) ingredients")
            
            let extractedData = ExtractedRecipeData(
                name: name,
                description: parsed.description,
                matchedIngredients: matchedIngredients,
                rawIngredients: parsed.ingredients,
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
            }
            logger.debug("🎉 Import complete!")
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
            logger.error("❌ Import failed: \(error.localizedDescription)")
        }
    }
    
    private func matchIngredientsWithUSDA(_ ingredients: [String]) -> [String] {
        var matched: [String] = []
        
        for ingredient in ingredients {
            let normalized = IngredientNormalizer.normalize(ingredient)
            
            let usdaFoods = FoodsList.getAllFoods()
            if usdaFoods.contains(normalized) {
                matched.append(normalized)
            } else {
                let foodName = extractFoodName(from: ingredient)
                let normalizedFoodName = IngredientNormalizer.normalize(foodName)
                
                if usdaFoods.contains(normalizedFoodName) {
                    matched.append(normalizedFoodName)
                } else {
                    matched.append(normalized)
                }
            }
        }
        
        return matched
    }
    
    private func extractFoodName(from ingredient: String) -> String {
        var cleaned = ingredient.lowercased()
        
        let quantityPattern = #"\b\d+[\d\/\.\s]*\s*(cup|tbsp|tsp|oz|lb|g|kg|ml|l)s?\b"#
        cleaned = cleaned.replacingOccurrences(of: quantityPattern, with: "", options: .regularExpression)
        
        let modifiers = ["diced", "chopped", "sliced", "minced", "crushed", "grated", "fresh", "dried", "frozen"]
        for modifier in modifiers {
            cleaned = cleaned.replacingOccurrences(of: "\\b\(modifier)\\b", with: "", options: .regularExpression)
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
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
                return "Could not connect to the website. The site may be blocking automated requests or experiencing issues. Please try copying the recipe manually."
            case .invalidEncoding:
                return "Could not read the webpage content"
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
    
    private func classifyCategory(
        schemaCategory: String?,
        recipeName: String,
        ingredients: [String],
        cuisine: String?
    ) -> String {
        
        if let schema = schemaCategory {
            let normalized = normalizeCategory(schema)
            if isValidCategory(normalized) {
                logger.debug("📂 Category from Schema.org: \(normalized)")
                return normalized
            }
        }
        
        if let nameCategory = classifyCategoryFromName(recipeName) {
            logger.debug("📂 Category from name: \(nameCategory)")
            return nameCategory
        }
        
        if let ingredientCategory = classifyCategoryFromIngredients(ingredients) {
            logger.debug("📂 Category from ingredients: \(ingredientCategory)")
            return ingredientCategory
        }
        
        if let cuisine = cuisine?.lowercased() {
            if ["italian", "french", "american"].contains(cuisine) {
                return "Main"
            } else if ["mexican", "indian", "thai", "chinese"].contains(cuisine) {
                return "Main"
            }
        }
        
        logger.debug("📂 Category: Using default (Main)")
        return "Main"
    }
    
    private func normalizeCategory(_ category: String) -> String {
        let lower = category.lowercased().trimmingCharacters(in: .whitespaces)
        
        let categoryMap: [String: String] = [
            "breakfast": "Breakfast",
            "breakfast and brunch": "Breakfast",
            "brunch": "Breakfast",
            "morning": "Breakfast",
            
            "appetizer": "Starter",
            "appetizers": "Starter",
            "starter": "Starter",
            "starters": "Starter",
            "hors d'oeuvre": "Starter",
            "finger food": "Starter",
            "snack": "Starter",
            
            "main": "Main",
            "main course": "Main",
            "main dish": "Main",
            "entree": "Main",
            "entrée": "Main",
            "dinner": "Main",
            "lunch": "Main",
            
            "side": "Side",
            "side dish": "Side",
            "sides": "Side",
            "accompaniment": "Side",
            
            "soup": "Soup",
            "soups": "Soup",
            "stew": "Soup",
            "chowder": "Soup",
            "bisque": "Soup",
            
            "dessert": "Dessert",
            "desserts": "Dessert",
            "sweet": "Dessert",
            "sweets": "Dessert",
            "pastry": "Dessert",
            "cake": "Dessert",
            "cookie": "Dessert",
            "pie": "Dessert",
            
            "drink": "Drink",
            "drinks": "Drink",
            "beverage": "Drink",
            "beverages": "Drink",
            "cocktail": "Drink",
            "smoothie": "Drink"
        ]
        
        return categoryMap[lower] ?? "Main"
    }
    
    private func isValidCategory(_ category: String) -> Bool {
        let validCategories = ["Breakfast", "Starter", "Main", "Side", "Soup", "Dessert", "Drink"]
        return validCategories.contains(category)
    }
    
    private func classifyCategoryFromName(_ name: String) -> String? {
        let lower = name.lowercased()
        
        let breakfastKeywords = [
            "pancake", "waffle", "french toast", "omelette", "omelet", "scrambled egg",
            "fried egg", "poached egg", "breakfast", "brunch", "cereal", "oatmeal",
            "porridge", "granola", "muesli", "bagel", "croissant", "muffin", "scone"
        ]
        if breakfastKeywords.contains(where: { lower.contains($0) }) {
            return "Breakfast"
        }
        
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
        
        let soupKeywords = [
            "soup", "stew", "chowder", "bisque", "broth", "consomme", "gazpacho",
            "minestrone", "ramen", "pho", "chili", "gumbo"
        ]
        if soupKeywords.contains(where: { lower.contains($0) }) {
            return "Soup"
        }
        
        let drinkKeywords = [
            "smoothie", "juice", "cocktail", "mocktail", "latte", "cappuccino",
            "espresso", "tea", "lemonade", "shake", "milkshake", "drink", "beverage"
        ]
        if drinkKeywords.contains(where: { lower.contains($0) }) {
            return "Drink"
        }
        
        let starterKeywords = [
            "dip", "salsa", "guacamole", "hummus", "bruschetta", "crostini",
            "appetizer", "starter", "canapé", "tapas", "mezze", "antipasto",
            "spring roll", "dumpling", "wonton", "samosa", "pakora"
        ]
        if starterKeywords.contains(where: { lower.contains($0) }) {
            return "Starter"
        }
        
        let sideKeywords = [
            "side", "fries", "coleslaw", "potato salad", "mac and cheese",
            "roasted vegetables", "sautéed", "steamed vegetables"
        ]
        if sideKeywords.contains(where: { lower.contains($0) }) {
            return "Side"
        }
        
        return nil
    }
    
    private func classifyCategoryFromIngredients(_ ingredients: [String]) -> String? {
        let ingredientText = ingredients.joined(separator: " ").lowercased()
        
        var scores: [String: Int] = [
            "Breakfast": 0,
            "Dessert": 0,
            "Soup": 0,
            "Drink": 0,
            "Main": 0
        ]
        
        if ingredientText.contains("egg") { scores["Breakfast"]! += 3 }
        if ingredientText.contains("bacon") { scores["Breakfast"]! += 3 }
        if ingredientText.contains("sausage") && !ingredientText.contains("italian") { scores["Breakfast"]! += 2 }
        if ingredientText.contains("maple syrup") { scores["Breakfast"]! += 4 }
        if ingredientText.contains("oat") { scores["Breakfast"]! += 2 }
        
        let hasFlour = ingredientText.contains("flour")
        let hasSugar = ingredientText.contains("sugar")
        let hasButter = ingredientText.contains("butter")
        let hasChocolate = ingredientText.contains("chocolate")
        let hasVanilla = ingredientText.contains("vanilla")
        
        if hasFlour && hasSugar && hasButter { scores["Dessert"]! += 5 }
        if hasChocolate { scores["Dessert"]! += 3 }
        if hasVanilla { scores["Dessert"]! += 2 }
        if ingredientText.contains("cream") && hasSugar { scores["Dessert"]! += 3 }
        
        if ingredientText.contains("broth") || ingredientText.contains("stock") {
            scores["Soup"]! += 4
        }
        if ingredientText.contains("carrot") && ingredientText.contains("celery") {
            scores["Soup"]! += 3
        }
        
        if ingredientText.contains("milk") && !hasFlour && ingredients.count <= 5 {
            scores["Drink"]! += 3
        }
        if ingredientText.contains("ice") && ingredients.count <= 6 {
            scores["Drink"]! += 4
        }
        
        let proteins = ["chicken", "beef", "pork", "fish", "salmon", "shrimp", "lamb", "turkey"]
        if proteins.contains(where: { ingredientText.contains($0) }) {
            scores["Main"]! += 4
        }
        
        if let maxScore = scores.values.max(), maxScore >= 4 {
            if let category = scores.first(where: { $0.value == maxScore })?.key {
                return category
            }
        }
        
        return nil
    }
    
    private func estimateDifficulty(
        ingredientCount: Int,
        instructionCount: Int,
        instructions: [String]
    ) -> String {
        
        var complexityScore = 0
        
        if ingredientCount > 15 {
            complexityScore += 2
        } else if ingredientCount > 10 {
            complexityScore += 1
        }
        
        if instructionCount > 10 {
            complexityScore += 2
        } else if instructionCount > 6 {
            complexityScore += 1
        }
        
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
        
        if instructionText.contains("overnight") || instructionText.contains("24 hour") {
            complexityScore += 2
        } else if instructionText.contains("rest") || instructionText.contains("chill") {
            complexityScore += 1
        }
        
        if complexityScore >= 5 {
            return "Expert"
        } else if complexityScore >= 2 {
            return "Intermediate"
        } else {
            return "Basic"
        }
    }
    
    func importRecipe(from urlString: String) async {
        isLoading = true
        errorMessage = nil
        extractedData = nil
        
        logger.debug("🌐 Starting smart import from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        do {
            logger.debug("📥 Fetching HTML...")
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else {
                throw ImportError.invalidHTML
            }
            logger.debug("✅ HTML fetched: \(html.count) chars")
            
            logger.debug("🔍 Extracting recipe data...")
            let schemaRecipe = extractSchemaRecipe(from: html)
            
            let recipeName: String
            let ingredientTexts: [String]
            let instructions: [String]
            
            if let schema = schemaRecipe {
                recipeName = schema.name ?? "Imported Recipe"
                ingredientTexts = schema.recipeIngredient ?? []
                instructions = schema.recipeInstructions?.steps ?? []
                logger.debug("✅ Extracted via Schema.org: \(ingredientTexts.count) ingredients")
            } else {
                logger.debug("⚠️ No Schema.org data, extracting from HTML text...")
                let extracted = extractFromHTML(html)
                recipeName = extracted.name
                ingredientTexts = extracted.ingredients
                instructions = extracted.instructions
                logger.debug("✅ Extracted from HTML: \(ingredientTexts.count) ingredient lines")
            }
            
            logger.debug("🎯 Matching ingredients against foods...")
            let matchedIngredients = matchUSDAIngredients(from: ingredientTexts)
            logger.debug("✅ Matched \(matchedIngredients.count) ingredients")
            
            let extracted = ExtractedRecipeData(
                name: recipeName,
                description: nil,
                matchedIngredients: matchedIngredients,
                rawIngredients: ingredientTexts,
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
            
            extractedData = extracted
            isLoading = false
            
        } catch {
            logger.error("❌ Import failed: \(error)")
            errorMessage = "Failed to import: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    private func matchUSDAIngredients(from texts: [String]) -> [String] {
        let usdaFoods = FoodsList.getAllFoods()
        let usdaLowercased = usdaFoods.map { $0.lowercased() }
        
        var matched: [String] = []
        var matchedLower: Set<String> = []
        
        let skipWords = Set(["and", "the", "with", "for", "into", "from", "about", "approximately", "roughly", "optional", "fresh", "dried", "chopped", "diced", "sliced", "minced", "grated", "shredded", "melted", "softened", "room", "temperature", "large", "small", "medium", "to", "taste", "as", "needed", "cup", "cups", "tbsp", "tsp", "tablespoon", "tablespoons", "teaspoon", "teaspoons", "ounce", "ounces", "oz", "pound", "pounds", "lb", "lbs", "gram", "grams", "g", "kg", "kilogram", "ml", "milliliter", "liter", "l", "pinch", "dash", "clove", "cloves"])
        
        for text in texts {
            let cleanText = text.lowercased()
                .replacingOccurrences(of: #"[^\w\s]"#, with: " ", options: .regularExpression)
                .replacingOccurrences(of: #"\d+\.?\d*"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)
            
            let words = cleanText.components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty && $0.count > 2 && !skipWords.contains($0) }
            
            if words.count >= 2 {
                for i in 0..<words.count-1 {
                    let twoWords = "\(words[i]) \(words[i+1])"
                    if let matchIndex = usdaLowercased.firstIndex(where: { $0 == twoWords || $0.contains(twoWords) }) {
                        let match = usdaFoods[matchIndex]
                        if !matchedLower.contains(match.lowercased()) {
                            matched.append(match)
                            matchedLower.insert(match.lowercased())
                            logger.debug("  ✓ Multi-word: \(match) from '\(twoWords)'")
                            break
                        }
                    }
                }
            }
            
            for food in usdaFoods {
                let foodLower = food.lowercased()
                if cleanText == foodLower || cleanText.contains(" \(foodLower) ") || cleanText.starts(with: "\(foodLower) ") || cleanText.hasSuffix(" \(foodLower)") {
                    if !matchedLower.contains(foodLower) {
                        matched.append(food)
                        matchedLower.insert(foodLower)
                        logger.debug("  ✓ Exact: \(food)")
                        break
                    }
                }
            }
            
            for word in words {
                if matched.count > matchedLower.count { break }
                
                if let matchIndex = usdaLowercased.firstIndex(where: { foodLower in
                    let foodWords = foodLower.components(separatedBy: .whitespaces)
                    return foodWords.contains(word) || word.contains(foodLower) || foodLower.contains(word)
                }) {
                    let match = usdaFoods[matchIndex]
                    if !matchedLower.contains(match.lowercased()) {
                        matched.append(match)
                        matchedLower.insert(match.lowercased())
                        logger.debug("  ≈ Fuzzy: \(match) from word '\(word)'")
                        break
                    }
                }
            }
            
            if matched.count == matchedLower.count {
                for (index, foodLower) in usdaLowercased.enumerated() {
                    if cleanText.contains(foodLower) && foodLower.count > 3 {
                        let match = usdaFoods[index]
                        if !matchedLower.contains(foodLower) {
                            matched.append(match)
                            matchedLower.insert(foodLower)
                            logger.debug("  ~ Partial: \(match)")
                            break
                        }
                    }
                }
            }
        }
        
        logger.debug("✅ Total matched: \(matched.count) unique ingredients")
        return matched
    }
    
    private func extractFromHTML(_ html: String) -> (name: String, ingredients: [String], instructions: [String]) {
        var text = html.replacingOccurrences(of: "<br[^>]*>", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "</p>", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "</li>", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "</div>", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        text = text.decodeHTMLEntities()
        text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && $0.count > 3 }
        
        var name = "Imported Recipe"
        
        if let titleRange = html.range(of: "<title[^>]*>([^<]+)</title>", options: .regularExpression) {
            let titleText = String(html[titleRange])
            if let extracted = titleText.range(of: ">([^<]+)<", options: .regularExpression) {
                let rawTitle = String(titleText[extracted])
                    .replacingOccurrences(of: ">", with: "")
                    .replacingOccurrences(of: "<", with: "")
                    .trimmingCharacters(in: .whitespaces)
                    .decodeHTMLEntities()
                
                let cleaned = rawTitle
                    .components(separatedBy: ["|", "-", "–", "—"])
                    .first?
                    .trimmingCharacters(in: .whitespaces) ?? rawTitle
                
                if cleaned.count > 3 && cleaned.count < 100 {
                    name = cleaned
                }
            }
        }
        
        if name == "Imported Recipe" {
            if let h1Range = html.range(of: "<h1[^>]*>([^<]+)</h1>", options: .regularExpression) {
                let h1Text = String(html[h1Range])
                if let extracted = h1Text.range(of: ">([^<]+)<", options: .regularExpression) {
                    let rawH1 = String(h1Text[extracted])
                        .replacingOccurrences(of: ">", with: "")
                        .replacingOccurrences(of: "<", with: "")
                        .trimmingCharacters(in: .whitespaces)
                        .decodeHTMLEntities()
                    if rawH1.count > 3 && rawH1.count < 100 {
                        name = rawH1
                    }
                }
            }
        }
        
        var ingredientLines: [String] = []
        
        var inIngredientSection = false
        var foundIngredientHeader = false
        
        for line in lines {
            let lowercased = line.lowercased()
            
            if lowercased.contains("ingredient") && line.count < 50 {
                inIngredientSection = true
                foundIngredientHeader = true
                continue
            }
            
            if inIngredientSection && 
               (lowercased.contains("instruction") || 
                lowercased.contains("direction") || 
                lowercased.contains("preparation") ||
                lowercased.contains("method")) {
                inIngredientSection = false
            }
            
            if inIngredientSection || !foundIngredientHeader {
                let hasNumber = line.range(of: #"[\d/]"#, options: .regularExpression) != nil
                let hasUnit = ["cup", "cups", "tbsp", "tsp", "teaspoon", "tablespoon", "oz", "ounce", "lb", "pound", "gram", "g", "kg", "ml", "liter", "clove", "pinch", "dash", "slice"].contains(where: { lowercased.contains($0) })
                let hasFoodWord = ["chicken", "beef", "pork", "fish", "egg", "flour", "sugar", "salt", "pepper", "oil", "butter", "cheese", "milk", "cream", "tomato", "onion", "garlic", "rice", "pasta", "bread"].contains(where: { lowercased.contains($0) })
                let isShort = line.count < 150
                
                if (hasNumber && hasUnit) || (hasNumber && hasFoodWord) || (hasFoodWord && isShort) {
                    if !lowercased.contains("step") && !lowercased.contains("preheat") {
                        ingredientLines.append(line)
                    }
                }
            }
            
            if ingredientLines.count >= 30 { break }
        }
        
        var instructionLines: [String] = []
        var inInstructionSection = false
        var currentInstruction = ""
        
        for line in lines {
            let lowercased = line.lowercased()
            
            if (lowercased.contains("instruction") || 
                lowercased.contains("direction") || 
                lowercased.contains("preparation") ||
                lowercased.contains("method") ||
                lowercased.contains("step")) && line.count < 50 {
                inInstructionSection = true
                continue
            }
            
            if inInstructionSection {
                let hasVerb = ["add", "mix", "stir", "cook", "heat", "bake", "boil", "fry", "season", "place", "pour", "combine", "whisk", "blend", "chop", "cut", "slice", "dice", "preheat", "serve"].contains(where: { lowercased.contains($0) })
                let isReasonableLength = line.count > 20 && line.count < 500
                let startsWithNumber = line.first?.isNumber == true
                
                if (hasVerb && isReasonableLength) || startsWithNumber {
                    if !currentInstruction.isEmpty {
                        instructionLines.append(currentInstruction)
                        currentInstruction = ""
                    }
                    
                    currentInstruction = line
                    
                    if line.hasSuffix(".") || line.hasSuffix("!") || startsWithNumber {
                        instructionLines.append(currentInstruction)
                        currentInstruction = ""
                    }
                } else if !currentInstruction.isEmpty && isReasonableLength {
                    currentInstruction += " " + line
                    if line.hasSuffix(".") || line.hasSuffix("!") {
                        instructionLines.append(currentInstruction)
                        currentInstruction = ""
                    }
                }
            }
            
            if instructionLines.count >= 25 { break }
        }
        
        if !currentInstruction.isEmpty {
            instructionLines.append(currentInstruction)
        }
        
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
        
        logger.debug("📝 Extracted: name='\(name)', \(ingredientLines.count) ingredients, \(instructionLines.count) instructions")
        
        return (name, Array(ingredientLines.prefix(30)), Array(instructionLines.prefix(20)))
    }
    
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
            
            if let recipe = try? JSONDecoder().decode(SchemaRecipe.self, from: jsonData), recipe.name != nil {
                return recipe
            }
            
            if let array = try? JSONDecoder().decode([SchemaRecipe].self, from: jsonData),
               let recipe = array.first(where: { $0.name != nil }) {
                return recipe
            }
            
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

struct SchemaRecipe: Codable {
    let name: String?
    let recipeIngredient: [String]?
    let recipeInstructions: InstructionType?
    let totalTime: String?
    let cookTime: String?
    let prepTime: String?
    let recipeCategory: CategoryType?
    let recipeCuisine: String?
    let recipeYield: YieldType?
    let difficulty: String?
    
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

extension String {
    func decodeHTMLEntities() -> String {
        var result = self
        
        let entities: [String: String] = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&apos;": "'",
            "&nbsp;": " ",
            "&#39;": "'",
            "&#34;": "\"",
            "&mdash;": "—",
            "&ndash;": "–",
            "&hellip;": "...",
            "&ldquo;": "\u{201C}",
            "&rdquo;": "\u{201D}",
            "&lsquo;": "\u{2018}",
            "&rsquo;": "\u{2019}",
            "&deg;": "°",
            "&frac12;": "½",
            "&frac14;": "¼",
            "&frac34;": "¾"
        ]
        
        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        
        let decimalPattern = "&#(\\d+);"
        if let regex = try? NSRegularExpression(pattern: decimalPattern, options: []) {
            let nsString = result as NSString
            let matches = regex.matches(in: result, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for match in matches.reversed() {
                if match.numberOfRanges >= 2 {
                    let numberRange = match.range(at: 1)
                    let numberString = nsString.substring(with: numberRange)
                    if let number = Int(numberString),
                       let scalar = UnicodeScalar(number) {
                        let replacement = String(Character(scalar))
                        result = (result as NSString).replacingCharacters(in: match.range, with: replacement)
                    }
                }
            }
        }
        
        let hexPattern = "&#x([0-9A-Fa-f]+);"
        if let regex = try? NSRegularExpression(pattern: hexPattern, options: []) {
            let nsString = result as NSString
            let matches = regex.matches(in: result, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for match in matches.reversed() {
                if match.numberOfRanges >= 2 {
                    let hexRange = match.range(at: 1)
                    let hexString = nsString.substring(with: hexRange)
                    if let number = Int(hexString, radix: 16),
                       let scalar = UnicodeScalar(number) {
                        let replacement = String(Character(scalar))
                        result = (result as NSString).replacingCharacters(in: match.range, with: replacement)
                    }
                }
            }
        }
        
        result = result.replacingOccurrences(of: #"\{([^}]+)\}"#, with: "$1", options: .regularExpression)
        
        return result
    }
}
