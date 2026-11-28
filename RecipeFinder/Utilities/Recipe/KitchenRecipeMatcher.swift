import Foundation

/// Matches recipes against a user's kitchen ingredients; extracted from `KitchenView` so fuzzy-match/ranking is unit-testable, not inline.
enum KitchenRecipeMatcher {

    // Normalization runs per recipe × ingredient × kitchen item on every pantry toggle; cache so repeated toggles are O(1).
    private static let normCache = MemoCache<String, String>(maxSize: 1000)

    /// Normalises an ingredient name to its comparable main term (lowercased, whitespace-collapsed, qualifiers stripped).
    static func normalizedTerm(_ raw: String) -> String {
        normCache.value(for: raw) { IngredientNameFormatter.matchKey($0) }
    }

    private static let termCache = MemoCache<String, MatchTerm>(maxSize: 4000)

    /// The prepared match term for a raw ingredient name, nil when it normalises to nothing. Cached: discovery and
    /// Today check every recipe's ingredients on each rebuild, and names repeat across rebuilds.
    static func matchTerm(_ raw: String) -> MatchTerm? {
        let prepared = termCache.value(for: raw) { MatchTerm(normalizedTerm($0)) }
        return prepared.term.isEmpty ? nil : prepared
    }

    /// Two normalised terms match on exact equality or a shared whole word (≥3 chars), never on substrings ("gin" ≠ "ginger").
    static func ingredientMatches(_ recipeIngredient: String, _ kitchenIngredient: String) -> Bool {
        if recipeIngredient == kitchenIngredient {
            return true
        }

        return !words(recipeIngredient).isDisjoint(with: words(kitchenIngredient))
    }

    /// A normalised term with its match words built once, so batch checks (recipes × ingredients × pantry) don't
    /// rebuild both word sets for every pair — that made a 350-recipe discovery rebuild take ~1 s.
    struct MatchTerm: Sendable {
        let term: String
        let words: Set<String>

        init(_ term: String) {
            self.term = term
            words = KitchenRecipeMatcher.words(term)
        }
    }

    /// Same rule as `ingredientMatches(_:_:)` on prepared terms.
    static func ingredientMatches(_ recipeIngredient: MatchTerm, _ kitchenIngredient: MatchTerm) -> Bool {
        recipeIngredient.term == kitchenIngredient.term || !recipeIngredient.words.isDisjoint(with: kitchenIngredient.words)
    }

    /// Whole words worth matching on (≥3 chars to drop filler like "of"), singularised so "egg" matches "eggs".
    /// "Leaf" names a form, not a food: "bay leaf" in the kitchen is no "mint leaves" for the recipe.
    fileprivate static func words(_ term: String) -> Set<String> {
        Set(
            term.split(separator: " ")
                .map(String.init)
                .filter { $0.count >= 3 }
                .map(EnglishPlural.singular)
        ).subtracting(formWords)
    }

    private static let formWords: Set<String> = ["leaf"]

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
