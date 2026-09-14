import Testing
import Foundation
@testable import RecipeFinder

/// Integration: verifies that `PersistenceController`'s write operations
/// (toggle-favourite, delete, notes, tags) survive the save→fetch round-trip.
/// Each test uses an in-memory store so nothing crosses between runs.
@MainActor
@Suite("Recipe persistence round-trip")
struct RecipePersistenceRoundTripTests {

    private func makeStore() -> PersistenceController {
        PersistenceController(inMemory: true, userID: { "test-user" })
    }

    private func makeRecipe(
        id: UUID = UUID(),
        name: String = "Test Recipe",
        notes: String = "",
        isFavorite: Bool = false,
        tags: [String] = []
    ) -> RecipeModel {
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
            notes: notes,
            isFavorite: isFavorite,
            tags: tags
        )
    }

    // MARK: - Favourites

    @Test("toggleFavorite flips the stored flag and persists across fetch")
    func toggleFavorite_persistsNewState() {
        let store = makeStore()
        let recipe = makeRecipe(isFavorite: false)
        #expect(store.saveRecipeModel(recipe) == true)

        store.toggleFavorite(withId: recipe.id)

        let fetched = store.fetchRecipes().first { $0.id == recipe.id }
        #expect(fetched?.isFavorite == true)
    }

    @Test("toggleFavorite twice restores the original flag")
    func toggleFavorite_doubletoggle_restoresOriginal() {
        let store = makeStore()
        let recipe = makeRecipe(isFavorite: false)
        #expect(store.saveRecipeModel(recipe) == true)

        store.toggleFavorite(withId: recipe.id)
        store.toggleFavorite(withId: recipe.id)

        let fetched = store.fetchRecipes().first { $0.id == recipe.id }
        #expect(fetched?.isFavorite == false)
    }

    @Test("toggleFavorite with an unknown id does not crash and leaves store unchanged")
    func toggleFavorite_missingId_isNoOp() {
        let store = makeStore()
        #expect(store.saveRecipeModel(makeRecipe()) == true)

        store.toggleFavorite(withId: UUID())

        #expect(store.fetchRecipes().count == 1)
    }

    // MARK: - Delete

    @Test("deleteRecipe removes the recipe from subsequent fetches")
    func deleteRecipe_removesFromFetch() {
        let store = makeStore()
        let recipe = makeRecipe()
        #expect(store.saveRecipeModel(recipe) == true)
        #expect(store.fetchRecipes().contains { $0.id == recipe.id })

        store.deleteRecipe(withId: recipe.id)

        #expect(!store.fetchRecipes().contains { $0.id == recipe.id })
    }

    @Test("deleteRecipe with an unknown id is a no-op")
    func deleteRecipe_missingId_isNoOp() {
        let store = makeStore()
        #expect(store.saveRecipeModel(makeRecipe()) == true)

        store.deleteRecipe(withId: UUID())

        #expect(store.fetchRecipes().count == 1)
    }

    @Test("deleteRecipe leaves other recipes untouched")
    func deleteRecipe_leavesOthersIntact() {
        let store = makeStore()
        let keep = makeRecipe(name: "Keep")
        let remove = makeRecipe(name: "Remove")
        #expect(store.saveRecipeModel(keep) == true)
        #expect(store.saveRecipeModel(remove) == true)

        store.deleteRecipe(withId: remove.id)

        let remaining = store.fetchRecipes()
        #expect(remaining.contains { $0.id == keep.id })
        #expect(!remaining.contains { $0.id == remove.id })
    }

    // MARK: - Notes

    @Test("saveRecipeModel persists the notes field")
    func saveRecipeModel_persistsNotes() {
        let store = makeStore()
        let recipe = makeRecipe(notes: "Serve with crusty bread")
        #expect(store.saveRecipeModel(recipe) == true)

        let fetched = store.fetchRecipes().first { $0.id == recipe.id }
        #expect(fetched?.notes == "Serve with crusty bread")
    }

    @Test("updateRecipe overwrites the notes field")
    func updateRecipe_updatesNotes() {
        let store = makeStore()
        let id = UUID()
        #expect(store.saveRecipeModel(makeRecipe(id: id, notes: "Original")) == true)

        #expect(store.updateRecipe(makeRecipe(id: id, notes: "Updated")) == true)

        let fetched = store.fetchRecipes().first { $0.id == id }
        #expect(fetched?.notes == "Updated")
    }

    // MARK: - Tags

    @Test("saveRecipeModel persists tags")
    func saveRecipeModel_persistsTags() {
        let store = makeStore()
        let recipe = makeRecipe(tags: ["spicy", "quick", "family"])
        #expect(store.saveRecipeModel(recipe) == true)

        let fetched = store.fetchRecipes().first { $0.id == recipe.id }
        #expect(Set(fetched?.tags ?? []) == ["spicy", "quick", "family"])
    }

    @Test("updateRecipe overwrites the tags field")
    func updateRecipe_updatesTags() {
        let store = makeStore()
        let id = UUID()
        #expect(store.saveRecipeModel(makeRecipe(id: id, tags: ["old-tag"])) == true)

        #expect(store.updateRecipe(makeRecipe(id: id, tags: ["new-tag", "quick"])) == true)

        let fetched = store.fetchRecipes().first { $0.id == id }
        #expect(Set(fetched?.tags ?? []) == ["new-tag", "quick"])
    }

    @Test("recipe with empty tags round-trips to empty tags")
    func saveRecipeModel_emptyTags_roundTrips() {
        let store = makeStore()
        let recipe = makeRecipe(tags: [])
        #expect(store.saveRecipeModel(recipe) == true)

        let fetched = store.fetchRecipes().first { $0.id == recipe.id }
        #expect(fetched?.tags.isEmpty == true)
    }
}
