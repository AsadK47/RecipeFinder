import Foundation

/// Pure, side-effect-free helper that surfaces recipes whose ingredients
/// match pantry items expiring within the next three days.
/// Kept separate from the view so the logic is unit-testable in isolation.
enum PantryExpirySuggestions {

    struct Match {
        let recipe: RecipeModel
        /// Inventory item names that are expiring and used by this recipe.
        let expiringItems: [String]
    }

    static let maxSuggestions = 3

    /// Returns up to `maxSuggestions` recipes that use at least one item
    /// expiring within three days, sorted by match count (most matches first).
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
