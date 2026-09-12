import Testing
import Foundation
@testable import RecipeFinder

/// Integration: `RecipeFilterCriteria.apply(to:)` working against a realistic
/// set of `RecipeModel` values. The unit tests in `RecipeFilterCriteriaTests`
/// check individual criteria in isolation; these tests verify the full
/// criteria object correctly gates the recipe list that the search view shows.
@Suite struct RecipeFilterIntegrationTests {

    private func recipe(
        name: String,
        category: String = "Main",
        difficulty: String = "Basic",
        cookingTime: String = "30 minutes",
        isFavorite: Bool = false,
        tags: [String] = [],
        dietary: DietaryInfo = DietaryInfo()
    ) -> RecipeModel {
        RecipeModel(
            id: UUID(),
            name: name,
            category: category,
            difficulty: difficulty,
            prepTime: "5 minutes",
            cookingTime: cookingTime,
            baseServings: 2,
            ingredients: [],
            prePrepInstructions: [],
            instructions: ["Cook it"],
            notes: "",
            isFavorite: isFavorite,
            tags: tags,
            dietaryInfo: dietary,
            isSampleRecipe: false
        )
    }

    private var corpus: [RecipeModel] {[
        recipe(name: "Pancakes",   category: "Breakfast", difficulty: "Basic",        cookingTime: "15 minutes",  isFavorite: true,  tags: ["quick"]),
        recipe(name: "Omelette",   category: "Breakfast", difficulty: "Basic",        cookingTime: "10 minutes",  isFavorite: false, tags: ["quick", "egg"]),
        recipe(name: "Pasta",      category: "Main",      difficulty: "Intermediate", cookingTime: "30 minutes",  isFavorite: false, tags: []),
        recipe(name: "Beef Stew",  category: "Main",      difficulty: "Expert",       cookingTime: "120 minutes", isFavorite: true,  tags: ["hearty"]),
        recipe(name: "Cheesecake", category: "Dessert",   difficulty: "Intermediate", cookingTime: "60 minutes",  isFavorite: false, tags: ["sweet"]),
        recipe(name: "Smoothie",   category: "Drink",     difficulty: "Basic",        cookingTime: "5 minutes",   isFavorite: false, tags: ["quick", "healthy"],
               dietary: { var d = DietaryInfo(); d.isVegan = true; return d }()),
    ]}

    private func criteria(
        search: String = "",
        categories: Set<String> = [],
        difficulties: Set<String> = [],
        cookTimes: Set<Int> = [],
        dietaryFilters: Set<String> = [],
        tags: Set<String> = [],
        favoritesOnly: Bool = false
    ) -> RecipeFilterCriteria {
        RecipeFilterCriteria(
            searchText: search,
            ingredientSearchText: "",
            availableIngredientsOnly: false,
            showFavoritesOnly: favoritesOnly,
            selectedCategories: categories,
            selectedDifficulties: difficulties,
            selectedCookTimes: cookTimes,
            selectedDietaryFilters: dietaryFilters,
            selectedTags: tags,
            availableIngredients: []
        )
    }

    // MARK: - No filters → all recipes pass

    @Test func noFilters_returnsAllRecipes() {
        let result = criteria().apply(to: corpus)
        #expect(result.count == corpus.count)
    }

    // MARK: - Text search

    @Test func textSearch_isCaseInsensitive() {
        let result = criteria(search: "pancakes").apply(to: corpus)
        #expect(result.map(\.name) == ["Pancakes"])
    }

    @Test func textSearch_partialMatch() {
        let result = criteria(search: "cake").apply(to: corpus)
        let names = Set(result.map(\.name))
        #expect(names.contains("Cheesecake"))
        #expect(names.contains("Pancakes"))
    }

    @Test func textSearch_noMatch_returnsEmpty() {
        let result = criteria(search: "xyzzy").apply(to: corpus)
        #expect(result.isEmpty)
    }

    // MARK: - Category filter

    @Test func categoryFilter_returnsOnlyMatchingCategory() {
        let result = criteria(categories: ["Breakfast"]).apply(to: corpus)
        #expect(result.allSatisfy { $0.category == "Breakfast" })
        #expect(result.count == 2)
    }

    @Test func categoryFilter_multipleCategories_union() {
        let result = criteria(categories: ["Breakfast", "Dessert"]).apply(to: corpus)
        let categories = Set(result.map(\.category))
        #expect(categories == ["Breakfast", "Dessert"])
    }

    // MARK: - Difficulty filter

    @Test func difficultyFilter_returnsOnlyMatchingDifficulty() {
        let result = criteria(difficulties: ["Basic"]).apply(to: corpus)
        #expect(result.allSatisfy { $0.difficulty == "Basic" })
    }

    @Test func difficultyFilter_expert_returnsOnlyExpert() {
        let result = criteria(difficulties: ["Expert"]).apply(to: corpus)
        #expect(result.map(\.name) == ["Beef Stew"])
    }

    // MARK: - Cook time filter

    @Test func cookTimeFilter_under30_excludesSlow() {
        let result = criteria(cookTimes: [30]).apply(to: corpus)
        // Compute the checks outside #expect — the macro can't expand multi-statement
        // or chained-negation expressions on older macro expansion paths.
        let allFit = result.map(\.cookingTime).allSatisfy { time in
            let minutes = Int(time.components(separatedBy: " ").first ?? "999") ?? 999
            return minutes <= 30
        }
        let names = result.map(\.name)
        let hasBeefStew = names.contains("Beef Stew")
        let hasCheesecake = names.contains("Cheesecake")
        #expect(allFit)
        #expect(!hasBeefStew)
        #expect(!hasCheesecake)
    }

    // MARK: - Favorites filter

    @Test func favoritesFilter_returnsOnlyFavorites() {
        let result = criteria(favoritesOnly: true).apply(to: corpus)
        #expect(result.allSatisfy { $0.isFavorite })
        #expect(Set(result.map(\.name)) == ["Pancakes", "Beef Stew"])
    }

    // MARK: - Tag filter

    @Test func tagFilter_returnsRecipesWithTag() {
        let result = criteria(tags: ["quick"]).apply(to: corpus)
        let names = Set(result.map(\.name))
        #expect(names.contains("Pancakes"))
        #expect(names.contains("Omelette"))
        #expect(names.contains("Smoothie"))
        let hasPasta = names.contains("Pasta")
        #expect(!hasPasta)
    }

    // MARK: - Compound filters

    @Test func compoundFilter_categoryAndDifficulty() {
        let result = criteria(categories: ["Breakfast"], difficulties: ["Basic"]).apply(to: corpus)
        #expect(result.allSatisfy { $0.category == "Breakfast" && $0.difficulty == "Basic" })
    }

    @Test func compoundFilter_favoritesAndCategory() {
        let result = criteria(categories: ["Main"], favoritesOnly: true).apply(to: corpus)
        #expect(result.map(\.name) == ["Beef Stew"])
    }

    @Test func compoundFilter_searchAndCategory() {
        // "sta" matches only "Pasta" among all recipes; combined with Main category → ["Pasta"].
        let result = criteria(search: "sta", categories: ["Main"]).apply(to: corpus)
        #expect(result.map(\.name) == ["Pasta"])
    }

    // MARK: - activeCount

    @Test func activeCount_incrementsPerFilter() {
        #expect(criteria().activeCount == 0)
        #expect(criteria(categories: ["Breakfast"]).activeCount == 1)
        #expect(criteria(categories: ["Breakfast"], difficulties: ["Basic"]).activeCount == 2)
        #expect(criteria(favoritesOnly: true).activeCount == 1)
    }
}
