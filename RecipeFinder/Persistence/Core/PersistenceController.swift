import CoreData
import Foundation

let persistenceLogger = AppLogger.logger(category: "PersistenceController")

/// Core Data stack owner; store lifecycle here, reads/writes/maintenance in focused extensions.
@MainActor
final class PersistenceController {
    static let shared = PersistenceController(
        backupDirectory: StoreBackup.defaultDirectory(),
        syncOn: SyncPreference.isOn(in: .shared)
    )

    let container: NSPersistentContainer
    private(set) var loadError: Error?
    private(set) var isStoreLoaded = false
    /// Where `takeOutsideChanges()` last stopped reading the store's history (`PersistenceController+RemoteChanges`).
    var lastHistoryToken: NSPersistentHistoryToken?

    /// True when the open store is mirrored to iCloud (sync was on at launch and the store opened with it).
    var isSyncing: Bool {
        isStoreLoaded && container.persistentStoreDescriptions.first?.cloudKitContainerOptions != nil
    }

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
        static let isSampleRecipe = "isSampleRecipe"
        static let dietaryInfo = "dietaryInfo"
        static let tags = "tags"
        static let cookCount = "cookCount"
        static let lastCookedAt = "lastCookedAt"
        static let rating = "rating"
        static let cuisine = "cuisine"
        static let sourceText = "sourceText"
        static let photoNames = "photoNames"
    }

    /// `inMemory`: back store with `/dev/null` for tests (still SQLite so batch ops work).
    /// `backupDirectory`: where the store is copied before a model upgrade (`StoreBackup`); nil = no copy (tests),
    /// so only `.shared` writes to the real Application Support.
    /// `syncOn`: mirror the store to the cook's iCloud (`CloudSyncStore`); read once at launch. Never in tests.
    init(inMemory: Bool = false, storeURL: URL? = nil, backupDirectory: URL? = nil, syncOn: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "RecipeModel")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else if let storeURL {
            container.persistentStoreDescriptions.first?.url = storeURL
        }
        configureStore(syncOn: syncOn && !inMemory)
        if !inMemory, let backupDirectory { backUpBeforeMigration(into: backupDirectory) }
        loadStore()
    }

    /// Copies the store aside when opening it is about to upgrade it. A failed copy is logged and the upgrade goes
    /// ahead: refusing to open would lock the cook out of every recipe, and recovery still preserves a store it
    /// can't open.
    private func backUpBeforeMigration(into directory: URL) {
        guard let storeURL = container.persistentStoreDescriptions.first?.url, storeURL.isFileURL,
              StoreBackup.needsMigration(storeURL: storeURL, model: container.managedObjectModel)
        else { return }
        do {
            if let folder = try StoreBackup.backUp(storeURL: storeURL, into: directory) {
                persistenceLogger.debug("💾 Store copied to \(folder.lastPathComponent) before upgrade")
            }
        } catch {
            persistenceLogger.error("❌ Store backup before upgrade failed: \(error.localizedDescription)")
        }
    }

    private func configureStore(syncOn: Bool) {
        guard let description = container.persistentStoreDescriptions.first else { return }
        CloudSyncStore.configure(description, syncOn: syncOn)

        // Lightweight migration; baseline is model v6+ (all-Binary `ingredients`). Pre-v6 Transformable can't migrate (see CoreDataMigrationTests) — app unreleased, and recovery preserves any store it can't open.
        description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }

    private func loadStore() {
        // Store loads synchronously, so set isStoreLoaded here (not a deferred Task): deferring left the flag false for one runloop turn, so launch-time fetchRecipes() returned [] and the list stayed empty for the session.
        container.loadPersistentStores { [weak self] storeDescription, error in
            MainActor.assumeIsolated {
                guard let self else { return }
                let storeURL = storeDescription.url?.absoluteString ?? "unknown location"

                if let error = error as NSError? {
                    persistenceLogger.error("❌ Failed to load persistent store: \(error.localizedDescription)")
                    persistenceLogger.error("❌ Error details: \(error.userInfo)")

                    self.loadError = error
                    self.isStoreLoaded = false
                    if !self.retryWithoutSync(storeDescription) {
                        self.attemptStoreRecovery()
                    }
                } else {
                    persistenceLogger.debug("✅ Core Data store loaded successfully at: \(storeURL)")
                    self.isStoreLoaded = true
                    self.loadError = nil
                }
            }
        }
    }

    /// A store that won't open with the iCloud mirror attached (no iCloud account set-up issue, CloudKit refusing
    /// the model) is opened on this device alone instead of being moved aside: the store itself is fine, and
    /// recovery would hide every recipe. Returns false when sync wasn't on, so the failure is the store's own.
    private func retryWithoutSync(_ failed: NSPersistentStoreDescription) -> Bool {
        guard let description = container.persistentStoreDescriptions.first,
              description.cloudKitContainerOptions != nil, failed.cloudKitContainerOptions != nil
        else { return false }
        persistenceLogger.error("⚠️ Store wouldn't open with iCloud sync; opening it on this device only")
        description.cloudKitContainerOptions = nil
        loadStore()
        return true
    }

    private func attemptStoreRecovery() {
        persistenceLogger.debug("🔄 Attempting to recover from Core Data store failure...")

        guard let storeURL = container.persistentStoreDescriptions.first?.url else {
            persistenceLogger.error("❌ Cannot recover: store URL not found")
            return
        }

        // Never destroy data: move the unreadable store (+ -wal/-shm sidecars) aside rather than delete, so a failed migration is recoverable. Only replace once originals are preserved.
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

        // Couldn't move the main store aside: don't recreate over it — leave data intact for a later attempt.
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
