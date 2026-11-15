import CoreData
import CloudKit
import Foundation

/// Spotting edits that arrived from another device (Data safety 2/4). The store posts a remote-change notification
/// for every write, this app's own included, so its history says who wrote what: this app never names its writes,
/// and CloudKit's importer always does.
extension PersistenceController {
    /// Starts reading history from now: changes already in the store are already on screen.
    func startTrackingOutsideChanges() {
        lastHistoryToken = container.persistentStoreCoordinator.currentPersistentHistoryToken(fromStores: nil)
    }

    /// Whether anything outside this app changed the app's data since the last call; moves the checkpoint on.
    /// Read on a background context: during a first iCloud import the history since the checkpoint is thousands of
    /// transactions, too many to read on the main thread (issue #16). Calls run one after another, so two
    /// overlapping checks never both report the same change or move the checkpoint back.
    /// An unreadable history counts as no change: the next launch shows the other device's edits anyway, and
    /// guessing "changed" could reload over and over.
    /// `reader` is the history read; tests wrap it to see where it runs.
    func takeOutsideChanges(
        reader: @escaping @Sendable (HistoryCheckpoint, Set<String>, NSManagedObjectContext) -> HistoryReading
            = PersistenceController.readHistory
    ) async -> Bool {
        let previous = outsideChangeCheck
        let check = Task { () -> Bool in
            _ = await previous?.value
            return await readOutsideChanges(with: reader)
        }
        outsideChangeCheck = check
        return await check.value
    }

    private func readOutsideChanges(
        with reader: @escaping @Sendable (HistoryCheckpoint, Set<String>, NSManagedObjectContext) -> HistoryReading
    ) async -> Bool {
        let container = self.container
        let after = HistoryCheckpoint(token: lastHistoryToken)
        let appEntities = Set(container.managedObjectModel.entitiesByName.keys)
        let reading = await withCheckedContinuation { (continuation: CheckedContinuation<HistoryReading, Never>) in
            container.performBackgroundTask { context in
                continuation.resume(returning: reader(after, appEntities, context))
            }
        }
        switch reading {
        case .read(let latest, let changed):
            if let latest = latest.token { lastHistoryToken = latest }
            return changed
        case .expired:
            // The checkpoint was purged (`purgeHistory`): what fell in between can't be read, so reload once and
            // read on from now.
            startTrackingOutsideChanges()
            return true
        case .failed(let message):
            persistenceLogger.error("❌ Couldn't read store history: \(message)")
            return false
        }
    }

    /// Call on `context`'s queue.
    nonisolated static func readHistory(
        after checkpoint: HistoryCheckpoint, appEntities: Set<String>, in context: NSManagedObjectContext
    ) -> HistoryReading {
        let request = NSPersistentHistoryChangeRequest.fetchHistory(after: checkpoint.token)
        do {
            let result = try context.execute(request) as? NSPersistentHistoryResult
            let transactions = result?.result as? [NSPersistentHistoryTransaction] ?? []
            let changed = transactions.contains { transaction in
                transaction.author != nil && (transaction.changes ?? []).contains { change in
                    appEntities.contains(change.changedObjectID.entity.name ?? "")
                }
            }
            return .read(latest: HistoryCheckpoint(token: transactions.last?.token), changed: changed)
        } catch {
            if (error as NSError).code == NSPersistentHistoryTokenExpiredError { return .expired }
            return .failed(error.localizedDescription)
        }
    }
}

/// A history token carried between the main actor and a background context. Tokens are immutable once made.
struct HistoryCheckpoint: @unchecked Sendable {
    let token: NSPersistentHistoryToken?
}

enum HistoryReading: Sendable {
    /// `latest` is nil when nothing new was written.
    case read(latest: HistoryCheckpoint, changed: Bool)
    case expired
    case failed(String)
}

/// Store history grows with every save, sync on or off; once CloudKit has sent it, nothing needs more than a few days
/// of it. A week matches Apple's CloudKit sample; `HistoryPurgeRule` says when the purge may run. After a week with no writes the launch purge can remove `takeOutsideChanges()`'s
/// checkpoint (the latest transaction), costing one extra reload of every list — accepted.
extension PersistenceController {
    nonisolated static let historyKeptFor: TimeInterval = 7 * 24 * 60 * 60

    nonisolated static func historyPurgeCutoff(now: Date) -> Date {
        now.addingTimeInterval(-historyKeptFor)
    }

    /// Deletes store history written before `cutoff`, off the main thread; the data itself is untouched.
    /// Returns whether the purge ran. A failure is logged and left for the next launch.
    @discardableResult
    func purgeHistory(before cutoff: Date) async -> Bool {
        guard ensureStoreIsReady() else { return false }
        let container = self.container
        return await withCheckedContinuation { continuation in
            container.performBackgroundTask { context in
                do {
                    _ = try context.execute(NSPersistentHistoryChangeRequest.deleteHistory(before: cutoff))
                    continuation.resume(returning: true)
                } catch {
                    persistenceLogger.error("❌ Couldn't purge store history: \(error.localizedDescription)")
                    continuation.resume(returning: false)
                }
            }
        }
    }
}

/// How far back the launch purge may reach (Inbox 🔴 2026-11-14). CloudKit sends a mirrored store's changes from its
/// history, and a purge that outruns it loses deletes (the mirror resets and re-sends what's left; deleted rows come
/// back from iCloud). So once sync has been on here, only history written before the last export CloudKit finished is
/// purged — sync off, paused, signed out or iCloud full all leave newer history in place. A device that never synced
/// has no one to send it to. Accepted: history grows while nothing exports.
enum HistoryPurgeRule {
    /// Start of the newest export CloudKit reported as finished; everything saved before it has been sent.
    static let lastExportKey = "iCloudLastExportStart"

