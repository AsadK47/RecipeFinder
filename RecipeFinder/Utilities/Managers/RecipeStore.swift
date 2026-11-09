import SwiftUI

// Single source of truth for the recipe library; observing views update on any write, replacing manual onRecipeChange sync of value-type copies.
@MainActor
protocol RecipeStoring: AnyObject, Observable {
    var recipes: [RecipeModel] { get set }
    var isLoading: Bool { get }
    func load()
    func refresh() async
    @discardableResult func save(_ recipe: RecipeModel) -> Bool
    @discardableResult func add(_ recipe: RecipeModel) -> Bool
    func delete(id: UUID)
    func sync(_ recipe: RecipeModel)
}

private struct RecipeStoreKey: EnvironmentKey {
    // SwiftUI reads environment defaults on the main actor, so assumeIsolated is safe; the app shares one instance.
    static var defaultValue: any RecipeStoring {
        MainActor.assumeIsolated { RecipeStore.shared }
    }
}

extension EnvironmentValues {
    // Injected recipe store; defaults to shared singleton, override with `.environment(\.recipeStore, fake)` in tests/previews.
    var recipeStore: any RecipeStoring {
        get { self[RecipeStoreKey.self] }
        set { self[RecipeStoreKey.self] = newValue }
    }
}

@MainActor
@Observable
final class RecipeStore: RecipeStoring {
    static let shared = RecipeStore()

    /// Settable for ephemeral in-memory adds (e.g. quick snacks) that shouldn't touch Core Data.
    var recipes: [RecipeModel] = []
    private(set) var isLoading = true

    @ObservationIgnored private let persistence: PersistenceController
    @ObservationIgnored private let imageStore: RecipeImageStore
    /// Bumped on each load so a slow earlier fetch can't overwrite a newer one's result.
    @ObservationIgnored private var loadGeneration = 0

    init(persistence: PersistenceController = .shared, imageStore: RecipeImageStore = RecipeImageStore()) {
        self.persistence = persistence
        self.imageStore = imageStore
    }

    /// Loads the library, seeding starter + bundled recipes on first run.
    func load() {
        loadRecipes(retryAttempt: 0)
    }

    private func loadRecipes(retryAttempt: Int) {
        // Corrupted-store recovery reloads the store late, so retry — one early empty fetch shouldn't strand the user with a blank list.
        guard persistence.isStoreLoaded else {
            guard retryAttempt < 5 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.loadRecipes(retryAttempt: retryAttempt + 1)
            }
            return
        }

