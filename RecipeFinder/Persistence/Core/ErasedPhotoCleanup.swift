import CoreData
import Foundation

private let logger = AppLogger.logger(category: "ErasedPhotoCleanup")

/// A Reset on another device (iCloud sync on) erases the recipes and their photo rows everywhere, but `RecipePhotoSync`
/// never deletes files, so this device kept the cook's photo files. They go when the signal is strong: the store file
/// this device has seen photo rows in now holds none, and no recipe in it shows one of the cook's photos. Never
/// inferred from a single missing row or file (rejected in 4b-2a): a new store file (recovery, first import), a
/// recipe still pointing at a photo, or an unreadable store all keep every file.
enum ErasedPhotoCleanup {
    /// The store file this device last saw photo rows in.
    static let rememberedFileKey = "syncedStoreFile.recipePhotos"

    struct StoreView: Equatable, Sendable {
        var photoRows: Int
        var referencedPaths: Set<String>
    }

    enum Step: Equatable {
        case remember(String)
        case clear
        case nothing
    }

    static func step(store: StoreView?, storeFile: String?, remembered: String?) -> Step {
        guard let store, let storeFile else { return .nothing }
        if store.photoRows > 0 { return storeFile == remembered ? .nothing : .remember(storeFile) }
        guard store.referencedPaths.isEmpty, storeFile == remembered else { return .nothing }
        return .clear
    }

    /// One check after a load: remembers the store file, or clears the photo files of a library erased elsewhere
    /// (only files iCloud has had, see `deleteBefore`). The file is forgotten after a clear so it runs once; a folder
    /// that couldn't be read throws and keeps it for the next load. Returns how many files went.
    @discardableResult
    static func follow(
        store: StoreView?, storeFile: String?, checkedAt: Date, storage: LocalStore, documents: URL,
        fileManager: FileManager = .default
    ) throws -> Int {
        switch step(store: store, storeFile: storeFile, remembered: storage.string(forKey: rememberedFileKey)) {
        case .remember(let storeFile):
            storage.set(storeFile, forKey: rememberedFileKey)
            return 0
        case .nothing:
            return 0
        case .clear:
            let lastExport = HistoryPurgeRule.lastExportStart(in: storage)
            var removed = 0
            if let before = deleteBefore(checkedAt: checkedAt, lastExportStart: lastExport) {
                removed = try removeFiles(in: documents, keeping: [], modifiedBefore: before, fileManager: fileManager)
            }
            storage.removeObject(forKey: rememberedFileKey)
            return removed
        }
    }

    /// A photo's row is saved by the photo pass a little after its file; an export that started in between didn't
    /// carry it.
    static let exportMargin: TimeInterval = 10 * 60

    /// Files written before this date may go; nil keeps them all. Only photos iCloud has had (written well before
    /// the last finished export) are deleted: an iCloud sign-out purges the store file just like a Reset elsewhere,
    /// and a photo that never reached iCloud (iCloud full, offline) would then be gone for good when the recipes
    /// come back. `checkedAt` keeps a photo saved while the check ran.
    static func deleteBefore(checkedAt: Date, lastExportStart: Date?) -> Date? {
        guard let lastExportStart else { return nil }
        return min(checkedAt, lastExportStart.addingTimeInterval(-exportMargin))
    }

    /// Photo rows and every own photo a recipe in the store shows (`photoFilePath`). Throws rather
    /// than reading a failed fetch as "no photos". Call on `context`'s queue.
    static func storeView(in context: NSManagedObjectContext) throws -> StoreView {
        let rows = try context.count(for: NSFetchRequest<NSManagedObject>(entityName: RecipePhotoSync.entityName))
        let request = NSFetchRequest<NSManagedObject>(entityName: PersistenceController.Entity.recipe)
        request.propertiesToFetch = [PersistenceController.RecipeKey.imageName, PersistenceController.RecipeKey.photoNames]
        var paths: Set<String> = []
        for recipe in try context.fetch(request) {
            let hero = recipe.value(forKey: PersistenceController.RecipeKey.imageName) as? String
            let gallery = recipe.value(forKey: PersistenceController.RecipeKey.photoNames) as? [String] ?? []
            for reference in [hero].compactMap({ $0 }) + gallery {
                if let path = photoFilePath(reference) { paths.insert(path) }
            }
        }
        return StoreView(photoRows: rows, referencedPaths: paths)
    }

    /// The photo-folder file a reference points at: `RecipeImages/<name>.jpg`, or an older build's absolute path to
    /// the same folder (never synced, but still a photo in use).
    static func photoFilePath(_ reference: String) -> String? {
        if let path = RecipePhotoSync.syncablePath(reference) { return path }
        guard reference.hasPrefix("/") else { return nil }
        let url = URL(fileURLWithPath: reference)
        guard url.deletingLastPathComponent().lastPathComponent + "/" == RecipePhotoSync.folder else { return nil }
        return RecipePhotoSync.syncablePath(RecipePhotoSync.folder + url.lastPathComponent)
    }

    /// Deletes the cook's own photo files (not kept web copies or anything else) that `keeping` doesn't name and
    /// that were written before `cutoff` — a photo saved here while the check ran stays. Returns how many went.
    static func removeFiles(
        in documents: URL, keeping: Set<String>, modifiedBefore cutoff: Date, fileManager: FileManager = .default
    ) throws -> Int {
        let folder = documents.appendingPathComponent(RecipePhotoSync.folder, isDirectory: true)
        guard fileManager.fileExists(atPath: folder.path) else { return 0 }
        var removed = 0
        for name in try fileManager.contentsOfDirectory(atPath: folder.path) {
            let path = RecipePhotoSync.folder + name
            guard RecipePhotoSync.syncablePath(path) != nil, !keeping.contains(path) else { continue }
            let url = folder.appendingPathComponent(name)
            // One file that can't be read or removed (e.g. deleted by its recipe at the same moment) doesn't stop the rest.
            do {
                guard let modified = try fileManager.attributesOfItem(atPath: url.path)[.modificationDate] as? Date,
                      modified < cutoff else { continue }
                try fileManager.removeItem(at: url)
                removed += 1
            } catch {
                logger.error("❌ Couldn't remove an erased photo: \(error.localizedDescription)")
            }
        }
        return removed
    }
}

extension PersistenceController {
    /// What the synced store holds of the cook's photos; nil when it isn't syncing or couldn't be read.
    func photoUseInSyncedStore() async -> ErasedPhotoCleanup.StoreView? {
        guard isSyncing else { return nil }
        let container = self.container
        return await withCheckedContinuation { continuation in
            container.performBackgroundTask { context in
                do {
                    continuation.resume(returning: try ErasedPhotoCleanup.storeView(in: context))
                } catch {
                    logger.error("❌ Couldn't read which photos the store holds: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
