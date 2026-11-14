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
    /// An unreadable history counts as no change: the next launch shows the other device's edits anyway, and
    /// guessing "changed" could reload over and over.
    func takeOutsideChanges() -> Bool {
        let request = NSPersistentHistoryChangeRequest.fetchHistory(after: lastHistoryToken)
        do {
            let result = try container.viewContext.execute(request) as? NSPersistentHistoryResult
            let transactions = result?.result as? [NSPersistentHistoryTransaction] ?? []
            if let last = transactions.last { lastHistoryToken = last.token }
            let appEntities = Set(container.managedObjectModel.entitiesByName.keys)
            return transactions.contains { transaction in
                transaction.author != nil && (transaction.changes ?? []).contains { change in
                    appEntities.contains(change.changedObjectID.entity.name ?? "")
                }
            }
        } catch {
            persistenceLogger.error("❌ Couldn't read store history: \(error.localizedDescription)")
            return false
        }
    }
}

extension PersistenceController {
    /// Folds copies of the same recipe that iCloud brought together into one (`RecipeCopyMerge`). Only while the
    /// store syncs: without iCloud there are no record names to agree on. Returns whether the store changed.
    func mergeSyncedRecipeCopies() -> Bool {
        guard isSyncing, let cloudContainer = container as? NSPersistentCloudKitContainer else { return false }
        let context = container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
        do {
            let objects = try context.fetch(request)
            let ids = objects.compactMap { $0.value(forKey: RecipeKey.id) as? UUID }
            let repeated = Set(Dictionary(grouping: ids, by: { $0 }).filter { $0.value.count > 1 }.keys)
            guard !repeated.isEmpty else { return false }

            var byRecordName: [String: NSManagedObject] = [:]
            var copies: [RecipeCopyMerge.Copy] = []
            for object in objects {
                guard let id = object.value(forKey: RecipeKey.id) as? UUID, repeated.contains(id),
                      let model = Self.mapToRecipeModel(object) else { continue }
                let recordName = cloudContainer.recordID(for: object.objectID)?.recordName
                if let recordName { byRecordName[recordName] = object }
                copies.append(RecipeCopyMerge.Copy(recordName: recordName, recipe: model))
            }
            let plan = RecipeCopyMerge.plan(copies)
            guard !plan.isEmpty else { return false }
            for (recordName, merged) in plan.update {
                // A copy is only deleted once what it adds is safely on the kept one.
                guard let object = byRecordName[recordName],
                      Self.populate(object, from: RecipeSaveParameters(from: merged)) else {
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
            persistenceLogger.error("❌ Couldn't merge recipe copies from iCloud: \(error.localizedDescription)")
            return false
        }
    }
}
