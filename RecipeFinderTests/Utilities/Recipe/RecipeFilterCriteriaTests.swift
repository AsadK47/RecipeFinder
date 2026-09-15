import Testing
import Foundation
@testable import RecipeFinder

@Suite("RecipeFilterCriteria")
struct RecipeFilterCriteriaTests {

    // MARK: - Fixtures

    private func makeRecipe(
        name: String = "Test Recipe",
        category: String = "Main",
        difficulty: String = "Basic",
        cookingTime: String = "20 min",
        isFavorite: Bool = false,
        tags: [String] = [],
        dietaryInfo: DietaryInfo = DietaryInfo(),
        ingredientNames: [String] = [],
        cuisine: String? = nil,
        rating: Int = 0,
        cookCount: Int = 0
    ) -> RecipeModel {
        RecipeModel(
            name: name,
            category: category,
            difficulty: difficulty,
            prepTime: "10 min",
            cookingTime: cookingTime,
            baseServings: 4,
            ingredients: ingredientNames.map { Ingredient(baseQuantity: 1, unit: "cup", name: $0) },
            prePrepInstructions: [],
            instructions: [],
            notes: "",
            isFavorite: isFavorite,
            tags: tags,
            dietaryInfo: dietaryInfo,
            cookCount: cookCount,
            rating: rating,
            cuisine: cuisine
        )
    }

    // MARK: - No-op

    @Test("Empty criteria returns every recipe, in order")
    func emptyReturnsAll() {
        let recipes = [makeRecipe(name: "A"), makeRecipe(name: "B"), makeRecipe(name: "C")]
        let result = RecipeFilterCriteria().apply(to: recipes)
        #expect(result.map(\.name) == ["A", "B", "C"])
    }

    // MARK: - Individual filters

    @Test("Favorites-only keeps only favorites")
    func favoritesOnly() {
        let recipes = [makeRecipe(name: "Fav", isFavorite: true), makeRecipe(name: "Plain")]
        var criteria = RecipeFilterCriteria()
        criteria.showFavoritesOnly = true
        #expect(criteria.apply(to: recipes).map(\.name) == ["Fav"])
    }

    @Test("Name search is case-insensitive and substring-based")
    func nameSearch() {
        let recipes = [makeRecipe(name: "Chicken Curry"), makeRecipe(name: "Beef Stew")]
        var criteria = RecipeFilterCriteria()
        criteria.searchText = "curry"
        #expect(criteria.apply(to: recipes).map(\.name) == ["Chicken Curry"])
    }

    @Test("Ingredient text search matches on ingredient name")
    func ingredientSearch() {
        let recipes = [
            makeRecipe(name: "Has Basil", ingredientNames: ["Fresh Basil"]),
            makeRecipe(name: "No Basil", ingredientNames: ["Salt"])
        ]
        var criteria = RecipeFilterCriteria()
        criteria.ingredientSearchText = "basil"
        #expect(criteria.apply(to: recipes).map(\.name) == ["Has Basil"])
    }

    @Test("Category filter keeps only selected categories")
    func categoryFilter() {
        let recipes = [makeRecipe(name: "M", category: "Main"), makeRecipe(name: "D", category: "Dessert")]
        var criteria = RecipeFilterCriteria()
        criteria.selectedCategories = ["Dessert"]
        #expect(criteria.apply(to: recipes).map(\.name) == ["D"])
    }

    @Test("Difficulty filter keeps only selected difficulties")
    func difficultyFilter() {
        let recipes = [makeRecipe(name: "E", difficulty: "Basic"), makeRecipe(name: "H", difficulty: "Expert")]
        var criteria = RecipeFilterCriteria()
        criteria.selectedDifficulties = ["Expert"]
        #expect(criteria.apply(to: recipes).map(\.name) == ["H"])
    }

    @Test("Cook-time filter keeps recipes at or under the selected threshold")
    func cookTimeFilter() {
        let recipes = [
            makeRecipe(name: "Quick", cookingTime: "15 min"),
            makeRecipe(name: "Slow", cookingTime: "60 min")
        ]
        var criteria = RecipeFilterCriteria()
        criteria.selectedCookTimes = [30]
        #expect(criteria.apply(to: recipes).map(\.name) == ["Quick"])
    }

