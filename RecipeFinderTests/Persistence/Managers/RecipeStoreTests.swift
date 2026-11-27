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

    // MARK: - Launch refresh of stale samples

    private static let refreshKey = "bundledSampleRefreshVersion"

    private func storedOldGreekSalad(in persistence: PersistenceController) async throws -> [RecipeModel] {
        var old = try #require(SeedRecipeProvider.shippedVersions.first { $0.name == "Greek Salad" })
        old.isFavorite = true
        #expect(old.dietaryInfo.isGlutenFree)
        #expect(await persistence.seedRecipes([old]))
        return await persistence.fetchRecipesAsync()
    }

    @Test("the launch refresh rewrites an untouched old starter copy and saves it")
    func launchRefreshReachesStarters() async throws {
        let persistence = PersistenceController(inMemory: true)
        let library = try await storedOldGreekSalad(in: persistence)
        let storage = LocalStore(userDefaults: try #require(UserDefaults(suiteName: UUID().uuidString)))

        let refreshed = await RecipeStore(persistence: persistence)
            .refreshStaleSamples(in: library, storage: storage)

        // Regression guard: wiring the refresh to the bundled recipes alone skips every starter fix. Uses the real
        // bundle loader (the default) so a broken default fails here too; the library holds only the salad.
        #expect(refreshed.first?.dietaryInfo.isGlutenFree == false)
        #expect(refreshed.first?.isFavorite == true)
        #expect(await persistence.fetchRecipesAsync().first?.dietaryInfo.isGlutenFree == false)
        #expect(storage.integer(forKey: Self.refreshKey) == BundledRecipeCatalog.sampleRefreshVersion)
    }

    @Test("a starter rated on another device during the refresh keeps the rating, and the refresh retries next launch")
    func launchRefreshKeepsChangesSyncedInMeanwhile() async throws {
        let persistence = PersistenceController(inMemory: true)
        let library = try await storedOldGreekSalad(in: persistence)
        let storage = LocalStore(userDefaults: try #require(UserDefaults(suiteName: UUID().uuidString)))
        // The snapshot says untouched; the store now holds a copy synced in from iCloud after it was read.
        var synced = try #require(library.first)
        synced.rating = 5
        synced.isFavorite = false
        #expect(persistence.updateRecipe(synced))

        let refreshed = await RecipeStore(persistence: persistence)
            .refreshStaleSamples(in: library, storage: storage)

        let stored = try #require(await persistence.fetchRecipesAsync().first)
        #expect(stored.rating == 5)
        #expect(stored.isFavorite == false)
        #expect(stored.dietaryInfo.isGlutenFree == true)
        #expect(refreshed.first?.dietaryInfo.isGlutenFree == true)
        // The list shows the synced copy, not the snapshot, so a later save can't write the old rating back.
        #expect(refreshed.first?.rating == 5)
        #expect(storage.integer(forKey: Self.refreshKey) == 0)

        // Next launch reads the synced copy, which is still an untouched old version: refreshed, rating kept.
        let again = await RecipeStore(persistence: persistence)
            .refreshStaleSamples(in: await persistence.fetchRecipesAsync(), storage: storage)
        #expect(again.first?.dietaryInfo.isGlutenFree == false)
        #expect(again.first?.rating == 5)
        #expect(await persistence.fetchRecipesAsync().first?.rating == 5)
        #expect(storage.integer(forKey: Self.refreshKey) == BundledRecipeCatalog.sampleRefreshVersion)
    }

    @Test("one starter changed during the refresh leaves the version unmarked while the other is still refreshed")
    func launchRefreshRetriesAfterAPartialSkip() async throws {
        let persistence = PersistenceController(inMemory: true)
        let salad = try #require(SeedRecipeProvider.shippedVersions.first { $0.name == "Greek Salad" })
        let toast = try #require(SeedRecipeProvider.shippedVersions.first { $0.name == "Avocado Toast" })
        #expect(await persistence.seedRecipes([salad, toast]))
        let library = await persistence.fetchRecipesAsync()
        let storage = LocalStore(userDefaults: try #require(UserDefaults(suiteName: UUID().uuidString)))
        var synced = try #require(library.first { $0.id == toast.id })
        synced.rating = 4
        #expect(persistence.updateRecipe(synced))

        let refreshed = await RecipeStore(persistence: persistence)
            .refreshStaleSamples(in: library, storage: storage)

        #expect(refreshed.first { $0.id == salad.id }?.dietaryInfo.isGlutenFree == false)
        #expect(refreshed.first { $0.id == toast.id }?.dietaryInfo.isVegan == true)
        #expect(refreshed.first { $0.id == toast.id }?.rating == 4)
        #expect(storage.integer(forKey: Self.refreshKey) == 0)

        let again = await RecipeStore(persistence: persistence)
            .refreshStaleSamples(in: await persistence.fetchRecipesAsync(), storage: storage)
        #expect(again.first { $0.id == toast.id }?.dietaryInfo.isVegan == false)
        #expect(again.first { $0.id == toast.id }?.rating == 4)
        #expect(storage.integer(forKey: Self.refreshKey) == BundledRecipeCatalog.sampleRefreshVersion)
    }

    @Test("missing bundle data leaves the starter copy as it was and the refresh unmarked")
    func launchRefreshWaitsForBundleData() async throws {
        let persistence = PersistenceController(inMemory: true)
        let library = try await storedOldGreekSalad(in: persistence)
        let storage = LocalStore(userDefaults: try #require(UserDefaults(suiteName: UUID().uuidString)))

        let refreshed = await RecipeStore(persistence: persistence)
            .refreshStaleSamples(in: library, storage: storage, bundle: { ([], []) })

        #expect(refreshed.first?.dietaryInfo.isGlutenFree == true)
        #expect(await persistence.fetchRecipesAsync().first?.dietaryInfo.isGlutenFree == true)
        #expect(storage.integer(forKey: Self.refreshKey) == 0)
    }

    @Test("a refresh version already done doesn't run again")
    func launchRefreshRunsOncePerVersion() async throws {
        let persistence = PersistenceController(inMemory: true)
        let library = try await storedOldGreekSalad(in: persistence)
        let storage = LocalStore(userDefaults: try #require(UserDefaults(suiteName: UUID().uuidString)))
        storage.set(BundledRecipeCatalog.sampleRefreshVersion, forKey: Self.refreshKey)

        let refreshed = await RecipeStore(persistence: persistence)
            .refreshStaleSamples(in: library, storage: storage)

        #expect(refreshed.first?.dietaryInfo.isGlutenFree == true)
        #expect(await persistence.fetchRecipesAsync().first?.dietaryInfo.isGlutenFree == true)
    }

    // MARK: - Seeding vs the store file

    private static let startersKey = "seedRecipesLoaded"
    private static let bundledKey = "bundledRecipesSeeded_v1"
    private static let seededFileKey = "seededStoreFileID"

    private func isolatedStorage() throws -> LocalStore {
        LocalStore(userDefaults: try #require(UserDefaults(suiteName: UUID().uuidString)))
    }

    @Test("a brand-new library seeds the starters and the bundled recipes")
    func firstLaunchSeeds() async throws {
        let persistence = PersistenceController(inMemory: true)
        let storage = try isolatedStorage()
        let extra = makeRecipe(name: "Bundled Dal")

        let seeded = await RecipeStore(persistence: persistence)
            .seedIfNeeded(existing: [], storage: storage, bundled: { [extra] })

        #expect(seeded?.count == SeedRecipeProvider.recipes.count + 1)
        #expect(storage.bool(forKey: Self.startersKey))
        #expect(storage.bool(forKey: Self.bundledKey))
    }

    @Test("the same store file isn't seeded twice")
    func sameFileSeedsOnce() async throws {
        let persistence = PersistenceController(inMemory: true)
        let storage = try isolatedStorage()
        let store = RecipeStore(persistence: persistence)
        _ = await store.seedIfNeeded(existing: [], storage: storage, bundled: { [] })

        // The cook deleted every recipe: an empty library on the same file stays empty.
        let again = await store.seedIfNeeded(existing: [], storage: storage, bundled: { [] })

        #expect(again == nil)
    }

    @Test("after a store recovery opens a fresh file, the empty library is seeded again")
    func freshStoreFileSeedsAgain() async throws {
        let storage = try isolatedStorage()
        let extra = makeRecipe(name: "Bundled Dal")
        _ = await RecipeStore(persistence: PersistenceController(inMemory: true))
            .seedIfNeeded(existing: [], storage: storage, bundled: { [extra] })

        // `attemptStoreRecovery` moved the unreadable file aside: a new, empty store with its own identifier.
        let recovered = PersistenceController(inMemory: true)
        let seeded = await RecipeStore(persistence: recovered)
            .seedIfNeeded(existing: [], storage: storage, bundled: { [extra] })

        #expect(seeded?.count == SeedRecipeProvider.recipes.count + 1)
        #expect(await recovered.fetchRecipesAsync().count == SeedRecipeProvider.recipes.count + 1)
        #expect(storage.string(forKey: Self.seededFileKey) == recovered.storeFileID)
    }

    @Test("an install seeded before the file was recorded adopts its open file and doesn't seed again")
    func legacyFlagsAdoptTheOpenFile() async throws {
        let persistence = PersistenceController(inMemory: true)
        let storage = try isolatedStorage()
        storage.set(true, forKey: Self.startersKey)
        storage.set(true, forKey: Self.bundledKey)
        let extra = makeRecipe(name: "Bundled Dal")

        // Bundled recipes the cook deleted on this file must not come back with the update.
        let seeded = await RecipeStore(persistence: persistence)
            .seedIfNeeded(existing: [], storage: storage, bundled: { [extra] })

        #expect(seeded == nil)
        #expect(await persistence.fetchRecipesAsync().isEmpty)
        #expect(persistence.storeFileID != nil)
        #expect(storage.string(forKey: Self.seededFileKey) == persistence.storeFileID)
    }

    @Test("relaunching on the same store file doesn't seed again")
    func relaunchOnTheSameFileSeedsOnce() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("RecipeModel.sqlite")
        let storage = try isolatedStorage()
        let first = PersistenceController(storeURL: storeURL)
        _ = await RecipeStore(persistence: first).seedIfNeeded(existing: [], storage: storage, bundled: { [] })
        let firstFile = try #require(first.storeFileID)

        // The cook deleted every recipe (`existing: []`); a relaunch opens the same file, which keeps its identifier.
        let relaunched = PersistenceController(storeURL: storeURL)
        let seeded = await RecipeStore(persistence: relaunched)
            .seedIfNeeded(existing: [], storage: storage, bundled: { [] })

        #expect(relaunched.storeFileID == firstFile)
        #expect(seeded == nil)
    }

    @Test("with iCloud sync on, a fresh store file waits for iCloud instead of seeding deleted recipes back")
    func freshSyncingFileDoesNotSeed() async throws {
        let storage = try isolatedStorage()
        let extra = makeRecipe(name: "Bundled Dal")
        _ = await RecipeStore(persistence: PersistenceController(inMemory: true))
            .seedIfNeeded(existing: [], storage: storage, bundled: { [extra] })

        // Seeded fixed ids would export as new records and bring back recipes the cook deleted on every device.
        let recovered = PersistenceController(inMemory: true)
        let seeded = await RecipeStore(persistence: recovered)
            .seedIfNeeded(existing: [], storage: storage, isSyncing: true, bundled: { [extra] })

        #expect(seeded == nil)
        #expect(await recovered.fetchRecipesAsync().isEmpty)
        #expect(storage.bool(forKey: Self.startersKey))
        #expect(storage.bool(forKey: Self.bundledKey))
    }
}