    /// The date to purge history before, or nil to keep all of it.
    static func cutoff(now: Date, everSynced: Bool, lastExportStart: Date?) -> Date? {
        let cutoff = PersistenceController.historyPurgeCutoff(now: now)
        guard everSynced else { return cutoff }
        guard let lastExportStart else { return nil }
        return min(cutoff, lastExportStart)
    }

    static func cutoff(now: Date, in storage: LocalStore) -> Date? {
        cutoff(now: now, everSynced: SyncPreference.hasEverSynced(in: storage), lastExportStart: lastExportStart(in: storage))
    }

    static func lastExportStart(in storage: LocalStore) -> Date? {
        storage.object(forKey: lastExportKey) == nil
            ? nil
            : Date(timeIntervalSinceReferenceDate: storage.double(forKey: lastExportKey))
    }

    /// When a CloudKit event proves history up to a point was sent: a finished, successful export, by its start.
    static func sentUpTo(isExport: Bool, succeeded: Bool, startDate: Date, endDate: Date?) -> Date? {
        isExport && succeeded && endDate != nil ? startDate : nil
    }

    /// Keeps the newest finished export; an older one reported late doesn't move it back.
    static func recordExport(startedAt start: Date, in storage: LocalStore) {
        if let known = lastExportStart(in: storage), known >= start { return }
        storage.set(start.timeIntervalSinceReferenceDate, forKey: lastExportKey)
    }
}

extension PersistenceController {
    /// Folds copies of the same recipe that iCloud brought together into one (`RecipeCopyMerge`). Only while the
    /// store syncs: without iCloud there are no record names to agree on. `ids` are the recipes the last fetch held
    /// more than once, so a library without copies costs nothing. Runs on a background context: on a first sync
    /// every built-in recipe is held twice, and this runs after each iCloud import burst (issue #16). Returns
    /// whether the store changed.
    func mergeSyncedRecipeCopies(of ids: Set<UUID>) async -> Bool {
        guard !ids.isEmpty, isSyncing, let cloudContainer = container as? NSPersistentCloudKitContainer else { return false }
        let previous = copyMerge
        let pass = Task { () -> Bool in
            _ = await previous?.value
            return await Self.mergeInBackground(ids, in: cloudContainer)
        }
        copyMerge = pass
        return await pass.value
    }

    nonisolated private static func mergeInBackground(
        _ ids: Set<UUID>, in cloudContainer: NSPersistentCloudKitContainer
    ) async -> Bool {
        await withCheckedContinuation { continuation in
            cloudContainer.performBackgroundTask { context in
                let merged = Self.mergeRecipeCopies(of: ids, in: context) { objectIDs in
                    cloudContainer.recordIDs(for: objectIDs).mapValues(\.recordName)
                }
                continuation.resume(returning: merged)
            }
        }
    }

    /// The merge itself, given each row's iCloud record name (`recordNames`, asked after the rows are read; a row
    /// without one waits for a later pass). Call on `context`'s queue.
    ///
    /// Saved with optimistic locking (`NSMergePolicy.error`): if the cook edits, rates or cooks one of these recipes,
    /// or iCloud updates it, between this pass reading the rows and saving, the save fails and is rolled back — the
    /// edit stands and the next load merges again. A merge-wins policy would write the kept row back over the edit,
    /// and the copy it deletes may hold the edit too.
    nonisolated static func mergeRecipeCopies(
        of ids: Set<UUID>,
        in context: NSManagedObjectContext,
        recordNames: ([NSManagedObjectID]) -> [NSManagedObjectID: String]
    ) -> Bool {
        context.mergePolicy = NSMergePolicy.error
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
        // Library rows only: a copy in Recently Deleted is never folded into (or chosen over) one the cook still has.
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "%K IN %@", RecipeKey.id, Array(ids) as NSArray), Self.inLibraryPredicate,
        ])
        do {
            let objects = try context.fetch(request)
            let names = recordNames(objects.map { $0.objectID })
            var byRecordName: [String: NSManagedObject] = [:]
            var copies: [RecipeCopyMerge.Copy] = []
            for object in objects {
                guard let model = mapToRecipeModel(object) else { continue }
                let recordName = names[object.objectID]
                if let recordName { byRecordName[recordName] = object }
                copies.append(RecipeCopyMerge.Copy(recordName: recordName, recipe: model))
            }
            let plan = RecipeCopyMerge.plan(copies)
            guard !plan.isEmpty else { return false }
            for (recordName, merged) in plan.update {
                // A copy is only deleted once what it adds is safely on the kept one.
                guard let object = byRecordName[recordName],
                      populate(object, from: RecipeSaveParameters(from: merged)) else {
                    context.rollback()
                    return false
                }
            }
            for recordName in plan.delete {
                if let object = byRecordName[recordName] { context.delete(object) }
            }
            try context.save()
            persistenceLogger.info("Merged \(plan.delete.count) recipe copies from iCloud")
            return true
        } catch {
            context.rollback()
            if Self.isSaveConflict(error) {
                persistenceLogger.info("Recipe copies changed while merging; merging again on the next load")
            } else {
                persistenceLogger.error("❌ Couldn't merge recipe copies from iCloud: \(error.localizedDescription)")
            }
            return false
        }
    }

    /// Optimistic-locking failures: another save changed or deleted a row this context had read.
    nonisolated static func isSaveConflict(_ error: Error) -> Bool {
        let error = error as NSError
        return error.domain == NSCocoaErrorDomain
            && [NSManagedObjectMergeError, NSPersistentStoreSaveConflictsError].contains(error.code)
    }
}
