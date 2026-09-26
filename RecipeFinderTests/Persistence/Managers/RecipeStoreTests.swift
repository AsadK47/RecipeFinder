import Testing
import Foundation
@testable import RecipeFinder

/// Unit tests for `RecipeStore`'s in-memory library semantics (upsert on save,
/// append on add, remove on delete, reload on refresh) against an in-memory
/// persistence controller.
@MainActor
@Suite("RecipeStore")
struct RecipeStoreTests {

    private func makeStore() -> RecipeStore {
        RecipeStore(persistence: PersistenceController(inMemory: true, userID: { "test-user" }))
    }

    private func makeRecipe(id: UUID = UUID(), name: String = "Test", rating: Int = 0) -> RecipeModel {
        RecipeModel(
            id: id,
            name: name,
            category: "Main",
            difficulty: "Basic",
            prepTime: "10 minutes",
            cookingTime: "20 minutes",
            baseServings: 2,
            ingredients: [Ingredient(baseQuantity: 1, unit: "cup", name: "rice")],
            prePrepInstructions: [],
            instructions: ["Cook it"],
            notes: "",
            rating: rating
        )
    }

    @Test("add persists and appends the recipe")
    func addAppends() {
        let store = makeStore()
        let recipe = makeRecipe()

        #expect(store.add(recipe) == true)
        #expect(store.recipes.count == 1)
        #expect(store.recipes.first?.id == recipe.id)
    }

    @Test("save upserts in place — no duplicate for the same id")
    func saveUpserts() {
        let store = makeStore()
        let recipe = makeRecipe(rating: 0)
        _ = store.add(recipe)

        var edited = recipe
        edited.rating = 5
        #expect(store.save(edited) == true)
        #expect(store.recipes.count == 1)
        #expect(store.recipes.first?.rating == 5)
    }

    @Test("delete removes the recipe by id")
    func deleteRemoves() {
        let store = makeStore()
        let recipe = makeRecipe()
        _ = store.add(recipe)

        store.delete(id: recipe.id)
        #expect(store.recipes.isEmpty)
    }

    @Test("refresh reloads the library from persistence")
    func refreshReloads() async {
        let store = makeStore()
        _ = store.add(makeRecipe(name: "Alpha"))
        store.recipes = []           // simulate a stale in-memory copy

        await store.refresh()
        #expect(store.recipes.contains { $0.name == "Alpha" })
    }
}
