import CoreData
import Foundation

/// Copies the recipe database (+ its -wal/-shm files) aside before Core Data upgrades it to a new model version, so
/// an upgrade that goes wrong can't take the cook's recipes with it. Keeps the newest three copies.
enum StoreBackup {
    static let folderPrefix = "store-"
    static let keepCount = 3
    private static let sidecars = ["", "-wal", "-shm"]

    /// Application Support/StoreBackups — kept out of Caches so iOS never purges it.
    static func defaultDirectory(fileManager: FileManager = .default) -> URL? {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("StoreBackups", isDirectory: true)
    }

    /// True when a store exists at `storeURL` that `model` didn't write — opening it will migrate. A store whose
    /// metadata can't be read counts too: copying it costs a little disk, losing it costs everything.
    static func needsMigration(storeURL: URL, model: NSManagedObjectModel, fileManager: FileManager = .default) -> Bool {
        guard fileManager.fileExists(atPath: storeURL.path) else { return false }
        do {
            let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                ofType: NSSQLiteStoreType, at: storeURL, options: nil
            )
            return !model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        } catch {
            return true
        }
    }

    /// Copies the store files into a new dated folder in `directory`, then keeps the newest `keep` folders.
    /// Returns the new folder, or nil when there's no store to copy. A failed copy removes its half-made folder.
    @discardableResult
    static func backUp(
        storeURL: URL,
        into directory: URL,
        now: Date = Date(),
        keep: Int = keepCount,
        fileManager: FileManager = .default
    ) throws -> URL? {
        guard fileManager.fileExists(atPath: storeURL.path) else { return nil }

        let folder = directory.appendingPathComponent(folderName(for: now), isDirectory: true)
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        do {
            for sidecar in sidecars {
                let source = URL(fileURLWithPath: storeURL.path + sidecar)
                guard fileManager.fileExists(atPath: source.path) else { continue }
                try fileManager.copyItem(at: source, to: folder.appendingPathComponent(storeURL.lastPathComponent + sidecar))
            }
        } catch {
            try? fileManager.removeItem(at: folder)
            throw error
        }
        try prune(directory, keep: keep, fileManager: fileManager)
        return folder
    }

    /// `store-<ms since 1970, zero-padded>-<random>`: names sort in time order, and two copies in the same
    /// millisecond don't collide.
    static func folderName(for date: Date) -> String {
        let milliseconds = max(0, Int64((date.timeIntervalSince1970 * 1000).rounded(.down)))
        let stamp = String(milliseconds)
        let padded = String(repeating: "0", count: max(0, 15 - stamp.count)) + stamp
        return folderPrefix + padded + "-" + String(UUID().uuidString.prefix(8))
    }

    /// Deletes all but the newest `keep` backup folders; anything else in the directory is left alone.
    private static func prune(_ directory: URL, keep: Int, fileManager: FileManager) throws {
        let folders = try fileManager.contentsOfDirectory(atPath: directory.path)
            .filter { $0.hasPrefix(folderPrefix) }
            .sorted()
        for name in folders.dropLast(keep) {
            try fileManager.removeItem(at: directory.appendingPathComponent(name))
        }
    }
}