    @Test("Dietary filter matches each dietary tag", arguments: [
        ("Vegetarian", DietaryInfo(isVegetarian: true)),
        ("Vegan", DietaryInfo(isVegan: true)),
        ("Gluten-Free", DietaryInfo(isGlutenFree: true)),
        ("Dairy-Free", DietaryInfo(isDairyFree: true)),
        ("Nut-Free", DietaryInfo(isNutFree: true)),
        ("Low-Carb", DietaryInfo(isLowCarb: true)),
        ("Keto", DietaryInfo(isKeto: true))
    ])
    func dietaryFilter(tag: String, info: DietaryInfo) {
        let recipes = [
            makeRecipe(name: "Matches", dietaryInfo: info),
            makeRecipe(name: "Plain", dietaryInfo: DietaryInfo())
        ]
        var criteria = RecipeFilterCriteria()
        criteria.selectedDietaryFilters = [tag]
        #expect(criteria.apply(to: recipes).map(\.name) == ["Matches"])
    }

    @Test("Multiple dietary filters require all to be satisfied")
    func dietaryFilterAllRequired() {
        let recipes = [
            makeRecipe(name: "Both", dietaryInfo: DietaryInfo(isVegetarian: true, isVegan: true)),
            makeRecipe(name: "VegOnly", dietaryInfo: DietaryInfo(isVegetarian: true))
        ]
        var criteria = RecipeFilterCriteria()
        criteria.selectedDietaryFilters = ["Vegetarian", "Vegan"]
        #expect(criteria.apply(to: recipes).map(\.name) == ["Both"])
    }

    @Test("Tag filter keeps recipes sharing at least one selected tag")
    func tagFilter() {
        let recipes = [
            makeRecipe(name: "Spicy", tags: ["spicy", "quick"]),
            makeRecipe(name: "Mild", tags: ["mild"])
        ]
        var criteria = RecipeFilterCriteria()
        criteria.selectedTags = ["spicy"]
        #expect(criteria.apply(to: recipes).map(\.name) == ["Spicy"])
    }

    // MARK: - Available ingredients (filter + ranking)

    @Test("Can-make-now keeps recipes matching >= 80% and ranks by match")
    func availableIngredientsFilterAndSort() {
        let fullMatch = makeRecipe(name: "Full", ingredientNames: ["chicken"])
        let partial = makeRecipe(name: "Partial", ingredientNames: ["chicken", "rice", "peas", "curry"])
        let recipes = [partial, fullMatch]

        var criteria = RecipeFilterCriteria()
        criteria.availableIngredientsOnly = true
        criteria.availableIngredients = ["chicken"]

        // Partial is 1/4 = 0.25 (< 0.8) so it's dropped; only the full match remains.
        #expect(criteria.apply(to: recipes).map(\.name) == ["Full"])
    }

    @Test("Can-make-now with an empty pantry is a no-op")
    func availableIngredientsEmptyPantry() {
        let recipes = [makeRecipe(name: "A", ingredientNames: ["chicken"]), makeRecipe(name: "B")]
        var criteria = RecipeFilterCriteria()
        criteria.availableIngredientsOnly = true
        criteria.availableIngredients = []
        #expect(criteria.apply(to: recipes).map(\.name) == ["A", "B"])
    }

    // MARK: - Combining filters

    @Test("Filters combine with AND semantics")
    func filtersCombine() {
        let recipes = [
            makeRecipe(name: "Target", category: "Main", isFavorite: true),
            makeRecipe(name: "WrongCategory", category: "Dessert", isFavorite: true),
            makeRecipe(name: "NotFavorite", category: "Main", isFavorite: false)
        ]
        var criteria = RecipeFilterCriteria()
        criteria.selectedCategories = ["Main"]
        criteria.showFavoritesOnly = true
        #expect(criteria.apply(to: recipes).map(\.name) == ["Target"])
    }

    // MARK: - activeCount

