import Foundation

/// The full set of recipe-search filters as a plain value.
///
/// Extracted from `RecipeSearchView` so the filtering/sorting is pure and unit
/// testable, and so the work no longer lives inline in a SwiftUI `body`. The view
/// builds one of these from its `@State` and calls `apply(to:)`.
struct RecipeFilterCriteria: Hashable {
    var searchText: String = ""
    var ingredientSearchText: String = ""
    var availableIngredientsOnly: Bool = false
    var showFavoritesOnly: Bool = false
    var selectedCategories: Set<String> = []
    var selectedDifficulties: Set<String> = []
    var selectedCookTimes: Set<Int> = []
    var selectedDietaryFilters: Set<String> = []
    var selectedTags: Set<String> = []

    /// When non-nil, only recipes whose `id` is in this set pass the filter.
    /// The caller resolves which IDs belong to the chosen collection; the
    /// criteria stays pure and independent of `CollectionManager`.
    var selectedCollectionRecipeIDs: Set<UUID>? = nil

    /// Kitchen inventory, lowercased. Only consulted when `availableIngredientsOnly`
    /// is set; used both to filter and to rank by how much of a recipe you can make.
    var availableIngredients: Set<String> = []

    /// Number of *chips* the UI shows as active. Deliberately excludes free-text
    /// `searchText` (which has its own field) to match the existing badge count.
    var activeCount: Int {
        selectedCategories.count +
        selectedDifficulties.count +
        selectedCookTimes.count +
        selectedDietaryFilters.count +
        selectedTags.count +
        (showFavoritesOnly ? 1 : 0) +
        (availableIngredientsOnly ? 1 : 0) +
        (!ingredientSearchText.isEmpty ? 1 : 0) +
        (selectedCollectionRecipeIDs != nil ? 1 : 0)
    }

    /// Applies every active filter, then ranks by ingredient match when
    /// "can make now" is on. Order of the individual filters is irrelevant to the
    /// result; it mirrors the original view code to stay behavior-preserving.
    func apply(to recipes: [RecipeModel]) -> [RecipeModel] {
        var results = recipes

        if showFavoritesOnly {
            results = results.filter { $0.isFavorite }
        }

        if !searchText.isEmpty {
            results = results.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        if !ingredientSearchText.isEmpty {
            results = results.filter { $0.containsIngredient(ingredientSearchText) }
        }

        if !selectedCategories.isEmpty {
            results = results.filter { selectedCategories.contains($0.category) }
        }

        if !selectedDifficulties.isEmpty {
            results = results.filter { selectedDifficulties.contains($0.difficulty) }
        }

        if !selectedCookTimes.isEmpty {
            results = results.filter { recipe in
                let time = TimeExtractor.extractMinutes(from: recipe.cookingTime)
                return selectedCookTimes.contains { time <= $0 }
            }
        }

        if !selectedDietaryFilters.isEmpty {
            results = results.filter { recipe in
                selectedDietaryFilters.allSatisfy { dietaryTag in
                    switch dietaryTag {
                    case "Vegetarian": return recipe.dietaryInfo.isVegetarian
                    case "Vegan": return recipe.dietaryInfo.isVegan
                    case "Gluten-Free": return recipe.dietaryInfo.isGlutenFree
                    case "Dairy-Free": return recipe.dietaryInfo.isDairyFree
                    case "Nut-Free": return recipe.dietaryInfo.isNutFree
                    case "Low-Carb": return recipe.dietaryInfo.isLowCarb
                    case "Keto": return recipe.dietaryInfo.isKeto
                    default: return true
                    }
                }
            }
        }

        if !selectedTags.isEmpty {
            results = results.filter { recipe in
                !Set(recipe.tags).isDisjoint(with: selectedTags)
            }
        }

        if let collectionIDs = selectedCollectionRecipeIDs {
            results = results.filter { collectionIDs.contains($0.id) }
        }

        // "Can make now": keep recipes you can mostly make and rank by how much.
        // The match percentage is computed once per recipe here — not inside the
        // sort comparator, which would recompute it O(n log n) times.
        if availableIngredientsOnly && !availableIngredients.isEmpty {
            results = results
                .map { ($0, $0.ingredientMatchPercentage(availableIngredients: availableIngredients)) }
                .filter { $0.1 >= 0.8 }
                .sorted { $0.1 > $1.1 }
                .map { $0.0 }
        }

        return results
    }
}
