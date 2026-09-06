import CoreData
import Foundation

/// Database maintenance: clearing and resetting the current user's recipes.
extension PersistenceController {

    func clearDatabase() {
        guard ensureStoreIsReady() else { return }
        
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: Entity.recipe)
        
        if let userId = userID() {
            fetchRequest.predicate = NSPredicate(format: "userId == %@", userId)
        } else {
            persistenceLogger.debug("⚠️ No user logged in, skipping database clear to protect other users' data")
            return
        }
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
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
