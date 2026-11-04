import Foundation

enum SortOrder: String, CaseIterable, Hashable {
    case nameAZ = "Name (A–Z)"
    case nameZA = "Name (Z–A)"
    case ratingHighLow = "Highest Rated"
    case mostCooked = "Most Cooked"
}

/// Full recipe-search filter set as a plain value; extracted from `RecipeSearchView` so filter/sort is pure and testable (view builds one from `@State` and calls `apply(to:)`).
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
    var selectedCuisines: Set<String> = []

    /// Post-filter sort order; ignored when ingredient-match ranking is active (percentage rank beats alphabetical there).
    var sortOrder: SortOrder = .nameAZ

    /// When non-nil, only recipes whose `id` is in this set pass; caller resolves the collection so criteria stays independent of `CollectionManager`.
    var selectedCollectionRecipeIDs: Set<UUID>? = nil

    /// Lowercased kitchen inventory; only consulted when `availableIngredientsOnly` is set, to filter and rank by how much you can make.
    var availableIngredients: Set<String> = []

    /// Count of active *chips*; excludes free-text `searchText` and `sortOrder` (own control, no chip).
    var activeCount: Int {
        selectedCategories.count +
        selectedDifficulties.count +
        selectedCookTimes.count +
        selectedDietaryFilters.count +
        selectedTags.count +
        selectedCuisines.count +
        (showFavoritesOnly ? 1 : 0) +
        (availableIngredientsOnly ? 1 : 0) +
        (!ingredientSearchText.isEmpty ? 1 : 0) +
        (selectedCollectionRecipeIDs != nil ? 1 : 0)
    }

    /// Applies every active filter, then ranks by ingredient match when "can make now" is on; filter order mirrors the original view to stay behavior-preserving.
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
            // Normalise so legacy/imported labels ("Medium", "Easy") still match the Basic/Intermediate/Expert filter chips.
            results = results.filter { selectedDifficulties.contains(RecipeWizardBuilder.normalizeDifficulty($0.difficulty)) }
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

        if !selectedCuisines.isEmpty {
            results = results.filter { recipe in
                guard let cuisine = recipe.cuisine else { return false }
                return selectedCuisines.contains(cuisine)
            }
        }

        // "Can make now": keep mostly-makeable recipes ranked by match %, taking precedence over sortOrder; % computed once here, not per comparator call.
        if availableIngredientsOnly && !availableIngredients.isEmpty {
            return results
                .map { ($0, $0.ingredientMatchPercentage(availableIngredients: availableIngredients)) }
                .filter { $0.1 >= 0.8 }
                .sorted { $0.1 > $1.1 }
                .map { $0.0 }
        }

        switch sortOrder {
        case .nameAZ:
            results = results.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        case .nameZA:
            results = results.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending
            }
        case .ratingHighLow:
            results = results.sorted {
                if $0.rating != $1.rating { return $0.rating > $1.rating }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        case .mostCooked:
            results = results.sorted {
                if $0.cookCount != $1.cookCount { return $0.cookCount > $1.cookCount }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }

        return results
    }
}
