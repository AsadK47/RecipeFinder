import CoreData
import Foundation

/// Database maintenance.
extension PersistenceController {

    /// Settings → Reset: every recipe, and the iCloud copies of their photos (`RecipePhotoSync`), so an erased
    /// library's photos don't come back from iCloud as files on this or another device.
    func deleteAllRecipes() {
        guard ensureStoreIsReady() else { return }

        let context = container.viewContext
        do {
            for entityName in [Entity.recipe, RecipePhotoSync.entityName] {
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                deleteRequest.resultType = .resultTypeObjectIDs
                // Batch deletes bypass the context, so merge the deleted IDs or in-memory objects go stale.
                let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
                if let ids = result?.result as? [NSManagedObjectID] {
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: ids], into: [context])
                }
            }
            try context.save()
            persistenceLogger.debug("✅ All recipes deleted")
        } catch {
            persistenceLogger.error("❌ Failed to delete all recipes: \(error.localizedDescription)")
        }
    }
}
