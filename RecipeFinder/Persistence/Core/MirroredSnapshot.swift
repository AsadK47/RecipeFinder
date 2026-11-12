import Foundation

enum MirroredSnapshotError: LocalizedError {
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .verificationFailed: "The database didn't hold what was just saved."
        }
    }
}

/// Keeps a whole-list `LocalStore` blob (collections, meal plans, shopping list…) in Core Data entities (Data safety
/// 1/4), with the blob kept current for one release as a fallback.
///
/// - First load copies the blob in, re-reads it and checks it matches before marking the key migrated.
/// - The blob is always written first, so it's never behind the store. That makes it safe to copy it in again
///   whenever the key is unmarked: any launch where the store can't be read or written runs on the blob and unmarks,
///   so the next launch replaces the store with the blob (edits, renames and deletes all carry over, no duplicates).
/// - A store that comes back empty while the blob isn't (recovery replaced an unreadable store) is refilled.
/// - Reset records a pending wipe, retried each launch, so a failed delete never brings erased data back.
@MainActor
final class MirroredSnapshot<Value: Codable & Equatable> {
    private let blobKey: String
    private let storage: LocalStore
    private let fetch: () throws -> [Value]
    private let replace: ([Value]) throws -> Void
    private let logger = AppLogger.logger(category: "MirroredSnapshot")

    /// False when the store can't be used this launch: the blob is read and written instead.
    private(set) var usesEntities = false

    init(
        blobKey: String,
        storage: LocalStore,
        fetch: @escaping () throws -> [Value],
        replace: @escaping ([Value]) throws -> Void
    ) {
        self.blobKey = blobKey
        self.storage = storage
        self.fetch = fetch
        self.replace = replace
    }

    static func wipePendingKey(for blobKey: String) -> String { "wipePending.\(blobKey)" }

    private var flagKey: String { LegacyBlobMigration.flagKey(for: blobKey) }
    private var wipePendingKey: String { Self.wipePendingKey(for: blobKey) }

    /// `LocalStore` keeps an undecodable blob aside as `<key>.corrupt`, so nil means missing or corrupt.
    private func blob() -> [Value]? {
        storage.decodable([Value].self, forKey: blobKey)
    }

    func load() -> [Value] {
        guard finishPendingWipe() else { return fallBackToBlob() }
        do {
            if !storage.bool(forKey: flagKey) {
                if let values = blob() {
                    try copyIn(values)
                    logger.info("✅ \(self.blobKey): moved \(values.count) values to Core Data")
                }
                storage.set(true, forKey: flagKey)
            }
            var values = try fetch()
            if values.isEmpty, let kept = blob(), !kept.isEmpty {
                logger.error("⚠️ \(self.blobKey): store is empty but the kept copy isn't; copying it in again")
                try copyIn(kept)
                values = kept
            }
            usesEntities = true
            return values
        } catch {
            logger.error("❌ \(self.blobKey): store unusable, using the kept copy: \(error.localizedDescription)")
            return fallBackToBlob()
        }
    }

    func save(_ values: [Value]) {
        storage.setEncodable(values, forKey: blobKey)
        guard usesEntities else {
            storage.removeObject(forKey: flagKey)
            return
        }
        do {
            try replace(values)
        } catch {
            logger.error("❌ \(self.blobKey): failed to save, kept in the old copy: \(error.localizedDescription)")
            usesEntities = false
            storage.removeObject(forKey: flagKey)
        }
    }

    /// Erase & Reset. Call `load()` afterwards.
    func removeAll() {
        storage.removeObject(forKey: blobKey)
        storage.set(true, forKey: wipePendingKey)
    }

    private func copyIn(_ values: [Value]) throws {
        try replace(values)
        guard try fetch() == values else { throw MirroredSnapshotError.verificationFailed }
    }

    private func fallBackToBlob() -> [Value] {
        usesEntities = false
        storage.removeObject(forKey: flagKey)
        return blob() ?? []
    }

    /// True when no Reset wipe is outstanding.
    private func finishPendingWipe() -> Bool {
        guard storage.bool(forKey: wipePendingKey) else { return true }
        do {
            try replace([])
            storage.removeObject(forKey: wipePendingKey)
            return true
        } catch {
            logger.error("❌ \(self.blobKey): failed to erase, will retry next launch: \(error.localizedDescription)")
            return false
        }
    }
}
