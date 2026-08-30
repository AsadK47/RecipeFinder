import Foundation

/// Matches recipes against the ingredients a user has in their kitchen. Extracted
/// from `KitchenView` so the fuzzy-matching and ranking logic is unit-testable
/// and no longer computed inline in a SwiftUI view.
enum KitchenRecipeMatcher {

    /// Normalises an ingredient name to its comparable main term (lowercased,
    /// whitespace-collapsed, brand/qualifier stripped via `IngredientNameFormatter`).
    static func normalizedTerm(_ raw: String) -> String {
        let main = IngredientNameFormatter.extractMainName(raw)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return main
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// Whether two normalised ingredient terms match. Exact matches always count;
    /// otherwise a substring match is allowed but only for terms of length ≥ 3 to
    /// avoid tiny terms like "b" matching everything.
    static func ingredientMatches(_ recipeIngredient: String, _ kitchenIngredient: String) -> Bool {
        if recipeIngredient == kitchenIngredient {
            return true
        }

        guard recipeIngredient.count >= 3, kitchenIngredient.count >= 3 else {
            return false
        }

        return recipeIngredient.contains(kitchenIngredient) || kitchenIngredient.contains(recipeIngredient)
    }

    /// How many of `recipe`'s ingredients match any of `kitchenIngredients`.
    /// `kitchenIngredients` is used as supplied (the caller decides normalisation).
    static func matchCount(recipe: RecipeModel, kitchenIngredients: Set<String>) -> Int {
        let recipeIngredients = recipe.ingredients
            .map { normalizedTerm($0.name) }
            .filter { !$0.isEmpty }

        return recipeIngredients.filter { recipeIng in
            kitchenIngredients.contains { kitchenIng in
                ingredientMatches(recipeIng, kitchenIng)
            }
        }.count
    }

    /// Recipes that share at least one ingredient with the kitchen, ranked by the
    /// number of matching ingredients (most matches first).
    static func quickMatches(recipes: [RecipeModel], kitchenItemNames: [String]) -> [RecipeModel] {
        guard !kitchenItemNames.isEmpty else { return [] }

        let kitchenIngredients = Set(
            kitchenItemNames
                .map { normalizedTerm($0) }
                .filter { !$0.isEmpty }
        )

        guard !kitchenIngredients.isEmpty else { return [] }

        return recipes.filter { recipe in
            let recipeIngredients = recipe.ingredients
                .map { normalizedTerm($0.name) }
                .filter { !$0.isEmpty }

            return recipeIngredients.contains { recipeIng in
                kitchenIngredients.contains { kitchenIng in
                    ingredientMatches(recipeIng, kitchenIng)
                }
            }
        }.sorted { recipe1, recipe2 in
            matchCount(recipe: recipe1, kitchenIngredients: kitchenIngredients) >
            matchCount(recipe: recipe2, kitchenIngredients: kitchenIngredients)
        }
    }
}
