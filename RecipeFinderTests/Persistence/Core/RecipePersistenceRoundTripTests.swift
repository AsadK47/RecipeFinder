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
        tags: [String] = [],
        cookCount: Int = 0,
        lastCookedAt: Date? = nil,
        rating: Int = 0,
        cuisine: String? = nil,
        photoNames: [String] = []
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
            tags: tags,
            cookCount: cookCount,
            lastCookedAt: lastCookedAt,
            rating: rating,
            cuisine: cuisine,
            photoNames: photoNames
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

    // MARK: - Servings

    @Test("baseServings round-trips through the store")
    func saveRecipeModel_persistsBaseServings() {
        let store = makeStore()
        let recipe = makeRecipe()   // baseServings: 2 in helper
        #expect(store.saveRecipeModel(recipe) == true)

        let fetched = store.fetchRecipes().first { $0.id == recipe.id }
        #expect(fetched?.baseServings == 2)
    }

    @Test("currentServings persists when it differs from baseServings")
    func saveRecipeModel_persistsCurrentServings_whenDifferentFromBase() {
        let store = makeStore()
        let recipe = RecipeModel(
            id: UUID(),
            name: "Serving Test",
            category: "Main",
            difficulty: "Basic",
            prepTime: "5 minutes",
            cookingTime: "10 minutes",
            baseServings: 4,
            currentServings: 8,
            ingredients: [],
            prePrepInstructions: [],
            instructions: ["Cook"],
            notes: "",
            isFavorite: false
        )
        #expect(store.saveRecipeModel(recipe) == true)

        let fetched = store.fetchRecipes().first { $0.id == recipe.id }
        #expect(fetched?.baseServings == 4)
        #expect(fetched?.currentServings == 8)
        #expect(fetched?.scaleFactor == 2.0)
    }

    @Test("updateRecipe overwrites baseServings and currentServings")
    func updateRecipe_updatesServings() {
        let store = makeStore()
        let id = UUID()
        let original = RecipeModel(
            id: id,
            name: "Servings Update Test",
            category: "Main",
            difficulty: "Basic",
            prepTime: "5 minutes",
            cookingTime: "10 minutes",
            baseServings: 2,
            currentServings: 2,
            ingredients: [Ingredient(baseQuantity: 1, unit: "cup", name: "rice")],
            prePrepInstructions: [],
            instructions: ["Cook"],
            notes: "",
            isFavorite: false
        )
        #expect(store.saveRecipeModel(original) == true)

        let updated = RecipeModel(
            id: id,
            name: "Servings Update Test",
            category: "Main",
            difficulty: "Basic",
            prepTime: "5 minutes",
            cookingTime: "10 minutes",
            baseServings: 6,
            currentServings: 3,
            ingredients: [Ingredient(baseQuantity: 1, unit: "cup", name: "rice")],
            prePrepInstructions: [],
            instructions: ["Cook"],
            notes: "",
            isFavorite: false
        )
        #expect(store.updateRecipe(updated) == true)

        let fetched = store.fetchRecipes().first { $0.id == id }
        #expect(fetched?.baseServings == 6)
        #expect(fetched?.currentServings == 3)
    }

    // MARK: - Cook history, rating, cuisine, photos

    @Test("cookCount round-trips through the store")
    func saveRecipeModel_persistsCookCount() {
        let store = makeStore()
        let recipe = makeRecipe(cookCount: 5)
        #expect(store.saveRecipeModel(recipe) == true)

        let fetched = store.fetchRecipes().first { $0.id == recipe.id }
        #expect(fetched?.cookCount == 5)
    }

    @Test("lastCookedAt round-trips through the store")
    func saveRecipeModel_persistsLastCookedAt() {
        let store = makeStore()
        let cookedAt = Date(timeIntervalSinceNow: -3600)
        let recipe = makeRecipe(lastCookedAt: cookedAt)
        #expect(store.saveRecipeModel(recipe) == true)

        let fetched = store.fetchRecipes().first { $0.id == recipe.id }
        let diff = abs((fetched?.lastCookedAt ?? .distantPast).timeIntervalSince(cookedAt))
        #expect(diff < 1.0)
    }

    @Test("rating round-trips through the store")
    func saveRecipeModel_persistsRating() {
        let store = makeStore()
        let recipe = makeRecipe(rating: 4)
        #expect(store.saveRecipeModel(recipe) == true)

        let fetched = store.fetchRecipes().first { $0.id == recipe.id }
        #expect(fetched?.rating == 4)
    }

    @Test("cuisine round-trips through the store")
    func saveRecipeModel_persistsCuisine() {
        let store = makeStore()
        let recipe = makeRecipe(cuisine: "Italian")
        #expect(store.saveRecipeModel(recipe) == true)

        let fetched = store.fetchRecipes().first { $0.id == recipe.id }
        #expect(fetched?.cuisine == "Italian")
    }

    @Test("photoNames round-trips through the store")
    func saveRecipeModel_persistsPhotoNames() {
        let store = makeStore()
        let recipe = makeRecipe(photoNames: ["photo1.jpg", "photo2.jpg", "photo3.jpg"])
        #expect(store.saveRecipeModel(recipe) == true)

        let fetched = store.fetchRecipes().first { $0.id == recipe.id }
        #expect(fetched?.photoNames == ["photo1.jpg", "photo2.jpg", "photo3.jpg"])
    }

    @Test("updateRecipe does not reset cook history")
    func updateRecipe_preservesCookHistory() {
        let store = makeStore()
        let id = UUID()
        #expect(store.saveRecipeModel(makeRecipe(id: id, cookCount: 3)) == true)

        #expect(store.updateRecipe(makeRecipe(id: id, name: "Updated Name")) == true)

        let fetched = store.fetchRecipes().first { $0.id == id }
        #expect(fetched?.cookCount == 3)
    }

    @Test("updateRecipe overwrites cuisine and rating")
    func updateRecipe_updatesCuisineAndRating() {
        let store = makeStore()
        let id = UUID()
        #expect(store.saveRecipeModel(makeRecipe(id: id, rating: 3, cuisine: "French")) == true)

        #expect(store.updateRecipe(makeRecipe(id: id, rating: 5, cuisine: "Italian")) == true)

        let fetched = store.fetchRecipes().first { $0.id == id }
        #expect(fetched?.cuisine == "Italian")
        #expect(fetched?.rating == 5)
    }
}
