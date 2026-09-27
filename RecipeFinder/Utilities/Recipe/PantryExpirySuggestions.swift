import Foundation

/// Pure helper surfacing recipes whose ingredients match pantry items expiring within three days; kept out of the view for isolated testing.
enum PantryExpirySuggestions {

    struct Match {
        let recipe: RecipeModel
        /// Inventory item names that are expiring and used by this recipe.
        let expiringItems: [String]
    }

    static let maxSuggestions = 3

    /// Up to `maxSuggestions` recipes using ≥1 item expiring within three days, sorted by match count (most first).
    static func matches(
        recipes: [RecipeModel],
        inventoryItems: [KitchenInventoryModel]
    ) -> [Match] {
        let expiring = inventoryItems.filter { $0.isExpiringSoon }
        guard !expiring.isEmpty else { return [] }

        let expiringNames = expiring.map { $0.name }
        let matched = KitchenRecipeMatcher.quickMatches(
            recipes: recipes,
            kitchenItemNames: expiringNames
        ).prefix(maxSuggestions)

        return matched.map { recipe in
            let recipeTerms = recipe.ingredients
                .map { KitchenRecipeMatcher.normalizedTerm($0.name) }
            let matchingNames = expiringNames.filter { name in
                let norm = KitchenRecipeMatcher.normalizedTerm(name)
                return recipeTerms.contains {
                    KitchenRecipeMatcher.ingredientMatches($0, norm)
                }
            }
            return Match(recipe: recipe, expiringItems: matchingNames)
        }
    }
}
