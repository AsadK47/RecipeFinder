import Foundation

/// The filter sheet's choices for the cook's library: courses, tags and cuisines that actually occur in it.
struct RecipeLibraryFacets: Equatable {
    /// Courses the filter sheet offers; anything else a recipe's category says (e.g. an import's "Dinner") is left out.
    static let knownCategories: Set<String> = ["Breakfast", "Dessert", "Drink", "Main", "Side", "Soup", "Starter"]
    /// The filter sheet's difficulty choices: the editor's levels, easiest first.
    static let difficulties = RecipeWizardBuilder.difficultyLevels

    /// The chosen difficulties easiest first (the editor's order), then any others alphabetically.
    static func orderedDifficulties(_ chosen: Set<String>) -> [String] {
        difficulties.filter(chosen.contains) + chosen.subtracting(difficulties).sorted()
    }

    var categories: [String] = []
    var tags: [String] = []
    var cuisines: [String] = []

    init() {}

    init(recipes: [RecipeModel]) {
        categories = Set(recipes.map(\.category)).intersection(Self.knownCategories).sorted()
        tags = Set(recipes.flatMap(\.tags)).sorted()
        cuisines = RecipeFilterCriteria.distinctCuisines(in: recipes)
    }
}
