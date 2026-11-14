import CoreData
import Foundation

private let logger = AppLogger.logger(category: "RecipePhotoSync")

/// Carries the cook's recipe photos over iCloud sync (Data safety 2/4 slice 4b). Photos live as files under
/// `Documents/RecipeImages/` and recipes point at them by relative path, so CloudKit — which only syncs the store —
/// never saw them. Each photo file is copied into a `RecipePhotoEntity` row (path + JPEG, external storage, so
/// CloudKit sends it as an asset), and rows that arrive from another device are written back to the same path.
/// Newer wins per photo path; nothing here deletes a file or a recipe.
enum RecipePhotoSync {
    static let entityName = "RecipePhotoEntity"
    static let folder = "RecipeImages/"
    /// Far above a 1600px JPEG; a larger row isn't a photo this app wrote.
    static let maxBytes = 20 * 1024 * 1024
    /// Rows saved per batch, so a big library never holds every photo in memory at once.
    static let batchSize = 8

    struct Outcome: Equatable, Sendable {
        var uploaded = 0
        var downloaded = 0
    }

    /// `reference` when it's one of the cook's own photo files (`RecipeImages/<name>.jpg`); nil for web URLs, kept
    /// copies of web pictures (re-downloadable from the URL the recipe keeps), legacy absolute paths, and anything
    /// that could leave the photo folder. Also the guard on paths arriving from another device.
    static func syncablePath(_ reference: String) -> String? {
        guard reference.hasPrefix(folder) else { return nil }
        let name = reference.dropFirst(folder.count)
        guard name.count > ".jpg".count, name.hasSuffix(".jpg"), !name.hasPrefix("."), !name.hasPrefix("web-"),
              !name.contains("/"), !name.contains("..") else { return nil }
        return reference
    }

    /// Every own photo file the library points at (hero + gallery).
    static func referencedPaths(in recipes: [RecipeModel]) -> Set<String> {
        var paths: Set<String> = []
        for recipe in recipes {
            for reference in [recipe.imageName].compactMap({ $0 }) + recipe.photoNames {
                if let path = syncablePath(reference) { paths.insert(path) }
            }
        }
        return paths
    }

    /// One pass both ways, per photo path: newer wins. A file newer than its row (a new photo, or a hero replaced
    /// at the same path) is sent; a row newer than the file (or with no file here yet) is written to disk, stamped
    /// with the row's date so it isn't sent straight back. Call on `context`'s queue. Failures are logged per photo
    /// and the rest carry on; the next pass (next launch, iCloud change or save) retries what was missed.
    static func mirror(
        referencedPaths: Set<String>,
        in context: NSManagedObjectContext,
        documentsDirectory: URL,
        fileManager: FileManager = .default
    ) -> Outcome {
        let stored: [String: Date]
        do {
            stored = try storedDates(in: context)
        } catch {
            logger.error("❌ Couldn't read synced photos: \(error.localizedDescription)")
            return Outcome()
        }
        let files = Files(documents: documentsDirectory, fileManager: fileManager)
        var toSend: [String] = []
        for path in referencedPaths.sorted() where syncablePath(path) != nil {
            guard let modified = files.modified(path) else { continue }
            if let storedDate = stored[path], modified <= storedDate.addingTimeInterval(clockTolerance) { continue }
            toSend.append(path)
        }
        // Only photos a recipe here shows: a removed photo's row stays in iCloud until pruning (4b-2) and must not
        // come back as a file. A photo that arrives before its recipe is fetched on the reload the recipe brings.
        var toReceive: [String] = []
        for path in referencedPaths.sorted() where syncablePath(path) != nil {
            guard let storedDate = stored[path], needsReceiving(storedDate, files.modified(path)) else { continue }
            toReceive.append(path)
        }
        return Outcome(
            uploaded: upload(toSend, into: context, from: files),
            downloaded: download(toReceive, from: context, to: files)
        )
    }

    /// File dates and the stored dates round differently; closer than this counts as the same photo.
    static let clockTolerance: TimeInterval = 1

    /// A stored photo is written here when there's no file yet or the stored one is newer.
    private static func needsReceiving(_ storedDate: Date, _ modified: Date?) -> Bool {
        guard let modified else { return true }
        return storedDate > modified.addingTimeInterval(clockTolerance)
    }

    private struct Files {
        let documents: URL
        let fileManager: FileManager

        func url(_ path: String) -> URL { documents.appendingPathComponent(path) }

        /// nil when there's no file — the usual case for a photo another device took.
        func modified(_ path: String) -> Date? {
            (try? fileManager.attributesOfItem(atPath: url(path).path))?[.modificationDate] as? Date
        }
    }

