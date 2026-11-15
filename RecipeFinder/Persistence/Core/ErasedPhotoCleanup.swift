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

    /// Photo rows and every own photo a recipe in the store shows (`RecipePhotoSync.syncablePath`). Throws rather
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
                if let path = RecipePhotoSync.syncablePath(reference) { paths.insert(path) }
            }
        }
        return StoreView(photoRows: rows, referencedPaths: paths)
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
            guard let modified = try fileManager.attributesOfItem(atPath: url.path)[.modificationDate] as? Date,
                  modified < cutoff else { continue }
            try fileManager.removeItem(at: url)
            removed += 1
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
