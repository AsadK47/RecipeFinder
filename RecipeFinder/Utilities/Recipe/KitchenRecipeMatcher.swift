import Foundation

/// Matches recipes against the ingredients a user has in their kitchen. Extracted
/// from `KitchenView` so the fuzzy-matching and ranking logic is unit-testable
/// and no longer computed inline in a SwiftUI view.
enum KitchenRecipeMatcher {

    // Ingredient name normalization is called for every recipe × ingredient × kitchen item
    // on every pantry toggle. Cache results so repeated toggles are O(1) after the first pass.
    private static let normCache = MemoCache<String, String>(maxSize: 1000)

    /// Normalises an ingredient name to its comparable main term (lowercased,
    /// whitespace-collapsed, brand/qualifier stripped via `IngredientNameFormatter`).
    static func normalizedTerm(_ raw: String) -> String {
        normCache.value(for: raw) { _ in
            let main = IngredientNameFormatter.extractMainName(raw)
                .lowercased()
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return main
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }
    }

    /// Whether two normalised ingredient terms match. Exact matches always count;
    /// otherwise they match only when they share a whole word (≥ 3 chars) — so a
    /// multi-word ingredient like "chicken breast" matches "chicken", but a short
    /// term is never matched as a mere substring of a longer word (e.g. "gin" must
    /// not match "ginger", "ice" must not match "rice").
    static func ingredientMatches(_ recipeIngredient: String, _ kitchenIngredient: String) -> Bool {
        if recipeIngredient == kitchenIngredient {
            return true
        }

        return !words(recipeIngredient).isDisjoint(with: words(kitchenIngredient))
    }

    /// The set of whole words in a term worth matching on (≥ 3 chars, so filler like
    /// "of" can't create spurious matches). Words are singularised so a pantry
    /// "egg" matches a recipe's "eggs" (and "tomato" ↔ "tomatoes").
    private static func words(_ term: String) -> Set<String> {
        Set(
            term.split(separator: " ")
                .map(String.init)
                .filter { $0.count >= 3 }
                .map(singularized)
        )
    }

    /// Conservative English singularisation for plural matching. Only reshapes
    /// clear plural endings; anything else is returned unchanged so it can't
    /// collide distinct ingredients (e.g. "ice"/"rice" stay put).
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

        // Pre-normalize each recipe's ingredient terms once so both the filter pass and
        // the sort pass reuse the same strings — previously `matchCount` re-normalized
        // every recipe's ingredients for every sort comparison (O(R log R × I × regex)).
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
