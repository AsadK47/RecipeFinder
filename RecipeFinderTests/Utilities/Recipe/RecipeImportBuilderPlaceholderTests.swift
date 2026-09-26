import Testing
import Foundation
@testable import RecipeFinder

/// The import builder must not fabricate placeholder content — empty ingredients
/// stay empty so the import flow can surface the gap for review.
@Suite("RecipeImportBuilder placeholders")
struct RecipeImportBuilderPlaceholderTests {

    private func makeData(rawIngredients: [String], instructions: [String]) -> RecipeImporter.ExtractedRecipeData {
        RecipeImporter.ExtractedRecipeData(
            name: "Test",
            description: nil,
            matchedIngredients: [],
            rawIngredients: rawIngredients,
            rawText: "",
            instructions: instructions,
            sourceURL: URL(string: "https://example.com/recipe")!,
            cookTimeMinutes: nil,
            prepTimeMinutes: nil,
            servings: nil,
            difficulty: nil,
            category: nil,
            cuisine: nil,
            imageURL: nil
        )
    }

    @Test("no ingredients → empty, not a 'See recipe' placeholder")
    func noFabricatedIngredient() {
        let recipe = RecipeImportBuilder().build(from: makeData(rawIngredients: [], instructions: ["Cook."]))
        #expect(recipe.ingredients.isEmpty)
    }

    @Test("real ingredients pass through")
    func realIngredientsKept() {
        let recipe = RecipeImportBuilder().build(from: makeData(rawIngredients: ["1 onion"], instructions: ["Cook."]))
        #expect(recipe.ingredients.count == 1)
    }
}
