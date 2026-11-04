import CoreData
import Foundation

/// Database maintenance.
extension PersistenceController {

    func deleteAllRecipes() {
        guard ensureStoreIsReady() else { return }

        let context = container.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: Entity.recipe)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs

        do {
            // Batch deletes bypass the context, so merge the deleted IDs or in-memory objects go stale.
            let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
            if let ids = result?.result as? [NSManagedObjectID] {
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: ids], into: [context])
            }
            try context.save()
            persistenceLogger.debug("✅ All recipes deleted")
        } catch {
            persistenceLogger.error("❌ Failed to delete all recipes: \(error.localizedDescription)")
        }
    }
}
