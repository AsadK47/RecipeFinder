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
        let imageURL: String?
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

            // Instructions are optional — many sites structure them in ways the parser misses
            let instructions = parsed.instructions.isEmpty ? ["See original recipe for instructions."] : parsed.instructions

            let matchedIngredients = matchIngredientsWithUSDA(parsed.ingredients)

            logger.debug("✅ Matched \(matchedIngredients.count)/\(parsed.ingredients.count) ingredients")

            let extractedData = ExtractedRecipeData(
                name: name,
                description: parsed.description,
                matchedIngredients: matchedIngredients,
                rawIngredients: parsed.ingredients,
                rawText: parsed.ingredients.joined(separator: "\n"),
                instructions: instructions,
                sourceURL: url,
                cookTimeMinutes: parsed.cookTime,
                prepTimeMinutes: parsed.prepTime,
                servings: parsed.servings,
                difficulty: parsed.difficulty,
                category: parsed.category,
                cuisine: parsed.cuisine,
                imageURL: parsed.imageURL
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
        case invalidResponse
        case invalidEncoding
        case missingRequiredData(String)

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Could not connect to the website. The site may be blocking automated requests or experiencing issues. Please try copying the recipe manually."
            case .invalidEncoding:
                return "Could not read the webpage content"
            case .missingRequiredData(let detail):
                return "Missing required data: \(detail)"
            }
        }
    }
}
