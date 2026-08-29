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
        ingredientNames: [String] = []
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
            dietaryInfo: dietaryInfo
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
}
