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
        #expect(RecipeLibraryFacets(recipes: recipes).cuisines == ["Italian", "Thai"])
    }

    /// The filter sheet lists difficulty easiest first, the same list the recipe editor offers.
    @Test func difficultiesMatchTheEditorEasiestFirst() {
        #expect(RecipeLibraryFacets.difficulties == ["Basic", "Intermediate", "Expert"])
        #expect(RecipeLibraryFacets.difficulties == RecipeWizardBuilder.difficultyLevels)
    }

    /// Active filter chips list chosen difficulties easiest first, whatever order the set holds them in.
    @Test func chosenDifficultiesRunEasiestFirst() {
        #expect(RecipeLibraryFacets.orderedDifficulties(["Expert", "Basic", "Intermediate"]) == ["Basic", "Intermediate", "Expert"])
        #expect(RecipeLibraryFacets.orderedDifficulties(["Expert", "Basic"]) == ["Basic", "Expert"])
    }

    /// A difficulty the editor doesn't offer still gets a chip, after the known ones, so it can be removed.
    @Test func unknownChosenDifficultiesFollowSorted() {
        #expect(RecipeLibraryFacets.orderedDifficulties(["hard", "Basic", "Easy"]) == ["Basic", "Easy", "hard"])
    }

    @Test func noChosenDifficultiesGiveNoChips() {
        #expect(RecipeLibraryFacets.orderedDifficulties([]).isEmpty)
    }
}
