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

    private init() {
        container = NSPersistentContainer(name: "RecipeModel")
        configureStore()
        loadStore()
    }

    private func configureStore() {
        guard let description = container.persistentStoreDescriptions.first else { return }

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

        do {
            try FileManager.default.removeItem(at: storeURL)
            persistenceLogger.debug("✅ Removed corrupted store file")

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
        } catch {
            persistenceLogger.error("❌ Failed to remove corrupted store: \(error.localizedDescription)")
            self.loadError = error
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
