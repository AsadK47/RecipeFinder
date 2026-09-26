import SwiftUI

/// Single source of truth for the user's recipe library. Views observe this
/// `@Observable` store (via `@Environment(\.recipeStore)` or a store-backed
/// binding) so a write anywhere updates every surface — replacing the old
/// pattern of value-type copies kept in sync by manual `onRecipeChange` callbacks.
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
    // SwiftUI reads environment defaults on the main actor during view updates,
    // so assuming main-actor isolation here is safe; the app shares one instance.
    static var defaultValue: any RecipeStoring {
        MainActor.assumeIsolated { RecipeStore.shared }
    }
}

extension EnvironmentValues {
    /// Injected recipe store. Defaults to the shared singleton; override with
    /// `.environment(\.recipeStore, fake)` in tests/previews.
    var recipeStore: any RecipeStoring {
        get { self[RecipeStoreKey.self] }
        set { self[RecipeStoreKey.self] = newValue }
    }
}

@MainActor
@Observable
final class RecipeStore: RecipeStoring {
    static let shared = RecipeStore()

    /// Settable so a store-backed `Binding` can front existing `@Binding var
    /// recipes` view APIs during the migration.
    var recipes: [RecipeModel] = []
    private(set) var isLoading = true

    @ObservationIgnored private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    /// Loads the library for the current user (or seed recipes in guest mode).
    /// Mirrors the retry/seed behaviour previously inline in `ContentView`.
    func load(isAuthenticated: Bool) {
        loadRecipes(isAuthenticated: isAuthenticated, retryAttempt: 0)
    }

    private func loadRecipes(isAuthenticated: Bool, retryAttempt: Int) {
        // Guest mode: show seed recipes so the app isn't empty before sign-up.
        guard isAuthenticated else {
            if recipes.isEmpty { recipes = SeedRecipeProvider.recipes }
            isLoading = false
            return
        }

        guard persistence.hasCurrentUserScope() else {
            AppLogger.logger(category: "RecipeStore")
                .debug("⚠️ Skipping recipe reload because user scope is not available")
            return
        }

        // The store loads synchronously at launch, but corrupted-store recovery
        // reloads it late. Retry so one early empty fetch doesn't strand the user
        // with a blank list for the session.
        guard persistence.isStoreLoaded else {
            guard retryAttempt < 5 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.loadRecipes(isAuthenticated: isAuthenticated, retryAttempt: retryAttempt + 1)
            }
            return
        }

        // Fetch off the main thread so a large library doesn't freeze the UI.
        Task {
            var fetched = await persistence.fetchRecipesAsync()
            // Seed starter recipes for brand-new users — one-time per account.
            if fetched.isEmpty, !UserScopedStorage.shared.bool(forKey: "seedRecipesLoaded") {
                await persistence.seedRecipes(SeedRecipeProvider.recipes)
                UserScopedStorage.shared.set(true, forKey: "seedRecipesLoaded")
                fetched = await persistence.fetchRecipesAsync()
            }
            recipes = fetched
            isLoading = false
        }
    }

    /// Awaitable reload from the store (used by pull-to-refresh and post-write syncs).
    func refresh() async {
        guard persistence.hasCurrentUserScope() else { return }
        recipes = await persistence.fetchRecipesAsync()
    }

    /// Persists an edit and upserts it into the in-memory library so every
    /// observing surface updates. Returns false (and leaves state untouched) on
    /// a persistence failure so callers can surface an error.
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
        recipes.removeAll { $0.id == id }
        persistence.deleteRecipe(withId: id)
    }

    /// Upserts an already-persisted recipe into the in-memory library without a
    /// re-write. For specialised persistence ops (recordCook/updateRating) that
    /// persist via their own path but still need the observable array in sync.
    func sync(_ recipe: RecipeModel) {
        if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[index] = recipe
        }
    }
}
