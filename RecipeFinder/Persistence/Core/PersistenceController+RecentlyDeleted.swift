import CoreData
import Foundation

/// Recently Deleted (Data safety 4/4): deleting a recipe stamps `deletedAt` on its row instead of removing it, so with
/// iCloud sync on the delete reaches other devices as an ordinary change and a restore (clearing it) does too. Every
/// library read skips stamped rows (`inLibraryPredicate`). The row really goes when the cook deletes it from Recently
/// Deleted or `RecentlyDeleted.keptFor` has passed; its photos go with it (`RecipeStore.deleteForever`).
extension PersistenceController {

    /// Moves every row with `id` that's in the library to Recently Deleted. Returns false when nothing was moved.
    @discardableResult
    func moveRecipeToRecentlyDeleted(withId id: UUID, at date: Date = Date()) -> Bool {
        updateRows(withId: id, matching: Self.inLibraryPredicate, deletedAt: date, action: "move to Recently Deleted")
    }

    /// Puts every recently deleted row with `id` back in the library. Returns false when there was none.
    @discardableResult
    func restoreRecentlyDeletedRecipe(withId id: UUID) -> Bool {
        updateRows(withId: id, matching: Self.recentlyDeletedPredicate, deletedAt: nil, action: "restore")
    }

    /// The recipes in Recently Deleted, one per id, newest delete first. Empty if the store can't be read — nothing is
    /// ever removed on the strength of an empty list.
    func fetchRecentlyDeletedRecipes() -> [DeletedRecipe] {
        guard ensureStoreIsReady() else { return [] }
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
        request.predicate = Self.recentlyDeletedPredicate
        do {
            let items = try container.viewContext.fetch(request).compactMap { object -> DeletedRecipe? in
                guard let deletedAt = object.value(forKey: RecipeKey.deletedAt) as? Date,
                      let recipe = Self.mapToRecipeModel(object) else { return nil }
                return DeletedRecipe(recipe: recipe, deletedAt: deletedAt)
            }
            return RecentlyDeleted.oneEach(items)
        } catch {
            persistenceLogger.error("❌ Failed to fetch recently deleted recipes: \(error.localizedDescription)")
            return []
        }
    }

    /// Removes for good the rows with `id` that are in Recently Deleted (deleted before `cutoff`, when given). A copy
    /// of the same recipe still in the library is left alone. Returns whether a row went.
    @discardableResult
    func deleteRecentlyDeletedRecipe(withId id: UUID, deletedBefore cutoff: Date? = nil) -> Bool {
        guard ensureStoreIsReady() else { return false }
        let context = container.viewContext
        var conditions = [Self.recipeIdPredicate(id), Self.recentlyDeletedPredicate]
        if let cutoff {
            conditions.append(NSPredicate(format: "%K < %@", RecipeKey.deletedAt, cutoff as NSDate))
        }
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: conditions)
        do {
            let rows = try context.fetch(request)
            guard !rows.isEmpty else { return false }
            for row in rows { context.delete(row) }
            try context.save()
            return true
        } catch {
            context.rollback()
            persistenceLogger.error("❌ Failed to delete a recently deleted recipe: \(error.localizedDescription)")
            return false
        }
    }

    nonisolated static var recentlyDeletedPredicate: NSPredicate {
        NSPredicate(format: "%K != nil", RecipeKey.deletedAt)
    }

    private func updateRows(withId id: UUID, matching filter: NSPredicate, deletedAt: Date?, action: String) -> Bool {
        guard ensureStoreIsReady() else { return false }
        let context = container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
        // Every matching row: with iCloud sync on, another device's copy may not be merged yet.
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [Self.recipeIdPredicate(id), filter])
        do {
            let rows = try context.fetch(request)
            guard !rows.isEmpty else {
                persistenceLogger.debug("⚠️ No recipe \(id) to \(action)")
                return false
            }
            for row in rows { row.setValue(deletedAt, forKey: RecipeKey.deletedAt) }
            try context.save()
            return true
        } catch {
            context.rollback()
            persistenceLogger.error("❌ Failed to \(action) recipe: \(error.localizedDescription)")
            return false
        }
    }
}
