import Testing
import Foundation
@testable import RecipeFinder

/// The recipe write API must report success/failure so the UI can surface a
/// failed save instead of silently losing a just-imported recipe.
@MainActor
@Suite struct RecipeSaveResultTests {

    private func makeRecipe(name: String, id: UUID = UUID()) -> RecipeModel {
        RecipeModel(
            id: id,
            name: name,
            category: "Main",
            difficulty: "Easy",
            prepTime: "10 minutes",
            cookingTime: "20 minutes",
            baseServings: 4,
            currentServings: 4,
            ingredients: [Ingredient(baseQuantity: 1, unit: "cup", name: "rice")],
            prePrepInstructions: [],
            instructions: ["Boil"],
            notes: "",
            imageName: nil,
            isFavorite: false
        )
    }

    @Test func saveRecipeModel_onReadyStore_returnsTrueAndPersists() {
        let controller = PersistenceController(inMemory: true, userID: { "u" })
        #expect(controller.isStoreLoaded)

        let recipe = makeRecipe(name: "Soup")
        #expect(controller.saveRecipeModel(recipe) == true)
        #expect(controller.fetchRecipes().contains { $0.id == recipe.id })
    }

    @Test func updateRecipe_whenRecipeMissing_returnsFalse() {
        let controller = PersistenceController(inMemory: true, userID: { "u" })
        #expect(controller.isStoreLoaded)
        // No matching recipe in the store → nothing to update.
        #expect(controller.updateRecipe(makeRecipe(name: "Ghost")) == false)
    }

    @Test func updateRecipe_existingRecipe_returnsTrue() {
        let controller = PersistenceController(inMemory: true, userID: { "u" })
        let recipe = makeRecipe(name: "Stew")
        #expect(controller.saveRecipeModel(recipe) == true)

        let edited = makeRecipe(name: "Beef Stew", id: recipe.id)
        #expect(controller.updateRecipe(edited) == true)
        #expect(controller.fetchRecipes().first { $0.id == recipe.id }?.name == "Beef Stew")
    }
}
