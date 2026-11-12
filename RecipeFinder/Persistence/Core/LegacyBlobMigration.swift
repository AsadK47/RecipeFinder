import Foundation

private let migrationLogger = AppLogger.logger(category: "LegacyBlobMigration")

/// What happened when a `LocalStore` JSON blob was moved into Core Data.
enum BlobMigrationResult: Equatable {
    case alreadyMigrated
    /// No blob, or one that can't be decoded (`LocalStore` keeps it as `<key>.corrupt`): nothing to move.
    case nothingToMigrate
    case migrated(count: Int)
    /// Writing or verifying failed; not marked, so the next launch tries again and the caller keeps using the blob.
    case failed
}

/// One-time move of a manager's `LocalStore` blob into Core Data entities (Data safety 1/4).
///
/// Writes only the values the store doesn't already hold (a retry after a half-finished run never duplicates), then
/// re-reads the store and checks every blob value is there before marking the key migrated. The blob is left in place
/// for one release as a fallback.
@MainActor
enum LegacyBlobMigration {
    static func flagKey(for blobKey: String) -> String { "migratedToCoreData.\(blobKey)" }

    static func run<Value: Decodable & Hashable>(
        blobKey: String,
        as _: Value.Type,
        storage: LocalStore,
        fetch: () throws -> [Value],
        insert: ([Value]) throws -> Void
    ) -> BlobMigrationResult {
        let flag = flagKey(for: blobKey)
        guard !storage.bool(forKey: flag) else { return .alreadyMigrated }

        guard let values = storage.decodable([Value].self, forKey: blobKey) else {
            storage.set(true, forKey: flag)
            return .nothingToMigrate
        }

        do {
            let missing = subtracting(try fetch(), from: values)
            try insert(missing)
            let stored = try fetch()
            guard subtracting(stored, from: values).isEmpty else {
                migrationLogger.error("❌ \(blobKey): store is missing values after migration; will retry next launch")
                return .failed
            }
            storage.set(true, forKey: flag)
            migrationLogger.info("✅ \(blobKey): moved \(values.count) values to Core Data (\(missing.count) written)")
            return .migrated(count: values.count)
        } catch {
            migrationLogger.error("❌ \(blobKey): migration failed, will retry next launch: \(error.localizedDescription)")
            return .failed
        }
    }

    /// Multiset difference, so two cooks at the same instant stay two rows.
    static func subtracting<Value: Hashable>(_ present: [Value], from wanted: [Value]) -> [Value] {
        var available = Dictionary(present.map { ($0, 1) }, uniquingKeysWith: +)
        var missing: [Value] = []
        for value in wanted {
            if let count = available[value], count > 0 {
                available[value] = count - 1
            } else {
                missing.append(value)
            }
        }
        return missing
    }
}
