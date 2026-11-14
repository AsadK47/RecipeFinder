import CoreData
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
