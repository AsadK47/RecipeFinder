import Testing
import Foundation
@testable import RecipeFinder

/// Regression for the dietaryInfo and isSampleRecipe fields once absent from the schema — both were silently dropped on save, making dietary filters return 0 results after a restart.
@MainActor
@Suite("RecipeDietaryInfo persistence")
struct RecipeDietaryInfoPersistenceTests {

    private func makeRecipe(
        dietary: DietaryInfo,
        isSample: Bool = false
    ) -> RecipeModel {
        RecipeModel(
            name: "Test Recipe",
            category: "Main",
            difficulty: "Easy",
            prepTime: "5 min",
            cookingTime: "10 min",
            baseServings: 2,
            ingredients: [.init(baseQuantity: 1, unit: "cup", name: "flour")],
            prePrepInstructions: [],
            instructions: ["Step one."],
            notes: "",
            dietaryInfo: dietary,
            isSampleRecipe: isSample
        )
    }

    @Test("vegetarian flag survives a save/fetch round-trip")
    func vegetarianRoundTrip() throws {
        let store = PersistenceController(inMemory: true, userID: { "u1" })
        let recipe = makeRecipe(dietary: DietaryInfo(isVegetarian: true))
        store.saveRecipeModel(recipe)
        let loaded = try #require(store.fetchRecipes().first)
        #expect(loaded.dietaryInfo.isVegetarian == true)
        #expect(loaded.dietaryInfo.isVegan == false)
    }

    @Test("vegan flag survives a save/fetch round-trip")
    func veganRoundTrip() throws {
        let store = PersistenceController(inMemory: true, userID: { "u1" })
        let recipe = makeRecipe(dietary: DietaryInfo(isVegetarian: true, isVegan: true))
        store.saveRecipeModel(recipe)
        let loaded = try #require(store.fetchRecipes().first)
        #expect(loaded.dietaryInfo.isVegetarian == true)
        #expect(loaded.dietaryInfo.isVegan == true)
    }

    @Test("gluten-free flag survives a save/fetch round-trip")
    func glutenFreeRoundTrip() throws {
        let store = PersistenceController(inMemory: true, userID: { "u1" })
        let recipe = makeRecipe(dietary: DietaryInfo(isGlutenFree: true))
        store.saveRecipeModel(recipe)
        let loaded = try #require(store.fetchRecipes().first)
        #expect(loaded.dietaryInfo.isGlutenFree == true)
    }

    @Test("all dietary flags survive a save/fetch round-trip")
    func allFlagsRoundTrip() throws {
        let store = PersistenceController(inMemory: true, userID: { "u1" })
        let info = DietaryInfo(isVegetarian: true, isVegan: true, isGlutenFree: true, isDairyFree: true, isNutFree: true)
        let recipe = makeRecipe(dietary: info)
        store.saveRecipeModel(recipe)
        let loaded = try #require(store.fetchRecipes().first)
        #expect(loaded.dietaryInfo.isVegetarian)
        #expect(loaded.dietaryInfo.isVegan)
        #expect(loaded.dietaryInfo.isGlutenFree)
        #expect(loaded.dietaryInfo.isDairyFree)
        #expect(loaded.dietaryInfo.isNutFree)
    }

    @Test("recipe with no dietary flags loads with all-false DietaryInfo")
    func noDietaryFlagsDefaultsToAllFalse() throws {
        let store = PersistenceController(inMemory: true, userID: { "u1" })
        let recipe = makeRecipe(dietary: DietaryInfo())
        store.saveRecipeModel(recipe)
        let loaded = try #require(store.fetchRecipes().first)
        #expect(!loaded.dietaryInfo.isVegetarian)
        #expect(!loaded.dietaryInfo.isVegan)
        #expect(!loaded.dietaryInfo.isGlutenFree)
    }

    @Test("isSampleRecipe true survives a save/fetch round-trip")
    func isSampleRecipeRoundTrip() throws {
        let store = PersistenceController(inMemory: true, userID: { "u1" })
        let recipe = makeRecipe(dietary: DietaryInfo(), isSample: true)
        store.saveRecipeModel(recipe)
        let loaded = try #require(store.fetchRecipes().first)
        #expect(loaded.isSampleRecipe == true)
    }

    @Test("isSampleRecipe false is preserved (not coerced to true)")
    func isSampleRecipeFalsePreserved() throws {
        let store = PersistenceController(inMemory: true, userID: { "u1" })
        let recipe = makeRecipe(dietary: DietaryInfo(), isSample: false)
        store.saveRecipeModel(recipe)
        let loaded = try #require(store.fetchRecipes().first)
        #expect(loaded.isSampleRecipe == false)
    }

    @Test("dietaryInfo survives an update (not just a create)")
    func dietaryInfoSurvivesUpdate() throws {
        let store = PersistenceController(inMemory: true, userID: { "u1" })
        var recipe = makeRecipe(dietary: DietaryInfo())
        store.saveRecipeModel(recipe)

        recipe.dietaryInfo = DietaryInfo(isVegetarian: true, isGlutenFree: true)
        store.saveRecipeModel(recipe)

        let loaded = try #require(store.fetchRecipes().first)
        #expect(loaded.dietaryInfo.isVegetarian == true)
        #expect(loaded.dietaryInfo.isGlutenFree == true)
        #expect(loaded.dietaryInfo.isVegan == false)
    }
}
