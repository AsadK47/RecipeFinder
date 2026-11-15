import CoreData
import Foundation

/// Copies the recipe database (+ its -wal/-shm files) aside before Core Data upgrades it to a new model version, so
/// an upgrade that goes wrong can't take the cook's recipes with it. Keeps the newest three copies.
enum StoreBackup {
    static let folderPrefix = "store-"
    static let keepCount = 3
    /// Recovery moves a store it can't open aside as `<store file>.corrupt-<seconds>` (+ sidecars).
    static let setAsideMarker = ".corrupt-"
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
    /// The folder is kept out of the iCloud/device backup.
    @discardableResult
    static func backUp(
        storeURL: URL,
        into directory: URL,
        now: Date = Date(),
        keep: Int = keepCount,
        fileManager: FileManager = .default
    ) throws -> URL? {
        guard fileManager.fileExists(atPath: storeURL.path) else { return nil }

        // Make room first: on a nearly full disk the upgrade that follows needs the space more than a 4th copy.
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        try excludeFromDeviceBackup(directory)
        prune(directory, keep: max(0, keep - 1), fileManager: fileManager)

        let folder = directory.appendingPathComponent(folderName(for: now), isDirectory: true)
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        do {
            for sidecar in sidecars {
                let source = URL(fileURLWithPath: storeURL.path + sidecar)
                guard fileManager.fileExists(atPath: source.path) else { continue }
                try fileManager.copyItem(at: source, to: folder.appendingPathComponent(storeURL.lastPathComponent + sidecar))
            }
        } catch {
            do {
                try fileManager.removeItem(at: folder)
            } catch let cleanupError {
                persistenceLogger.error("❌ Could not remove half-made store copy: \(cleanupError.localizedDescription)")
            }
            throw error
        }
        return folder
    }

    /// The live store is already in the iCloud/device backup; three more copies of it would only fill the cook's
    /// iCloud. These are on-phone rollback points.
    private static func excludeFromDeviceBackup(_ directory: URL) throws {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var url = directory
        try url.setResourceValues(values)
    }

    /// Settings → Reset: removes every safety copy in `backupDirectory` and every set-aside copy of the store beside
    /// `storeURL`, so an erased library leaves no old copies of itself on the phone. Other files are left alone. Tries
    /// every copy, then throws the first failure.
    static func removeAllCopies(storeURL: URL, backupDirectory: URL?, fileManager: FileManager = .default) throws {
        var firstError: Error?
        func remove(names prefix: String, in folder: URL) {
            guard fileManager.fileExists(atPath: folder.path) else { return }
            do {
                for name in try fileManager.contentsOfDirectory(atPath: folder.path) where name.hasPrefix(prefix) {
                    do {
                        try fileManager.removeItem(at: folder.appendingPathComponent(name))
                    } catch {
                        if firstError == nil { firstError = error }
                    }
                }
            } catch {
                if firstError == nil { firstError = error }
            }
        }
        if let backupDirectory { remove(names: folderPrefix, in: backupDirectory) }
        remove(names: storeURL.lastPathComponent + setAsideMarker, in: storeURL.deletingLastPathComponent())
        if let firstError { throw firstError }
    }

    /// `store-<ms since 1970, zero-padded>-<random>`: names sort in time order, and two copies in the same
    /// millisecond don't collide.
    static func folderName(for date: Date) -> String {
        let milliseconds = max(0, Int64((date.timeIntervalSince1970 * 1000).rounded(.down)))
        let stamp = String(milliseconds)
        let padded = String(repeating: "0", count: max(0, 15 - stamp.count)) + stamp
        return folderPrefix + padded + "-" + String(UUID().uuidString.prefix(8))
    }

    /// Deletes all but the newest `keep` backup folders; anything else in the directory is left alone. A failed
    /// delete is logged, not thrown — it mustn't stop the new copy being made.
    private static func prune(_ directory: URL, keep: Int, fileManager: FileManager) {
        do {
            let folders = try fileManager.contentsOfDirectory(atPath: directory.path)
                .filter { $0.hasPrefix(folderPrefix) }
                .sorted()
            for name in folders.dropLast(keep) {
                try fileManager.removeItem(at: directory.appendingPathComponent(name))
            }
        } catch {
            persistenceLogger.error("❌ Could not prune old store copies: \(error.localizedDescription)")
        }
    }
}
