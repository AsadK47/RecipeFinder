import SwiftUI

private let logger = AppLogger.logger(category: "CollectionManager")

/// Behavioural seam so views depend on this protocol, not the `CollectionManager` singleton, and tests can inject a fake.
@MainActor
protocol CollectionManaging: AnyObject, Observable {
    var collections: [RecipeCollection] { get }
    func collection(withID id: UUID) -> RecipeCollection?
    func createCollection(name: String, color: CollectionColor)
    func rename(_ collection: RecipeCollection, to name: String)
    func recolor(_ collection: RecipeCollection, to color: CollectionColor)
    func delete(_ collection: RecipeCollection)
    func remove(recipeID: UUID, from collection: RecipeCollection)
    @discardableResult func toggle(recipeID: UUID, in collection: RecipeCollection) -> Bool
}

private struct CollectionManagingKey: EnvironmentKey {
    // SwiftUI reads environment defaults on the main actor, so assuming main-actor isolation is safe.
    static var defaultValue: any CollectionManaging {
        MainActor.assumeIsolated { CollectionManager.shared }
    }
}

extension EnvironmentValues {
    /// Injected collections store; defaults to the shared singleton, override with `.environment(\.collections, fake)` in tests/previews.
    var collections: any CollectionManaging {
        get { self[CollectionManagingKey.self] }
        set { self[CollectionManagingKey.self] = newValue }
    }
}

@MainActor
@Observable
final class CollectionManager: CollectionManaging {
    static let shared = CollectionManager()

    @ObservationIgnored private let saveKey = Constants.UserDefaultsKeys.collections
    @ObservationIgnored private let storage: LocalStore

    private(set) var collections: [RecipeCollection] = []

    private init() {
        self.storage = .shared
        loadCollections()
    }

    init(storage: LocalStore) {
        self.storage = storage
        loadCollections()
    }

    func reload() {
        loadCollections()
    }

    private func loadCollections() {
        if let decoded = storage.decodable([RecipeCollection].self, forKey: saveKey) {
            collections = decoded
        } else {
            collections = []
        }
    }

    private func saveCollections(_ updated: [RecipeCollection]) {
        collections = updated
        storage.setEncodable(updated, forKey: saveKey)
    }

    // MARK: - CRUD

    func createCollection(name: String, color: CollectionColor = .blue) {
        let trimmed = name.trimmed
        guard !trimmed.isEmpty else { return }
        let collection = RecipeCollection(name: trimmed, colorName: color)
        var updated = collections
        updated.append(collection)
        logger.debug("✅ Created collection '\(trimmed)'")
        saveCollections(updated)
        HapticManager.shared.success()
    }

    func rename(_ collection: RecipeCollection, to name: String) {
        let trimmed = name.trimmed
        guard !trimmed.isEmpty else { return }
        var updated = collections
        guard let idx = updated.firstIndex(where: { $0.id == collection.id }) else { return }
        updated[idx].name = trimmed
        saveCollections(updated)
    }

    func recolor(_ collection: RecipeCollection, to color: CollectionColor) {
        var updated = collections
        guard let idx = updated.firstIndex(where: { $0.id == collection.id }) else { return }
        updated[idx].colorName = color
        saveCollections(updated)
    }

    func delete(_ collection: RecipeCollection) {
        var updated = collections
        updated.removeAll { $0.id == collection.id }
        logger.debug("✅ Deleted collection '\(collection.name)'")
        saveCollections(updated)
        HapticManager.shared.delete()
    }

    // MARK: - Recipe membership

    func add(recipeID: UUID, to collection: RecipeCollection) {
        var updated = collections
        guard let idx = updated.firstIndex(where: { $0.id == collection.id }) else { return }
        updated[idx].add(recipeID)
        saveCollections(updated)
        HapticManager.shared.light()
    }

    func remove(recipeID: UUID, from collection: RecipeCollection) {
        var updated = collections
        guard let idx = updated.firstIndex(where: { $0.id == collection.id }) else { return }
        updated[idx].remove(recipeID)
        saveCollections(updated)
    }

    /// Toggle recipe in/out of a collection; returns the new membership state.
    @discardableResult
    func toggle(recipeID: UUID, in collection: RecipeCollection) -> Bool {
        var updated = collections
        guard let idx = updated.firstIndex(where: { $0.id == collection.id }) else { return false }
        if updated[idx].contains(recipeID) {
            updated[idx].remove(recipeID)
            saveCollections(updated)
            return false
        } else {
            updated[idx].add(recipeID)
            saveCollections(updated)
            HapticManager.shared.light()
            return true
        }
    }

    /// Remove a deleted recipe from all collections.
    func purge(recipeID: UUID) {
        var updated = collections
        for idx in updated.indices {
            updated[idx].remove(recipeID)
        }
        saveCollections(updated)
    }

    /// All collections that contain the given recipe id.
    func collections(containing recipeID: UUID) -> [RecipeCollection] {
        collections.filter { $0.contains(recipeID) }
    }

    /// The collection with the given id, or nil if it no longer exists.
    func collection(withID id: UUID) -> RecipeCollection? {
        collections.first { $0.id == id }
    }

    // MARK: - Backup

    func merge(_ incoming: [RecipeCollection]) {
        saveCollections(BackupMerge.merged(existing: collections, incoming: incoming))
    }
}
