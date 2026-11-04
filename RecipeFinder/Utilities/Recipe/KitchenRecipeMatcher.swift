import Foundation

/// Matches recipes against a user's kitchen ingredients; extracted from `KitchenView` so fuzzy-match/ranking is unit-testable, not inline.
enum KitchenRecipeMatcher {

    // Normalization runs per recipe × ingredient × kitchen item on every pantry toggle; cache so repeated toggles are O(1).
    private static let normCache = MemoCache<String, String>(maxSize: 1000)

    /// Normalises an ingredient name to its comparable main term (lowercased, whitespace-collapsed, qualifiers stripped).
    static func normalizedTerm(_ raw: String) -> String {
        normCache.value(for: raw) { IngredientNameFormatter.matchKey($0) }
    }

    /// Two normalised terms match on exact equality or a shared whole word (≥3 chars), never on substrings ("gin" ≠ "ginger").
    static func ingredientMatches(_ recipeIngredient: String, _ kitchenIngredient: String) -> Bool {
        if recipeIngredient == kitchenIngredient {
            return true
        }

        return !words(recipeIngredient).isDisjoint(with: words(kitchenIngredient))
    }

    /// Whole words worth matching on (≥3 chars to drop filler like "of"), singularised so "egg" matches "eggs".
    private static func words(_ term: String) -> Set<String> {
        Set(
            term.split(separator: " ")
                .map(String.init)
                .filter { $0.count >= 3 }
                .map(singularized)
        )
    }

    /// Conservative English singularisation: only reshapes clear plural endings, else returns unchanged so it can't collide distinct ingredients ("ice"/"rice").
    private static func singularized(_ word: String) -> String {
        if word.count > 4, word.hasSuffix("ies") {
            return String(word.dropLast(3)) + "y"            // berries → berry
        }
        if word.count > 4,
           word.hasSuffix("ches") || word.hasSuffix("shes")
            || word.hasSuffix("oes") || word.hasSuffix("ses")
            || word.hasSuffix("xes") || word.hasSuffix("zes") {
            return String(word.dropLast(2))                  // tomatoes → tomato, boxes → box
        }
        if word.count > 3, word.hasSuffix("s"), !word.hasSuffix("ss") {
            return String(word.dropLast())                   // eggs → egg, carrots → carrot
        }
        return word
    }

    /// How many of `recipe`'s ingredients match any of `kitchenIngredients` (used as-supplied; caller decides normalisation).
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

    /// Recipes sharing ≥1 kitchen ingredient, ranked by match count (most first).
    static func quickMatches(recipes: [RecipeModel], kitchenItemNames: [String]) -> [RecipeModel] {
        guard !kitchenItemNames.isEmpty else { return [] }

        let kitchenIngredients = Set(
            kitchenItemNames
                .map { normalizedTerm($0) }
                .filter { !$0.isEmpty }
        )

        guard !kitchenIngredients.isEmpty else { return [] }

        // Pre-normalize each recipe's terms once so filter and sort reuse them; avoids re-normalizing per sort comparison (O(R log R × I × regex)).
        let normalized: [(recipe: RecipeModel, terms: [String])] = recipes.map { recipe in
            (recipe, recipe.ingredients.map { normalizedTerm($0.name) }.filter { !$0.isEmpty })
        }

        return normalized
            .filter { entry in
                entry.terms.contains { recipeIng in
                    kitchenIngredients.contains { kitchenIng in
                        ingredientMatches(recipeIng, kitchenIng)
                    }
                }
            }
            .sorted { a, b in
                let countMatches: ([String]) -> Int = { terms in
                    terms.filter { term in
                        kitchenIngredients.contains { kitchenIng in ingredientMatches(term, kitchenIng) }
                    }.count
                }
                return countMatches(a.terms) > countMatches(b.terms)
            }
            .map(\.recipe)
    }
}
