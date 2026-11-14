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

    // Internal so RecipeStore+RemoteImages.swift can sync photos through it.
    @ObservationIgnored let persistence: PersistenceController
    @ObservationIgnored private let imageStore: RecipeImageStore
    // Internal so RecipeStore+RemoteImages.swift can use them.
    @ObservationIgnored let imageLocalizer: RecipeImageLocalizer
    /// Latest queued picture download; each waits for the one before.
    @ObservationIgnored var imageLocalization: Task<Void, Never>?
    /// Web pictures already tried this launch.
    @ObservationIgnored var attemptedPictures: Set<String> = []
    /// Latest queued iCloud photo pass (`syncPhotosWithICloud`); each waits for the one before.
    @ObservationIgnored var photoSync: Task<Void, Never>?
    /// Photo paths the last queued pass saw shown; nil until the first pass of this launch (`RecipePhotoSync.removedPaths`).
    @ObservationIgnored var syncedPhotoPaths: Set<String>?
    /// Bumped on each load so a slow earlier fetch can't overwrite a newer one's result.
    @ObservationIgnored private var loadGeneration = 0

    init(
        persistence: PersistenceController = .shared,
        imageStore: RecipeImageStore = RecipeImageStore(),
        imageLocalizer: RecipeImageLocalizer = RecipeImageLocalizer()
    ) {
        self.persistence = persistence
        self.imageStore = imageStore
        self.imageLocalizer = imageLocalizer
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
            fetched = seedUITestMissingAmountsRecipeIfRequested(into: fetched)
            seedUITestTonightPlanIfRequested(from: fetched)
            seedUITestUseSoonIfRequested()
            #endif
            // Ignore a stale fetch superseded by a newer load.
            guard generation == loadGeneration else { return }
            // With iCloud sync on, another device's built-in recipes arrive with the same ids as this one's.
            if persistence.mergeSyncedRecipeCopies(of: RecipeCopyMerge.repeatedIDs(in: fetched)) {
                fetched = await persistence.fetchRecipesAsync()
                guard generation == loadGeneration else { return }
            }
            fetched = RecipeCopyMerge.oneCopyEach(fetched)
            // Repair flags first: dedupe only removes sample copies, and legacy samples lacked the flag.
            let repaired = await repairLegacySampleFlags(in: fetched)
            let deduped = removeDuplicateCopies(from: repaired)
            recipes = await refreshStaleSamples(in: deduped)
            isLoading = false
            keepWebPictures(of: recipes)
            syncPhotosWithICloud()
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
        let refreshes = await Task.detached(priority: .utility) { () -> [RecipeModel]? in
            let current = BundledRecipeCatalog.load()
            let history = BundledRecipeCatalog.loadHistory()
            guard BundledRecipeCatalog.canCompleteSampleRefresh(current: current, history: history) else { return nil }
            return BundledRecipeCatalog.sampleUpdates(library: library, current: current, history: history)
        }.value
        // Bundle data missing or unreadable: leave the version unmarked so the next launch retries.
        guard let refreshes else { return library }
        // One background save; on failure keep the old copies and retry next launch.
        guard await persistence.updateRecipesInBackground(refreshes) else { return library }
        LocalStore.shared.set(BundledRecipeCatalog.sampleRefreshVersion, forKey: key)
        guard !refreshes.isEmpty else { return library }
        let byID = Dictionary(refreshes.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        Self.logger.info("Refreshed \(refreshes.count) stale sample recipes")
        return library.map { byID[$0.id] ?? $0 }
    }

    /// One-time cleanup of duplicate sample copies (see `BackupMerge.duplicateRecipeIDs`) left by old re-seeding
    /// builds. Runs once per install so it can never touch copies made later. Goes straight to persistence rather
    /// than `delete(id:)` so image files shared with the kept copy are never removed.
    private func removeDuplicateCopies(from library: [RecipeModel]) -> [RecipeModel] {
        let key = "duplicateSampleCopiesRemoved_v1"
        guard !LocalStore.shared.bool(forKey: key) else { return library }
        LocalStore.shared.set(true, forKey: key)
        let duplicates = BackupMerge.duplicateRecipeIDs(in: library)
        guard !duplicates.isEmpty else { return library }
        for id in duplicates {
            persistence.deleteRecipe(withId: id)
        }
        Self.logger.info("Removed \(duplicates.count) duplicate recipe copies")
        return library.filter { !duplicates.contains($0.id) }
    }

    static let logger = AppLogger.logger(category: "RecipeStore")

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

    /// UI-test hook (`-seed-missing-amounts-recipe`): a recipe whose ingredients mostly lack amounts, named to sort
    /// first, so Screenshots can capture the "Estimate amounts" review sheet. Idempotent via a fixed id.
    private func seedUITestMissingAmountsRecipeIfRequested(into library: [RecipeModel]) -> [RecipeModel] {
        guard ProcessInfo.processInfo.arguments.contains("-seed-missing-amounts-recipe"),
              let id = UUID(uuidString: "5EED0000-0000-4000-8000-00000000A002"),
              !library.contains(where: { $0.id == id }) else { return library }
        let recipe = RecipeModel(
            id: id, name: "1-Bowl Banana Bread", category: "Dessert", difficulty: "Basic",
            prepTime: "10 minutes", cookingTime: "50 minutes", baseServings: 8,
            ingredients: ["ripe bananas", "plain flour", "light brown sugar", "butter, melted"].map {
                Ingredient(baseQuantity: 0, unit: "", name: $0)
            } + [Ingredient(baseQuantity: 1, unit: "tsp", name: "baking soda")],
            prePrepInstructions: [], instructions: ["Mash the bananas.", "Stir everything together.", "Bake 50 minutes."],
            notes: ""
        )
        guard persistence.saveRecipeModel(recipe) else { return library }
        return library + [recipe]
    }

    /// UI-test hook (`-seed-tonight-plan`): plans tonight's dinner (first recipe by name) and tomorrow's dinner (first
    /// recipe that needs prepping ahead) so Screenshots can capture Today's "Planned for tonight" hero and prep-ahead
    /// nudge. Leaves existing dinner plans alone.
    private func seedUITestTonightPlanIfRequested(from library: [RecipeModel]) {
        let planner = MealPlanningManager.shared
        guard ProcessInfo.processInfo.arguments.contains("-seed-tonight-plan") else { return }
        let now = Date()
        let sorted = library.sorted { $0.name < $1.name }
        if planner.mealPlan(for: now, mealTime: .dinner) == nil, let recipe = sorted.first {
            planner.addMealPlan(MealPlanModel(recipeId: recipe.id, recipeName: recipe.name, date: now, mealTime: .dinner))
        }
        if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now),
           planner.mealPlan(for: tomorrow, mealTime: .dinner) == nil,
           let recipe = sorted.first(where: { PrepAhead.cue(for: $0) != nil }) {
            planner.addMealPlan(MealPlanModel(recipeId: recipe.id, recipeName: recipe.name, date: tomorrow, mealTime: .dinner))
        }
    }

    /// UI-test hook (`-seed-use-soon`): spinach going off tomorrow and lemons in three days, so Screenshots can
    /// capture Today's "Use it up" card. The bundled recipes use both. Replaced each launch so a reused simulator
    /// never keeps yesterday's dates.
    private func seedUITestUseSoonIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains("-seed-use-soon") else { return }
        let kitchen = KitchenInventoryManager.shared
        for (name, days) in [("Spinach", 1), ("Lemons", 3)] {
            for stale in kitchen.inventoryItems where stale.name == name { kitchen.removeInventoryItem(stale) }
            guard let expiry = Calendar.current.date(byAdding: .day, value: days, to: Date()) else { continue }
            kitchen.addInventoryItem(KitchenInventoryModel(
                name: name, category: .produce, quantity: 1, unit: "", storageLocation: .fridge, expiryDate: expiry
            ))
        }
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
        keepWebPictures(of: [recipe])
        syncPhotosWithICloud()
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
            removeKeptPicture(of: recipe)
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