    @Test("activeCount sums chip filters and ignores free-text search")
    func activeCountSumsChips() {
        var criteria = RecipeFilterCriteria()
        criteria.searchText = "ignored"          // not counted
        criteria.showFavoritesOnly = true          // +1
        criteria.availableIngredientsOnly = true   // +1
        criteria.ingredientSearchText = "basil"    // +1
        criteria.selectedCategories = ["Main", "Side"] // +2
        criteria.selectedDifficulties = ["Basic"]  // +1
        criteria.selectedCookTimes = [30]          // +1
        criteria.selectedDietaryFilters = ["Vegan"] // +1
        criteria.selectedTags = ["spicy"]          // +1
        #expect(criteria.activeCount == 9)
    }

    @Test("activeCount is zero for empty criteria")
    func activeCountEmpty() {
        #expect(RecipeFilterCriteria().activeCount == 0)
    }

    // MARK: - Collection filter

    @Test("Collection filter keeps only recipes whose id is in the set")
    func collectionFilter_keepsMembersOnly() {
        let inCollection = makeRecipe(name: "In Collection")
        let outside = makeRecipe(name: "Outside")
        var criteria = RecipeFilterCriteria()
        criteria.selectedCollectionRecipeIDs = [inCollection.id]

        #expect(criteria.apply(to: [inCollection, outside]).map(\.name) == ["In Collection"])
    }

    @Test("Collection filter nil means no constraint — all recipes pass")
    func collectionFilter_nil_returnsAll() {
        let recipes = [makeRecipe(name: "A"), makeRecipe(name: "B")]
        var criteria = RecipeFilterCriteria()
        criteria.selectedCollectionRecipeIDs = nil

        #expect(criteria.apply(to: recipes).count == 2)
    }

    @Test("Collection filter with an empty set returns no recipes")
    func collectionFilter_emptySet_returnsNone() {
        let recipes = [makeRecipe(name: "A"), makeRecipe(name: "B")]
        var criteria = RecipeFilterCriteria()
        criteria.selectedCollectionRecipeIDs = []

        #expect(criteria.apply(to: recipes).isEmpty)
    }

    @Test("Collection filter combines with tag filter using AND semantics")
    func collectionFilter_combinesWithTagFilter() {
        let spicyIn = makeRecipe(name: "SpicyIn", tags: ["spicy"])
        let mildIn = makeRecipe(name: "MildIn", tags: [])
        let spicyOut = makeRecipe(name: "SpicyOut", tags: ["spicy"])
        var criteria = RecipeFilterCriteria()
        criteria.selectedCollectionRecipeIDs = [spicyIn.id, mildIn.id]
        criteria.selectedTags = ["spicy"]

        #expect(criteria.apply(to: [spicyIn, mildIn, spicyOut]).map(\.name) == ["SpicyIn"])
    }

    @Test("activeCount increments by 1 when a collection filter is set")
    func collectionFilter_incrementsActiveCount() {
        var criteria = RecipeFilterCriteria()
        #expect(criteria.activeCount == 0)

        criteria.selectedCollectionRecipeIDs = [UUID()]
        #expect(criteria.activeCount == 1)
    }

    // MARK: - Cuisine filter

    @Test("Cuisine filter keeps only recipes with a matching cuisine")
    func cuisineFilter_keepsCuisineMatch() {
        let italian = makeRecipe(name: "Pizza", cuisine: "Italian")
        let mexican = makeRecipe(name: "Tacos", cuisine: "Mexican")
        var criteria = RecipeFilterCriteria()
        criteria.selectedCuisines = ["Italian"]
        #expect(criteria.apply(to: [italian, mexican]).map(\.name) == ["Pizza"])
    }

    @Test("Cuisine filter with empty set is a no-op")
    func cuisineFilter_emptySet_isNoOp() {
        let recipes = [makeRecipe(name: "A", cuisine: "Italian"), makeRecipe(name: "B")]
        var criteria = RecipeFilterCriteria()
        criteria.selectedCuisines = []
        #expect(criteria.apply(to: recipes).count == 2)
    }

    @Test("Cuisine filter excludes recipes with a nil cuisine value")
    func cuisineFilter_nilCuisine_isExcluded() {
        let italian = makeRecipe(name: "Pizza", cuisine: "Italian")
        let unknown = makeRecipe(name: "Mystery")
        var criteria = RecipeFilterCriteria()
        criteria.selectedCuisines = ["Italian"]
        #expect(criteria.apply(to: [italian, unknown]).map(\.name) == ["Pizza"])
    }

