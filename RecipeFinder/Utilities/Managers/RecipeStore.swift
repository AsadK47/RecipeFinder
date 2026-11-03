import SwiftUI

// Single source of truth for the recipe library; observing views update on any write, replacing manual onRecipeChange sync of value-type copies.
@MainActor
protocol RecipeStoring: AnyObject, Observable {
    var recipes: [RecipeModel] { get set }
    var isLoading: Bool { get }
    func load(isAuthenticated: Bool)
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

    /// Settable for the sign-out reset (`ContentView`) and ephemeral in-memory adds (e.g. quick snacks) that shouldn't touch Core Data.
    var recipes: [RecipeModel] = []
    private(set) var isLoading = true

    @ObservationIgnored private let persistence: PersistenceController
    @ObservationIgnored private let imageStore: RecipeImageStore
    /// Bumped on each load so a slow earlier fetch (e.g. previous account) can't overwrite a newer one's result.
    @ObservationIgnored private var loadGeneration = 0
    /// Which library the last load targeted (nil before the first load); detects guest↔account switches.
    @ObservationIgnored private var isGuestLibrary: Bool?

    init(persistence: PersistenceController = .shared, imageStore: RecipeImageStore = RecipeImageStore()) {
        self.persistence = persistence
        self.imageStore = imageStore
    }

    /// Loads the current user's library (or seed recipes in guest mode); mirrors the retry/seed behaviour once inline in `ContentView`.
    func load(isAuthenticated: Bool) {
        loadRecipes(isAuthenticated: isAuthenticated, retryAttempt: 0)
    }

    private func loadRecipes(isAuthenticated: Bool, retryAttempt: Int) {
        // Guests load the persisted guest scope (nil userId) through the same fetch/seed path as accounts —
        // showing only in-memory seeds dropped every recipe a guest added or cooked on relaunch.
        // Clear on a guest↔account switch so one library doesn't linger during the other's async fetch.
        if isGuestLibrary == isAuthenticated {
            recipes = []
            isLoading = true
        }
        isGuestLibrary = !isAuthenticated

        // Signed in but the account scope isn't set yet: don't fall through to the guest scope.
        guard !isAuthenticated || persistence.hasCurrentUserScope() else {
            AppLogger.logger(category: "RecipeStore")
                .debug("⚠️ Skipping recipe reload because user scope is not available")
            return
        }

        // Corrupted-store recovery reloads the store late, so retry — one early empty fetch shouldn't strand the user with a blank list.
        guard persistence.isStoreLoaded else {
            guard retryAttempt < 5 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.loadRecipes(isAuthenticated: isAuthenticated, retryAttempt: retryAttempt + 1)
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
            // Ignore a stale fetch superseded by a newer load (account switch / scope change).
            guard generation == loadGeneration else { return }
            recipes = fetched
            isLoading = false
        }
    }

    /// One-time seeding per scope: starters for an empty library, plus the bundled collection (once, even for existing
    /// libraries — ids already present are skipped). Returns the refetched library, or nil if nothing was seeded.
    /// Flags are set before awaiting so a concurrent load doesn't seed twice, and reset if the save fails so the
    /// next launch retries instead of stranding the user with an empty library.
    private func seedIfNeeded(existing: [RecipeModel]) async -> [RecipeModel]? {
        let storage = UserScopedStorage.shared
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
        guard isGuestLibrary == true || persistence.hasCurrentUserScope() else { return }
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
