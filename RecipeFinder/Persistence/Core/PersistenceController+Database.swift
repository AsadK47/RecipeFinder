import CoreData
import Foundation

/// Database maintenance: clearing and resetting the current user's recipes.
extension PersistenceController {

    func clearDatabase() {
        guard ensureStoreIsReady() else { return }
        
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: Entity.recipe)
        // nil userId = the guest's own scope (rows with userId == nil), so this never touches an account's recipes.
        fetchRequest.predicate = Self.ownerPredicate(userID())

        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs

        do {
            // Batch deletes bypass the context, so merge the deleted IDs or in-memory objects go stale.
            let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
            if let ids = result?.result as? [NSManagedObjectID] {
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: ids], into: [context])
            }
            try context.save()
            persistenceLogger.debug("✅ Database cleared successfully for current user")
        } catch {
            persistenceLogger.error("❌ Failed to clear database: \(error.localizedDescription)")
        }
    }
    
    func resetDatabase() {
        persistenceLogger.debug("🔄 Resetting database...")
        clearDatabase()
        UserScopedStorage.shared.set(false, forKey: Constants.UserDefaultsKeys.hasPopulatedDatabase)
        populateDatabase()
        UserScopedStorage.shared.set(true, forKey: Constants.UserDefaultsKeys.hasPopulatedDatabase)
        persistenceLogger.debug("✅ Database reset complete")
    }
    
    func clearAllRecipes() {
        clearDatabase()
    }
}
