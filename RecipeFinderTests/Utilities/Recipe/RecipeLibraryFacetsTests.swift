import Testing
import Foundation
@testable import RecipeFinder

/// The filter sheet's courses, tags and cuisines, derived from the library.
@Suite struct RecipeLibraryFacetsTests {

    private static func recipe(_ category: String, tags: [String] = [], cuisine: String? = nil) -> RecipeModel {
        RecipeModel(
            name: category, category: category, difficulty: "Basic", prepTime: "5 min", cookingTime: "10 min",
            baseServings: 2, ingredients: [], prePrepInstructions: [], instructions: [], notes: "",
            tags: tags, cuisine: cuisine
        )
    }

    @Test func emptyLibraryHasNoChoices() {
        #expect(RecipeLibraryFacets(recipes: []) == RecipeLibraryFacets())
    }

    @Test func coursesAreKnownOnesSortedOnce() {
        let facets = RecipeLibraryFacets(recipes: [
            Self.recipe("Soup"), Self.recipe("Dinner"), Self.recipe("Breakfast"), Self.recipe("Soup"), Self.recipe("main")
        ])
        #expect(facets.categories == ["Breakfast", "Soup"])
    }

    @Test func tagsAreSortedOnce() {
        let facets = RecipeLibraryFacets(recipes: [
            Self.recipe("Main", tags: ["quick", "vegan"]), Self.recipe("Side", tags: ["quick", "Batch"])
        ])
        #expect(facets.tags == ["Batch", "quick", "vegan"])
    }

    @Test func cuisinesFollowTheFilterSpellingRules() {
        let recipes = [
            Self.recipe("Main", cuisine: "Italian"), Self.recipe("Main", cuisine: " italian "),
            Self.recipe("Main", cuisine: "Thai"), Self.recipe("Main")
        ]
        #expect(RecipeLibraryFacets(recipes: recipes).cuisines == RecipeFilterCriteria.distinctCuisines(in: recipes))
        #expect(RecipeLibraryFacets(recipes: recipes).cuisines.count == 2)
    }

    @Test func difficultiesKeepTheSheetOrder() {
        #expect(RecipeLibraryFacets.difficulties == ["Basic", "Expert", "Intermediate"])
    }
}
