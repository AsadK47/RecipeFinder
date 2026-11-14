import CoreData
import Foundation

/// Database maintenance.
extension PersistenceController {

    /// Settings → Reset: every recipe, and the iCloud copies of their photos (`RecipePhotoSync`), so an erased
    /// library's photos don't come back from iCloud as files on this or another device. Returns whether it worked, so
    /// Reset keeps the photo files of a library it couldn't erase.
    @discardableResult
    func deleteAllRecipes() -> Bool {
        guard ensureStoreIsReady() else { return false }

        let context = container.viewContext
        do {
            // Photos first: if that fails, the recipes (and the cook's library) are left whole.
            for entityName in [RecipePhotoSync.entityName, Entity.recipe] {
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
            return true
        } catch {
            persistenceLogger.error("❌ Failed to delete all recipes: \(error.localizedDescription)")
            return false
        }
    }
}