    @Test("Cuisine filter increments activeCount once per selected cuisine")
    func cuisineFilter_incrementsActiveCount() {
        var criteria = RecipeFilterCriteria()
        #expect(criteria.activeCount == 0)
        criteria.selectedCuisines = ["Italian", "Mexican"]
        #expect(criteria.activeCount == 2)
    }

    @Test("Cuisine filter combines with category filter using AND semantics")
    func cuisineFilter_combinesWithCategoryFilter() {
        let italianMain    = makeRecipe(name: "Pasta",    category: "Main",    cuisine: "Italian")
        let italianDessert = makeRecipe(name: "Tiramisu", category: "Dessert", cuisine: "Italian")
        let mexicanMain    = makeRecipe(name: "Tacos",    category: "Main",    cuisine: "Mexican")
        var criteria = RecipeFilterCriteria()
        criteria.selectedCuisines = ["Italian"]
        criteria.selectedCategories = ["Main"]
        #expect(criteria.apply(to: [italianMain, italianDessert, mexicanMain]).map(\.name) == ["Pasta"])
    }

    // MARK: - Sort order

    @Test("Sort nameAZ orders recipes alphabetically ascending")
    func sort_nameAZ_ascending() {
        let recipes = [makeRecipe(name: "Zebra"), makeRecipe(name: "Apple"), makeRecipe(name: "Mango")]
        var criteria = RecipeFilterCriteria()
        criteria.sortOrder = .nameAZ
        #expect(criteria.apply(to: recipes).map(\.name) == ["Apple", "Mango", "Zebra"])
    }

    @Test("Sort nameZA orders recipes alphabetically descending")
    func sort_nameZA_descending() {
        let recipes = [makeRecipe(name: "Apple"), makeRecipe(name: "Zebra"), makeRecipe(name: "Mango")]
        var criteria = RecipeFilterCriteria()
        criteria.sortOrder = .nameZA
        #expect(criteria.apply(to: recipes).map(\.name) == ["Zebra", "Mango", "Apple"])
    }

    @Test("Sort ratingHighLow orders by rating desc, name asc as tiebreak")
    func sort_ratingHighLow_ordersCorrectly() {
        let recipes = [
            makeRecipe(name: "C-recipe", rating: 3),
            makeRecipe(name: "A-recipe", rating: 5),
            makeRecipe(name: "B-recipe", rating: 5)
        ]
        var criteria = RecipeFilterCriteria()
        criteria.sortOrder = .ratingHighLow
        #expect(criteria.apply(to: recipes).map(\.name) == ["A-recipe", "B-recipe", "C-recipe"])
    }

    @Test("Sort mostCooked orders by cookCount desc, name asc as tiebreak")
    func sort_mostCooked_ordersCorrectly() {
        let recipes = [
            makeRecipe(name: "C-recipe", cookCount: 1),
            makeRecipe(name: "A-recipe", cookCount: 10),
            makeRecipe(name: "B-recipe", cookCount: 10)
        ]
        var criteria = RecipeFilterCriteria()
        criteria.sortOrder = .mostCooked
        #expect(criteria.apply(to: recipes).map(\.name) == ["A-recipe", "B-recipe", "C-recipe"])
    }

    @Test("Sort order does not increment activeCount")
    func sort_doesNotIncrementActiveCount() {
        var criteria = RecipeFilterCriteria()
        criteria.sortOrder = .nameZA
        #expect(criteria.activeCount == 0)
    }

    @Test("ingredientMatch ranking takes precedence over sortOrder")
    func sort_ingredientMatchTakesPrecedence() {
        // nameZA would put "Zzz" last alphabetically, but ingredient-match ranks it 100% → first
        let fullMatch    = makeRecipe(name: "Zzz", ingredientNames: ["chicken"])
        let noMatch      = makeRecipe(name: "Aaa", ingredientNames: ["tofu", "seitan", "rice", "miso"])
        var criteria = RecipeFilterCriteria()
        criteria.sortOrder = .nameZA
        criteria.availableIngredientsOnly = true
        criteria.availableIngredients = ["chicken"]
        // noMatch is 0 of 4 (0%) — filtered; fullMatch is 1 of 1 (100%) — passes
        #expect(criteria.apply(to: [noMatch, fullMatch]).map(\.name) == ["Zzz"])
    }
}
