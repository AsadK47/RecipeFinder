import Foundation

private let logger = AppLogger.logger(category: "CollectionManager")

@MainActor
final class CollectionManager: ObservableObject {
    static let shared = CollectionManager()

    private let saveKey = Constants.UserDefaultsKeys.collections
    private let storage: UserScopedStorage

    @Published private(set) var collections: [RecipeCollection] = []

    private init() {
        self.storage = .shared
        loadCollections()
    }

    init(storage: UserScopedStorage) {
        self.storage = storage
        loadCollections()
    }

    func reloadForCurrentUser() {
        loadCollections()
    }

    private func loadCollections() {
        if let data = storage.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([RecipeCollection].self, from: data) {
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
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let collection = RecipeCollection(name: trimmed, colorName: color)
        var updated = collections
        updated.append(collection)
        logger.debug("✅ Created collection '\(trimmed)'")
        saveCollections(updated)
        HapticManager.shared.success()
    }

    func rename(_ collection: RecipeCollection, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
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
        var updated = collections
        let existingIDs = Set(updated.map(\.id))
        for collection in incoming where !existingIDs.contains(collection.id) {
            updated.append(collection)
        }
        saveCollections(updated)
    }
}