        // Fetch off the main thread so a large library doesn't freeze the UI.
        loadGeneration += 1
        let generation = loadGeneration
        Task {
            var fetched = await persistence.fetchRecipesAsync()
            if let seeded = await seedIfNeeded(existing: fetched) {
                fetched = seeded
            }
            #if DEBUG
            fetched = seedUITestReimportRecipeIfRequested(into: fetched)
            #endif
            // Ignore a stale fetch superseded by a newer load.
            guard generation == loadGeneration else { return }
            let deduped = removeDuplicateCopies(from: fetched)
            let repaired = await repairLegacySampleFlags(in: deduped)
            recipes = await refreshStaleSamples(in: repaired)
            isLoading = false
        }
    }

    /// One-time repair: older builds saved the bundled/starter samples without `isSampleRecipe`, so they counted
    /// as user-collected and unlocked every collection badge on the first cook. Re-flag copies matching a sample
    /// by name (never imported ones), then drop the collection badges that only those copies had earned.
    private func repairLegacySampleFlags(in library: [RecipeModel]) async -> [RecipeModel] {
        let key = "legacySampleFlagsRepaired_v1"
        guard !LocalStore.shared.bool(forKey: key) else { return library }
        LocalStore.shared.set(true, forKey: key)

        let bundled = await Task.detached(priority: .utility) { BundledRecipeCatalog.load() }.value
        let sampleNames = Set((bundled + SeedRecipeProvider.recipes).map { $0.name.nameKey })
        var repaired = library
        var fixedCount = 0
        for index in repaired.indices
        where !repaired[index].isSampleRecipe
            && repaired[index].importedFromURL == nil
            && sampleNames.contains(repaired[index].name.nameKey) {
            repaired[index].isSampleRecipe = true
            if persistence.updateRecipe(repaired[index]) { fixedCount += 1 }
        }
        let collected = repaired.filter { !$0.isSampleRecipe }.count
        BadgeManager.shared.revokeUnearnedCollectionBadges(collectedCount: collected)
        if fixedCount > 0 {
            Self.logger.info("Re-flagged \(fixedCount) legacy sample recipes; \(collected) user recipes remain")
        }
        return repaired
    }

    /// Versioned one-time pass: bundled samples are seeded once, so installs keep pre-curation copies (steps parsed
    /// as ingredients, etc.). Rewrites untouched ones with today's content; edited copies are never overwritten.
    private func refreshStaleSamples(in library: [RecipeModel]) async -> [RecipeModel] {
        let key = "bundledSampleRefreshVersion"
        guard BundledRecipeCatalog.needsSampleRefresh(lastRunVersion: LocalStore.shared.integer(forKey: key)) else {
            return library
        }
        let refreshes = await Task.detached(priority: .utility) {
            BundledRecipeCatalog.staleSampleRefreshes(
                library: library, current: BundledRecipeCatalog.load(), history: BundledRecipeCatalog.loadHistory()
            )
        }.value
        var updated = library
        var failures = 0
        for recipe in refreshes {
            guard persistence.updateRecipe(recipe) else { failures += 1; continue }
            if let index = updated.firstIndex(where: { $0.id == recipe.id }) { updated[index] = recipe }
        }
        // Retry next launch if any write failed; otherwise this version is done.
        if failures == 0 { LocalStore.shared.set(BundledRecipeCatalog.sampleRefreshVersion, forKey: key) }
        if !refreshes.isEmpty {
            Self.logger.info("Refreshed \(refreshes.count - failures) stale sample recipes (\(failures) failed)")
        }
        return updated
    }

    /// Deletes exact duplicate copies (see `BackupMerge.duplicateRecipeIDs`) and returns the cleaned library.
    /// Idempotent: a no-op once the store is clean. Goes straight to persistence rather than `delete(id:)` so
    /// image files shared with the kept copy are never removed.
    private func removeDuplicateCopies(from library: [RecipeModel]) -> [RecipeModel] {
        let duplicates = BackupMerge.duplicateRecipeIDs(in: library)
        guard !duplicates.isEmpty else { return library }
        for id in duplicates {
            persistence.deleteRecipe(withId: id)
        }
        Self.logger.info("Removed \(duplicates.count) duplicate recipe copies")
        return library.filter { !duplicates.contains($0.id) }
    }

    private static let logger = AppLogger.logger(category: "RecipeStore")

    #if DEBUG
    /// UI-test hook (`-seed-reimport-recipe`): one recipe that kept its original text, named to sort first, so the
    /// Screenshots workflow can capture the "Re-import from original" menu. Idempotent via a fixed id.
    private func seedUITestReimportRecipeIfRequested(into library: [RecipeModel]) -> [RecipeModel] {
        guard ProcessInfo.processInfo.arguments.contains("-seed-reimport-recipe"),
              let id = UUID(uuidString: "5EED0000-0000-4000-8000-00000000A001"),
              !library.contains(where: { $0.id == id }) else { return library }
        let original = "1-Pot Tomato Soup\nIngredients\n4 tomatoes\n1 onion\n500 ml stock\nMethod\nSoften the onion.\nAdd tomatoes and stock, simmer 20 minutes, blend."
        let recipe = RecipeModel(
            id: id, name: "1-Pot Tomato Soup", category: "Main", difficulty: "Basic",
            prepTime: "5 minutes", cookingTime: "25 minutes", baseServings: 2,
            ingredients: [Ingredient(baseQuantity: 4, unit: "", name: "tomatoes")],
            prePrepInstructions: [], instructions: ["Soften the onion."], notes: "",
            sourceText: original
        )
        guard persistence.saveRecipeModel(recipe) else { return library }
        return library + [recipe]
    }
    #endif

    /// One-time seeding: starters for an empty library, plus the bundled collection (once, even for existing
    /// libraries — ids already present are skipped). Returns the refetched library, or nil if nothing was seeded.
    /// Flags are set before awaiting so a concurrent load doesn't seed twice, and reset if the save fails so the
    /// next launch retries instead of stranding the user with an empty library.
    private func seedIfNeeded(existing: [RecipeModel]) async -> [RecipeModel]? {
        let storage = LocalStore.shared
        let startersKey = "seedRecipesLoaded"
        let bundledKey = "bundledRecipesSeeded_v1"
        let seedStarters = existing.isEmpty && !storage.bool(forKey: startersKey)
        let seedBundled = !storage.bool(forKey: bundledKey)
        guard seedStarters || seedBundled else { return nil }
        if seedStarters { storage.set(true, forKey: startersKey) }
        if seedBundled { storage.set(true, forKey: bundledKey) }

        var toSeed = seedStarters ? SeedRecipeProvider.recipes : []
        if seedBundled {
            // Decode the bundled JSON off the main actor — it's a few hundred recipes.
            let bundled = await Task.detached(priority: .userInitiated) { BundledRecipeCatalog.load() }.value
            let existingIDs = Set(existing.map(\.id))
            toSeed += bundled.filter { !existingIDs.contains($0.id) }
        }
        guard !toSeed.isEmpty else { return nil }
        guard await persistence.seedRecipes(toSeed) else {
            if seedStarters { storage.set(false, forKey: startersKey) }
            if seedBundled { storage.set(false, forKey: bundledKey) }
            return nil
        }
        return await persistence.fetchRecipesAsync()
    }

    /// Awaitable reload from the store (used by pull-to-refresh and post-write syncs).
    func refresh() async {
        recipes = await persistence.fetchRecipesAsync()
    }

    /// Persists an edit and upserts it into the in-memory library so observers update; returns false (state untouched) on failure.
    @discardableResult
    func save(_ recipe: RecipeModel) -> Bool {
        guard persistence.saveRecipeModel(recipe) else { return false }
        if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[index] = recipe
        } else {
            recipes.append(recipe)
        }
        return true
    }

    /// Persists a new recipe and appends it. Returns false on failure.
    @discardableResult
    func add(_ recipe: RecipeModel) -> Bool {
        save(recipe)
    }

    func delete(id: UUID) {
        // Clean up owned image files so deleting a recipe doesn't leak orphaned hero/gallery photos on disk.
        if let recipe = recipes.first(where: { $0.id == id }) {
            if let hero = recipe.imageName { imageStore.deleteIfLocal(hero) }
            recipe.photoNames.forEach { imageStore.deleteIfLocal($0) }
        }
        recipes.removeAll { $0.id == id }
        persistence.deleteRecipe(withId: id)
    }

    /// Upserts an already-persisted recipe into the in-memory library without re-writing — for ops (recordCook/updateRating) that persist via their own path but still need the observable array synced.
    func sync(_ recipe: RecipeModel) {
        if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[index] = recipe
        }
    }
}
