import Testing
import Foundation
@testable import RecipeFinder

@Suite("IngredientCatalog")
struct IngredientCatalogTests {

    // MARK: - Fixtures

    private func ingredient(_ name: String) -> Ingredient {
        Ingredient(baseQuantity: 1.0, unit: "", name: name)
    }

    private func recipe(_ ingredientNames: [String]) -> RecipeModel {
        RecipeModel(
            name: "Test Recipe",
            category: "Test",
            difficulty: "Easy",
            prepTime: "10 min",
            cookingTime: "20 min",
            baseServings: 4,
            currentServings: 4,
            ingredients: ingredientNames.map(ingredient),
            prePrepInstructions: [],
            instructions: [],
            notes: ""
        )
    }

    private var sut: IngredientCatalog {
        IngredientCatalog(recipes: [
            recipe(["Garlic", "Chicken Breast"]),
            recipe(["Garlic", "Onion"]),
            recipe(["Salmon"]),
            recipe(["Chicken Thigh"])
        ])
    }

    // MARK: - allIngredients

    @Test("All ingredients are distinct and sorted alphabetically")
    func allIngredientsAreDistinctAndSorted() {
        #expect(sut.allIngredients == ["Chicken Breast", "Chicken Thigh", "Garlic", "Onion", "Salmon"])
    }

    // MARK: - searchResults

    @Test("Search matches case-insensitively on a substring")
    func searchMatchesSubstringCaseInsensitively() {
        #expect(sut.searchResults(for: "gar") == ["Garlic"])
        #expect(sut.searchResults(for: "chicken") == ["Chicken Breast", "Chicken Thigh"])
    }

    @Test("An empty query returns no results")
    func emptyQueryReturnsNothing() {
        #expect(sut.searchResults(for: "").isEmpty)
    }

    // MARK: - recipes(containing:)

    @Test("Recipes are filtered to those containing the ingredient")
    func recipesContainingIngredient() {
        #expect(sut.recipes(containing: "garlic").count == 2)
        #expect(sut.recipes(containing: "salmon").count == 1)
    }

    @Test("A nil ingredient returns all recipes")
    func nilIngredientReturnsAll() {
        #expect(sut.recipes(containing: nil).count == 4)
    }

    // MARK: - recipeCount

    @Test("Recipe count reflects how many recipes contain the ingredient")
    func recipeCountMatches() {
        #expect(sut.recipeCount(for: "garlic") == 2)
        #expect(sut.recipeCount(for: "onion") == 1)
        #expect(sut.recipeCount(for: "beef") == 0)
    }

    // MARK: - variations

    @Test("Variations are all ingredients containing the stem, sorted")
    func variationsContainStemSorted() {
        #expect(sut.variations(of: "Chicken") == ["Chicken Breast", "Chicken Thigh"])
    }

    // MARK: - categorizedIngredients filtering

    @Test("An empty category filter returns the full categorized list")
    func emptyFilterReturnsAll() {
        let all = sut.categorizedIngredients.map { $0.category }
        let filtered = sut.categorizedIngredients(filteredBy: []).map { $0.category }
        #expect(filtered == all)
    }

    @Test("Filtering by a category returns only that category")
    func filterByCategoryReturnsOnlyThatCategory() throws {
        let first = try #require(sut.categorizedIngredients.first?.category)
        let filtered = sut.categorizedIngredients(filteredBy: [first])
        #expect(filtered.count == 1)
        #expect(filtered.first?.category == first)
    }
}
