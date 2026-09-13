import Testing
import Foundation
@testable import RecipeFinder

@Suite("SeedRecipeProvider")
struct SeedRecipeProviderTests {

    // MARK: - Count & completeness

    @Test("recipe count is exactly 6")
    func recipeCount() {
        #expect(SeedRecipeProvider.recipes.count == 6)
    }

    @Test("all recipes are marked isSampleRecipe", arguments: SeedRecipeProvider.recipes)
    func allMarkedSample(recipe: RecipeModel) {
        #expect(recipe.isSampleRecipe)
    }

    @Test("all recipes have a non-empty name", arguments: SeedRecipeProvider.recipes)
    func nonEmptyName(recipe: RecipeModel) {
        #expect(!recipe.name.isEmpty)
    }

    @Test("all recipes have at least one instruction", arguments: SeedRecipeProvider.recipes)
    func hasInstructions(recipe: RecipeModel) {
        #expect(!recipe.instructions.isEmpty)
    }

    @Test("all recipes have at least one ingredient", arguments: SeedRecipeProvider.recipes)
    func hasIngredients(recipe: RecipeModel) {
        #expect(!recipe.ingredients.isEmpty)
    }

    @Test("all recipes have a positive baseServings", arguments: SeedRecipeProvider.recipes)
    func positiveServings(recipe: RecipeModel) {
        #expect(recipe.baseServings > 0)
    }

    // MARK: - Stable UUIDs

    @Test("all UUIDs carry the 5EED0001 seed prefix", arguments: SeedRecipeProvider.recipes)
    func seedUUIDPrefix(recipe: RecipeModel) {
        #expect(recipe.id.uuidString.hasPrefix("5EED0001"))
    }

    @Test("all UUIDs are unique")
    func uniqueUUIDs() {
        let ids = SeedRecipeProvider.recipes.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("UUIDs are stable across successive accesses")
    func stableUUIDs() {
        let first  = SeedRecipeProvider.recipes.map(\.id)
        let second = SeedRecipeProvider.recipes.map(\.id)
        #expect(first == second)
    }

    // MARK: - Specific stable identifiers

    @Test("Spaghetti Bolognese UUID is fixed")
    func spaghettiUUID() {
        let expected = UUID(uuidString: "5EED0001-0000-0000-0000-000000000001")
        let actual = SeedRecipeProvider.recipes.first { $0.name == "Spaghetti Bolognese" }?.id
        #expect(actual == expected)
    }

    @Test("Greek Salad UUID is fixed")
    func greekSaladUUID() {
        let expected = UUID(uuidString: "5EED0001-0000-0000-0000-000000000006")
        let actual = SeedRecipeProvider.recipes.first { $0.name == "Greek Salad" }?.id
        #expect(actual == expected)
    }
}
