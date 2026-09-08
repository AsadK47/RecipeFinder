import CoreData
import Foundation

let persistenceLogger = AppLogger.logger(category: "PersistenceController")

/// Core Data stack owner. Store lifecycle (load, configure, recover) lives here;
/// recipe reads/writes and database maintenance live in focused extensions:
/// - `PersistenceController+RecipeWrites` — save/update/delete/favorite
/// - `PersistenceController+RecipeFetch` — fetch/count/mapping
/// - `PersistenceController+Database` — clear/reset
/// - `SampleRecipeData` — sample data population
@MainActor
final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer
    private(set) var loadError: Error?
    private(set) var isStoreLoaded = false

    /// Current account scope. Recipes are stamped with and filtered by this id.
    /// Defaults to the shared per-user store; injected in tests so scoping can be
    /// exercised against an in-memory store without touching global state.
    let userID: () -> String?

    enum Entity {
        static let recipe = "Recipe"
    }

    enum RecipeKey {
        static let id = "id"
        static let name = "name"
        static let category = "category"
        static let difficulty = "difficulty"
        static let prepTime = "prepTime"
        static let cookingTime = "cookingTime"
        static let baseServings = "baseServings"
        static let currentServings = "currentServings"
        static let ingredients = "ingredients"
        static let prePrepInstructions = "prePrepInstructions"
        static let instructions = "instructions"
        static let notes = "notes"
        static let imageName = "imageName"
        static let isFavorite = "isFavorite"
        static let userId = "userId"
    }

    /// - Parameters:
    ///   - inMemory: back the store with `/dev/null` (isolated, non-persisted)
    ///     for tests. Kept as SQLite so batch operations still work.
    ///   - userID: account-scope provider (see `userID`).
    init(
        inMemory: Bool = false,
        storeURL: URL? = nil,
        userID: @escaping () -> String? = { UserScopedStorage.shared.currentUserId }
    ) {
        self.userID = userID
        container = NSPersistentContainer(name: "RecipeModel")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else if let storeURL {
            container.persistentStoreDescriptions.first?.url = storeURL
        }
        configureStore()
        loadStore()
    }

    private func configureStore() {
        guard let description = container.persistentStoreDescriptions.first else { return }

        // Automatic lightweight migration. Supported baseline is model v6+ (the
        // all-Binary `ingredients` era); pre-v6 versions used a Transformable
        // `ingredients` that can't lightweight-migrate to the current model — see
        // CoreDataMigrationTests. The app is unreleased, so no shipped store is
        // affected, and attemptStoreRecovery() preserves any store it can't open.
        description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }

    private func loadStore() {
        // The store loads synchronously (shouldAddStoreAsynchronously is
        // false by default), so this completion runs on the main thread
        // before loadPersistentStores returns. isStoreLoaded must be set
        // right here, not via a deferred Task: deferring it left the flag
        // false for the first runloop turn, so the launch-time fetchRecipes()
        // returned [] with no retry and the recipe list stayed empty for the
        // whole session — intermittently, depending on scheduling.
        container.loadPersistentStores { [weak self] storeDescription, error in
            MainActor.assumeIsolated {
                guard let self else { return }
                let storeURL = storeDescription.url?.absoluteString ?? "unknown location"

                if let error = error as NSError? {
                    persistenceLogger.error("❌ Failed to load persistent store: \(error.localizedDescription)")
                    persistenceLogger.error("❌ Error details: \(error.userInfo)")

                    self.loadError = error
                    self.isStoreLoaded = false
                    self.attemptStoreRecovery()
                } else {
                    persistenceLogger.debug("✅ Core Data store loaded successfully at: \(storeURL)")
                    self.isStoreLoaded = true
                    self.loadError = nil
                }
            }
        }
    }

    private func attemptStoreRecovery() {
        persistenceLogger.debug("🔄 Attempting to recover from Core Data store failure...")

        guard let storeURL = container.persistentStoreDescriptions.first?.url else {
            persistenceLogger.error("❌ Cannot recover: store URL not found")
            return
        }

        // Never destroy the user's data. Move the unreadable store aside (with its
        // -wal/-shm sidecars) instead of deleting it, so a failed migration or a
        // corrupt file is recoverable rather than silent total loss. Only after the
        // originals are safely preserved do we let a fresh store take their place.
        let backupSuffix = ".corrupt-\(Int(Date().timeIntervalSince1970))"
        var preservedMainStore = false
        for sidecar in ["", "-wal", "-shm"] {
            let source = URL(fileURLWithPath: storeURL.path + sidecar)
            guard FileManager.default.fileExists(atPath: source.path) else { continue }
            let destination = URL(fileURLWithPath: storeURL.path + backupSuffix + sidecar)
            do {
                try FileManager.default.moveItem(at: source, to: destination)
                if sidecar.isEmpty { preservedMainStore = true }
            } catch {
                persistenceLogger.error("❌ Failed to preserve store file \(source.lastPathComponent): \(error.localizedDescription)")
            }
        }

        // If we couldn't move the main store aside, do NOT recreate over it —
        // reloading will just re-fail, leaving the data intact for a later attempt.
        guard preservedMainStore else {
            persistenceLogger.error("❌ Could not preserve the unreadable store; leaving it in place to avoid data loss")
            self.isStoreLoaded = false
            return
        }

        persistenceLogger.error("⚠️ Unreadable store preserved as \(storeURL.lastPathComponent)\(backupSuffix); starting a fresh store")

        container.loadPersistentStores { [weak self] _, error in
            MainActor.assumeIsolated {
                guard let self else { return }

                if let error {
                    persistenceLogger.error("❌ Recovery failed: \(error.localizedDescription)")
                    self.loadError = error
                    self.isStoreLoaded = false
                } else {
                    persistenceLogger.debug("✅ Store recovered successfully")
                    self.isStoreLoaded = true
                    self.loadError = nil
                    self.populateDatabase()
                }
            }
        }
    }

    @discardableResult
    func ensureStoreIsReady() -> Bool {
        guard isStoreLoaded else {
            persistenceLogger.debug("⚠️ Store not loaded. Cannot perform operation.")
            return false
        }
        return true
    }
}
