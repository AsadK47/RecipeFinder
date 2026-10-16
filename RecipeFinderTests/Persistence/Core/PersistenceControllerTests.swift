import Testing
import Foundation
@testable import RecipeFinder

/// Integration on the real Core Data recipe stack, backed by an in-memory (`/dev/null`) store for isolation with an injected account scope so per-user isolation is exercised without global state.
@MainActor
@Suite struct PersistenceControllerTests {

    private func makeController(userID: @escaping () -> String?) -> PersistenceController {
        let controller = PersistenceController(inMemory: true, userID: userID)
        #expect(controller.isStoreLoaded)
        #expect(controller.loadError == nil)
        return controller
    }

    private func makeRecipe(name: String, id: UUID = UUID(), favorite: Bool = false) -> RecipeModel {
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
            prePrepInstructions: ["Rinse rice"],
            instructions: ["Boil", "Serve"],
            notes: "Weeknight staple",
            imageName: nil,
            isFavorite: favorite
        )
    }

    // MARK: - Store lifecycle (regression guard, migrated from XCTest)

    /// The store loads synchronously, so the shared controller must report ready
    /// the moment it exists — a deferred flag once left launch fetches empty.
    @Test func sharedStoreLoadsImmediately() {
        #expect(PersistenceController.shared.isStoreLoaded)
        #expect(PersistenceController.shared.loadError == nil)
    }

    // MARK: - Round trip

    @Test func saveThenFetch_returnsSameRecipe() {
        let controller = makeController(userID: { "userA" })
        let recipe = makeRecipe(name: "Rice Bowl", favorite: true)

        controller.saveRecipeModel(recipe)
        let fetched = controller.fetchRecipes()

        #expect(fetched.count == 1)
        #expect(fetched.first?.id == recipe.id)
        #expect(fetched.first?.name == "Rice Bowl")
        // `Ingredient` capitalises its name on construction ("rice" → "Rice");
        // the store round-trips that faithfully rather than re-normalising.
        #expect(fetched.first?.ingredients.first?.name == "Rice")
        #expect(fetched.first?.prePrepInstructions == ["Rinse rice"])
        #expect(fetched.first?.instructions == ["Boil", "Serve"])
        #expect(fetched.first?.baseServings == 4)
        #expect(fetched.first?.notes == "Weeknight staple")
        #expect(fetched.first?.isFavorite == true)
    }

    // MARK: - Seeding

    @Test func seedRecipes_whenScoped_returnsTrueAndPersistsAll() async {
        let controller = makeController(userID: { "userA" })
        let models = [makeRecipe(name: "Seed One"), makeRecipe(name: "Seed Two")]

        let ok = await controller.seedRecipes(models)

        #expect(ok)
        #expect(controller.fetchRecipes().count == 2)
    }

    /// No user scope ⇒ the save can't be attributed, so seeding reports failure and writes nothing — this is the
    /// signal RecipeStore uses to clear its "seeded" flag and retry next launch rather than strand an empty library.
    @Test func seedRecipes_whenUnscoped_returnsFalseAndPersistsNothing() async {
        let controller = makeController(userID: { nil })

        let ok = await controller.seedRecipes([makeRecipe(name: "Seed One")])

        #expect(!ok)
        #expect(controller.fetchRecipes().isEmpty)
    }

    @Test func delete_removesOnlyThatRecipe() {
        let controller = makeController(userID: { "userA" })
        let keep = makeRecipe(name: "Keep")
        let drop = makeRecipe(name: "Drop")
        controller.saveRecipeModel(keep)
        controller.saveRecipeModel(drop)

        controller.deleteRecipe(withId: drop.id)

        #expect(controller.fetchRecipes().map(\.id) == [keep.id])
    }

    @Test func saveModelWithExistingId_updatesInPlace() {
        let controller = makeController(userID: { "userA" })
        let recipe = makeRecipe(name: "Original")
        controller.saveRecipeModel(recipe)

        controller.saveRecipeModel(makeRecipe(name: "Renamed", id: recipe.id))

        let fetched = controller.fetchRecipes()
        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Renamed")
    }

    @Test func toggleFavorite_flipsPersistedFlag() {
        let controller = makeController(userID: { "userA" })
        let recipe = makeRecipe(name: "Toggle", favorite: false)
        controller.saveRecipeModel(recipe)

        controller.toggleFavorite(withId: recipe.id)

        #expect(controller.fetchRecipes().first?.isFavorite == true)
    }

    // MARK: - Per-user scope

    @Test func recipesAreIsolatedPerUser() {
        var currentUser = "userA"
        let controller = makeController(userID: { currentUser })

        let a = makeRecipe(name: "A only")
        controller.saveRecipeModel(a)

        currentUser = "userB"
        let b = makeRecipe(name: "B only")
        controller.saveRecipeModel(b)

        #expect(controller.fetchRecipes().map(\.id) == [b.id])

        currentUser = "userA"
        #expect(controller.fetchRecipes().map(\.id) == [a.id])
    }

    @Test func withoutScope_savesAreInvisible() {
        let controller = makeController(userID: { nil })
        controller.saveRecipeModel(makeRecipe(name: "Orphan"))
        #expect(controller.fetchRecipes().isEmpty)
    }
}