    /// Newest date per stored path; a row without one counts as oldest (only fills a missing file).
    private static func storedDates(in context: NSManagedObjectContext) throws -> [String: Date] {
        let request = NSFetchRequest<NSDictionary>(entityName: entityName)
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = ["path", "updatedAt"]
        var dates: [String: Date] = [:]
        for row in try context.fetch(request) {
            guard let path = row["path"] as? String else { continue }
            let date = row["updatedAt"] as? Date ?? .distantPast
            dates[path] = max(dates[path] ?? .distantPast, date)
        }
        return dates
    }

    private static func rows(at path: String, in context: NSManagedObjectContext) throws -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.predicate = NSPredicate(format: "path == %@", path)
        return try context.fetch(request)
    }

    private static func upload(_ paths: [String], into context: NSManagedObjectContext, from files: Files) -> Int {
        var uploaded = 0
        var pending = 0
        for path in paths {
            guard let modified = files.modified(path),
                  let data = try? Data(contentsOf: files.url(path), options: .mappedIfSafe), isPhoto(data) else { continue }
            do {
                var targets = try rows(at: path, in: context)
                if targets.isEmpty {
                    let row = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
                    row.setValue(UUID(), forKey: "id")
                    row.setValue(path, forKey: "path")
                    targets = [row]
                }
                // Every copy of the row (two devices can add the same path) gets the new photo.
                for row in targets {
                    row.setValue(data, forKey: "data")
                    row.setValue(modified, forKey: "updatedAt")
                }
            } catch {
                logger.error("❌ Couldn't read a synced photo: \(error.localizedDescription)")
                continue
            }
            pending += 1
            if pending == batchSize {
                uploaded += save(context, count: pending)
                pending = 0
            }
        }
        if pending > 0 { uploaded += save(context, count: pending) }
        return uploaded
    }

    /// Saves a batch and drops it from memory; a failed batch is rolled back and retried next pass.
    private static func save(_ context: NSManagedObjectContext, count: Int) -> Int {
        defer { context.reset() }
        do {
            try context.save()
            return count
        } catch {
            logger.error("❌ Couldn't save \(count) photos for iCloud: \(error.localizedDescription)")
            context.rollback()
            return 0
        }
    }

    private static func download(_ paths: [String], from context: NSManagedObjectContext, to files: Files) -> Int {
        var downloaded = 0
        for path in paths {
            let found: [NSManagedObject]
            do {
                found = try rows(at: path, in: context)
            } catch {
                logger.error("❌ Couldn't read a synced photo: \(error.localizedDescription)")
                continue
            }
            defer { context.reset() }
            let newest = found.max { ($0.value(forKey: "updatedAt") as? Date ?? .distantPast)
                < ($1.value(forKey: "updatedAt") as? Date ?? .distantPast) }
            guard let row = newest, let data = row.value(forKey: "data") as? Data, isPhoto(data),
                  // Re-checked just before writing: the cook may have saved a new photo here since the pass began.
                  needsReceiving(row.value(forKey: "updatedAt") as? Date ?? .distantPast, files.modified(path))
            else { continue }
            let url = files.url(path)
            do {
                try files.fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try data.write(to: url, options: .atomic)
                if let date = row.value(forKey: "updatedAt") as? Date {
                    try files.fileManager.setAttributes([.modificationDate: date], ofItemAtPath: url.path)
                }
                downloaded += 1
            } catch {
                logger.error("❌ Couldn't write a synced photo: \(error.localizedDescription)")
            }
        }
        return downloaded
    }

    /// A JPEG of a sane size: what this app writes.
    private static func isPhoto(_ data: Data) -> Bool {
        data.count <= maxBytes && data.starts(with: [0xFF, 0xD8, 0xFF])
    }
}

extension PersistenceController {
    /// Mirrors the library's photos to and from iCloud on a background context while the store syncs; nil when it
    /// doesn't (photos stay files only, no second copy on disk).
    func mirrorRecipePhotos(referencedPaths: Set<String>, documentsDirectory: URL?) async -> RecipePhotoSync.Outcome? {
        guard isSyncing, let documentsDirectory else { return nil }
        let container = self.container
        return await withCheckedContinuation { continuation in
            container.performBackgroundTask { context in
                let outcome = RecipePhotoSync.mirror(
                    referencedPaths: referencedPaths, in: context, documentsDirectory: documentsDirectory
                )
                continuation.resume(returning: outcome)
            }
        }
    }
}
