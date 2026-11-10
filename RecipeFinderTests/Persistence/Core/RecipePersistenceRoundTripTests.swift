import Testing
import Foundation
@testable import RecipeFinder

/// Integration: `PersistenceController` writes (toggle-favourite, delete, notes, tags) survive the save→fetch round-trip, each on an isolated in-memory store.
@MainActor
@Suite("Recipe persistence round-trip")
struct RecipePersistenceRoundTripTests {

    private func makeStore() -> PersistenceController {
        PersistenceController(inMemory: true)
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

    // MARK: - Single-recipe re-read (detail screen)

    @Test("fetchRecipe(withId:) returns the persisted recipe by id")
    func fetchRecipe_returnsPersistedRecipe() {
        let store = makeStore()
        let recipe = makeRecipe(name: "Ramen")
        #expect(store.saveRecipeModel(recipe) == true)

        #expect(store.fetchRecipe(withId: recipe.id)?.name == "Ramen")
    }

    @Test("fetchRecipe(withId:) reflects a photo added after the first save")
    func fetchRecipe_reflectsLaterPhotoEdit() {
        // Mirrors the post-cook-photo bug: a recipe is saved, then a photo is
        // persisted via update, and the detail screen re-reads the single recipe.
        let store = makeStore()
        let id = UUID()
        #expect(store.saveRecipeModel(makeRecipe(id: id)) == true)

        #expect(store.updateRecipe(makeRecipe(id: id, photoNames: ["cook.jpg"])) == true)

        #expect(store.fetchRecipe(withId: id)?.photoNames == ["cook.jpg"])
    }

    @Test("fetchRecipe(withId:) returns nil for an unknown id")
    func fetchRecipe_unknownId_returnsNil() {
        let store = makeStore()
        #expect(store.saveRecipeModel(makeRecipe()) == true)

        #expect(store.fetchRecipe(withId: UUID()) == nil)
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

    // MARK: - recordCook

    @Test("recordCook increments cookCount by one")
    func recordCook_incrementsCookCount() async {
        let store = makeStore()
        let recipe = makeRecipe(cookCount: 2)
        #expect(store.saveRecipeModel(recipe) == true)

        await store.recordCook(withId: recipe.id)

        let fetched = store.fetchRecipes().first { $0.id == recipe.id }
        #expect(fetched?.cookCount == 3)
    }

    @Test("recordCook updates lastCookedAt to approximately now")
    func recordCook_updatesLastCookedAt() async {
        let store = makeStore()
        let before = Date()
        let recipe = makeRecipe()
        #expect(store.saveRecipeModel(recipe) == true)

        await store.recordCook(withId: recipe.id)

        let after = Date()
        let fetched = store.fetchRecipes().first { $0.id == recipe.id }
        if let cookedAt = fetched?.lastCookedAt {
            #expect(cookedAt >= before)
            #expect(cookedAt <= after)
        } else {
            Issue.record("lastCookedAt should not be nil after recordCook")
        }
    }

    @Test("recordCook with an unknown id is a no-op")
    func recordCook_unknownId_isNoOp() async {
        let store = makeStore()
        let recipe = makeRecipe(cookCount: 0)
        #expect(store.saveRecipeModel(recipe) == true)

        await store.recordCook(withId: UUID())

        let fetched = store.fetchRecipes().first { $0.id == recipe.id }
        #expect(fetched?.cookCount == 0)
    }

    @Test("recordCook called twice increments cookCount by two")
    func recordCook_calledTwice_incrementsByTwo() async {
        let store = makeStore()
        let recipe = makeRecipe(cookCount: 0)
        #expect(store.saveRecipeModel(recipe) == true)

        await store.recordCook(withId: recipe.id)
        await store.recordCook(withId: recipe.id)

        let fetched = store.fetchRecipes().first { $0.id == recipe.id }
        #expect(fetched?.cookCount == 2)
    }

    // MARK: - updateRating

    @Test("updateRating persists the new rating")
    func updateRating_persistsNewRating() async {
        let store = makeStore()
        let recipe = makeRecipe(rating: 0)
        #expect(store.saveRecipeModel(recipe) == true)

        await store.updateRating(withId: recipe.id, rating: 4)

        let fetched = store.fetchRecipes().first { $0.id == recipe.id }
        #expect(fetched?.rating == 4)
    }

    @Test("updateRating with an unknown id is a no-op")
    func updateRating_unknownId_isNoOp() async {
        let store = makeStore()
        let recipe = makeRecipe(rating: 3)
        #expect(store.saveRecipeModel(recipe) == true)

        await store.updateRating(withId: UUID(), rating: 5)

        let fetched = store.fetchRecipes().first { $0.id == recipe.id }
        #expect(fetched?.rating == 3)
    }

    @Test("updateRating to zero clears the rating")
    func updateRating_toZero_clearsRating() async {
        let store = makeStore()
        let recipe = makeRecipe(rating: 5)
        #expect(store.saveRecipeModel(recipe) == true)

        await store.updateRating(withId: recipe.id, rating: 0)

        let fetched = store.fetchRecipes().first { $0.id == recipe.id }
        #expect(fetched?.rating == 0)
    }

    @Test("batch background update rewrites content, keeps cook history, skips missing ids")
    func updateRecipesInBackground_rewritesContentKeepsHistory() async {
        let store = makeStore()
        let a = UUID(), b = UUID()
        #expect(store.saveRecipeModel(makeRecipe(id: a, name: "Old A", cookCount: 2)) == true)
        #expect(store.saveRecipeModel(makeRecipe(id: b, name: "Old B")) == true)

        let ok = await store.updateRecipesInBackground([
            makeRecipe(id: a, name: "New A"), makeRecipe(id: b, name: "New B"), makeRecipe(id: UUID(), name: "Ghost")
        ])

        let fetched = store.fetchRecipes()
        #expect(ok)
        #expect(fetched.count == 2)
        #expect(fetched.first { $0.id == a }?.name == "New A")
        #expect(fetched.first { $0.id == a }?.cookCount == 2)
        #expect(fetched.first { $0.id == b }?.name == "New B")
    }
}
