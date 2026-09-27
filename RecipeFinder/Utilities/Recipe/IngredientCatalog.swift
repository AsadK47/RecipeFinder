import Foundation

/// Pure ingredient/recipe queries backing `IngredientSearchView`; extracted from the view so browse/search/filter logic is unit-testable, not inline in `body`.
struct IngredientCatalog {
    let recipes: [RecipeModel]

    /// Every distinct ingredient name across all recipes, sorted alphabetically.
    var allIngredients: [String] {
        Set(recipes.flatMap { $0.ingredients.map { $0.name } }).sorted()
    }

    /// Ingredients grouped under matching kitchen categories with similar ones collapsed; empty categories omitted.
    var categorizedIngredients: [(category: String, ingredients: [String])] {
        let ingredients = allIngredients
        return CategoryClassifier.kitchenCategories.compactMap { category in
            guard let keywords = CategoryClassifier.kitchenIngredientKeywords[category] else { return nil }
            let matched = ingredients.filter { ingredient in
                keywords.contains { keyword in
                    ingredient.localizedCaseInsensitiveContains(keyword)
                }
            }
            let grouped = CategoryClassifier.groupSimilarIngredients(matched)
            return grouped.isEmpty ? nil : (category, grouped.sorted())
        }
    }

    /// `categorizedIngredients` limited to `selected` categories (all if empty).
    func categorizedIngredients(filteredBy selected: Set<String>) -> [(category: String, ingredients: [String])] {
        if selected.isEmpty {
            return categorizedIngredients
        }
        return categorizedIngredients.filter { selected.contains($0.category) }
    }

    /// Ingredient names matching `query` (empty for an empty query).
    func searchResults(for query: String) -> [String] {
        if query.isEmpty {
            return []
        }
        return allIngredients.filter { $0.localizedCaseInsensitiveContains(query) }
    }

    /// Recipes containing `ingredient`, or all recipes when `ingredient` is nil.
    func recipes(containing ingredient: String?) -> [RecipeModel] {
        guard let ingredient else { return recipes }
        return recipes.filter { recipe in
            recipe.ingredients.contains { $0.name.localizedCaseInsensitiveContains(ingredient) }
        }
    }

    /// How many recipes contain `ingredient`.
    func recipeCount(for ingredient: String) -> Int {
        recipes.filter { recipe in
            recipe.ingredients.contains { $0.name.localizedCaseInsensitiveContains(ingredient) }
        }.count
    }

    /// All ingredient names that contain `mainIngredient`, sorted.
    func variations(of mainIngredient: String) -> [String] {
        allIngredients.filter { ingredient in
            ingredient.localizedCaseInsensitiveContains(mainIngredient)
        }.sorted()
    }
}
