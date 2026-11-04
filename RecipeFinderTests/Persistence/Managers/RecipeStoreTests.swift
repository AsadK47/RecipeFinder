import Testing
import Foundation
import UIKit
@testable import RecipeFinder

/// `RecipeStore`'s in-memory library semantics (upsert on save, append on add, remove on delete, reload on refresh) against an in-memory persistence controller.
@MainActor
@Suite("RecipeStore")
struct RecipeStoreTests {

    private func makeStore() -> RecipeStore {
        RecipeStore(persistence: PersistenceController(inMemory: true))
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

    @Test("delete removes owned hero and gallery image files (no orphaned files)")
    func deleteCleansUpImages() throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        let imageStore = RecipeImageStore(documentsDirectory: tmp)
        let store = RecipeStore(
            persistence: PersistenceController(inMemory: true),
            imageStore: imageStore
        )

        let id = UUID()
        let image = Self.tinyImage()
        let hero = try #require(imageStore.persist(image, recipeId: id))
        let gallery = imageStore.persistGallery([image], recipeId: id)
        #expect(gallery.count == 1)

        var recipe = makeRecipe(id: id)
        recipe.imageName = hero
        recipe.photoNames = gallery
        _ = store.add(recipe)

        #expect(FileManager.default.fileExists(atPath: tmp.appendingPathComponent(hero).path))

        store.delete(id: id)

        #expect(!FileManager.default.fileExists(atPath: tmp.appendingPathComponent(hero).path))
        #expect(!FileManager.default.fileExists(atPath: tmp.appendingPathComponent(gallery[0]).path))
    }

    private static func tinyImage() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2)).image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }
    }

    @Test("sync upserts an existing recipe in place, ignores unknown ids")
    func syncUpserts() {
        let store = makeStore()
        let recipe = makeRecipe(rating: 0)
        _ = store.add(recipe)

        var edited = recipe
        edited.rating = 4
        store.sync(edited)
        #expect(store.recipes.first?.rating == 4)

        store.sync(makeRecipe(name: "Unknown"))   // not in the library
        #expect(store.recipes.count == 1)
    }

    /// `load` fetches on a background Task; poll until it lands (bounded so a hang fails, not stalls).
    private func waitUntilLoaded(_ store: RecipeStore) async {
        for _ in 0..<200 where store.isLoading {
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    @Test("an added recipe survives a relaunch (fresh store, same database)")
    func addedRecipePersistsAcrossRelaunch() async {
        let persistence = PersistenceController(inMemory: true)
        let recipe = makeRecipe(name: "Toast")
        #expect(RecipeStore(persistence: persistence).add(recipe))

        let relaunched = RecipeStore(persistence: persistence)
        relaunched.load()
        await waitUntilLoaded(relaunched)

        // Regression: load once showed only in-memory seeds, hiding every saved recipe.
        #expect(relaunched.recipes.contains { $0.id == recipe.id })
    }

    @Test("collected-recipe count (badge input) excludes starter recipes")
    func collectedCountExcludesStarters() async {
        let persistence = PersistenceController(inMemory: true)
        #expect(await persistence.seedRecipes(SeedRecipeProvider.recipes))
        #expect(persistence.fetchCollectedRecipeCount() == 0)

        #expect(persistence.saveRecipeModel(makeRecipe(name: "Mine")))
        #expect(persistence.fetchCollectedRecipeCount() == 1)
        #expect(persistence.fetchRecipeCount() == SeedRecipeProvider.recipes.count + 1)
    }

    @Test("backup includes the library's recipes")
    func backupIncludesRecipes() {
        let persistence = PersistenceController(inMemory: true)
        #expect(persistence.saveRecipeModel(makeRecipe(name: "Toast")))

        let archive = BackupService(recipeStore: persistence).makeArchive()
        #expect(archive.recipes.map(\.name) == ["Toast"])
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
