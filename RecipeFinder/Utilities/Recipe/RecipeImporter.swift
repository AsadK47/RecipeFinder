import Foundation
import SwiftUI

private let logger = AppLogger.logger(category: "RecipeImporter")

@MainActor
final class RecipeImporter: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var extractedData: ExtractedRecipeData?
    @Published var parseConfidence: Double = 0.0

    private let fetcher: HTMLFetching
    private let isNetworkAvailable: () async -> Bool

    init(
        fetcher: HTMLFetching = URLSessionHTMLFetcher(),
        isNetworkAvailable: @escaping () async -> Bool = { await NetworkMonitor.shared.isConnected }
    ) {
        self.fetcher = fetcher
        self.isNetworkAvailable = isNetworkAvailable
    }

    struct ExtractedRecipeData: Equatable, Sendable {
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

    struct ImportOutcome: Equatable, Sendable {
        let data: ExtractedRecipeData
        let confidence: Double
    }

    /// Drives the observable UI state around a single import: fetches + parses
    /// off the main actor, then publishes the result (or an error message).
    func importRecipe(from url: URL) async {
        isLoading = true
        errorMessage = nil
        extractedData = nil

        guard await isNetworkAvailable() else {
            isLoading = false
            errorMessage = AppError.networkUnavailable.localizedDescription
            return
        }

        do {
            let outcome = try await fetchAndParse(from: url)
            parseConfidence = outcome.confidence
            extractedData = outcome.data
            isLoading = false
            logger.debug("🎉 Import complete!")
        } catch {
            isLoading = false
            errorMessage = (error as? ImportError)?.errorDescription ?? error.localizedDescription
            logger.error("❌ Import failed: \(error.localizedDescription)")
        }
    }

    /// Fetches the page and parses it into an `ImportOutcome`, following up to
    /// five redirects. Runs off the main actor and touches no UI state, so it's
    /// unit-testable with a fake `HTMLFetching`.
    nonisolated func fetchAndParse(from url: URL, redirectCount: Int = 0) async throws -> ImportOutcome {
        guard redirectCount < 5 else {
            throw ImportError.tooManyRedirects
        }

        logger.debug("🌐 Fetching recipe from: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.timeoutInterval = 30

        let (data, httpResponse) = try await fetcher.fetch(request)
        logger.debug("📊 HTTP Status: \(httpResponse.statusCode)")

        if httpResponse.statusCode == 301 || httpResponse.statusCode == 302 {
            if let location = httpResponse.value(forHTTPHeaderField: "Location"),
               let redirectURL = URL(string: location, relativeTo: url) {
                logger.debug("↪️ Following redirect \(redirectCount + 1)/5 to: \(redirectURL.absoluteString)")
                return try await fetchAndParse(from: redirectURL, redirectCount: redirectCount + 1)
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
        logger.debug("🎯 Parse confidence: \(Int(parsed.confidence * 100))%")

        guard let name = parsed.name, !name.isEmpty else {
            throw ImportError.missingRequiredData("Recipe name not found")
        }

        guard !parsed.ingredients.isEmpty else {
            throw ImportError.missingRequiredData("No ingredients found")
        }

        // Instructions are optional — many sites structure them in ways the parser misses
        let instructions = parsed.instructions.isEmpty ? ["See original recipe for instructions."] : parsed.instructions

        let matchedIngredients = Self.matchIngredientsWithUSDA(parsed.ingredients)
        logger.debug("✅ Matched \(matchedIngredients.count)/\(parsed.ingredients.count) ingredients")

        let extracted = ExtractedRecipeData(
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

        return ImportOutcome(data: extracted, confidence: parsed.confidence)
    }

    private nonisolated static func matchIngredientsWithUSDA(_ ingredients: [String]) -> [String] {
        var matched: [String] = []
        let usdaFoods = FoodsList.getAllFoods()

        for ingredient in ingredients {
            let normalized = IngredientNormalizer.normalize(ingredient)

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

    private nonisolated static func extractFoodName(from ingredient: String) -> String {
        var cleaned = ingredient.lowercased()

        let quantityPattern = #"\b\d+[\d\/\.\s]*\s*(cup|tbsp|tsp|oz|lb|g|kg|ml|l)s?\b"#
        cleaned = cleaned.replacingOccurrences(of: quantityPattern, with: "", options: .regularExpression)

        let modifiers = ["diced", "chopped", "sliced", "minced", "crushed", "grated", "fresh", "dried", "frozen"]
        for modifier in modifiers {
            cleaned = cleaned.replacingOccurrences(of: "\\b\(modifier)\\b", with: "", options: .regularExpression)
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    enum ImportError: LocalizedError, Equatable {
        case invalidResponse
        case invalidEncoding
        case missingRequiredData(String)
        case tooManyRedirects

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Could not connect to the website. The site may be blocking automated requests or experiencing issues. Please try copying the recipe manually."
            case .invalidEncoding:
                return "Could not read the webpage content"
            case .missingRequiredData(let detail):
                return "Missing required data: \(detail)"
            case .tooManyRedirects:
                return "Too many redirects. Please try a different URL."
            }
        }
    }
}
