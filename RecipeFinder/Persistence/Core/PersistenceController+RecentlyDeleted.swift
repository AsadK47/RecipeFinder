import CoreData
import Foundation

/// Recently Deleted (Data safety 4/4): deleting a recipe stamps `deletedAt` on its row instead of removing it, so with
/// iCloud sync on the delete reaches other devices as an ordinary change and a restore (clearing it) does too. Every
/// library read skips stamped rows (`inLibraryPredicate`). The row really goes when the cook deletes it from Recently
/// Deleted or the purge allows it (`RecentlyDeleted.mayPurge`); its photos go with it (`RecipeStore+RecentlyDeleted`).
extension PersistenceController {

    /// What a load of Recently Deleted found: what's left in it, and the recipes it removed for good whose id no
    /// row holds any more (their photos can go).
    struct RecentlyDeletedLoad: Sendable {
        var trash: [DeletedRecipe] = []
        var purged: [RecipeModel] = []
        /// False when the store couldn't be read: `trash` is then empty for want of knowing, not because it is.
        var wasRead = true
    }

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
        do {
            return RecentlyDeleted.oneEach(try Self.deletedItems(in: container.viewContext))
        } catch {
            persistenceLogger.error("❌ Failed to fetch recently deleted recipes: \(error.localizedDescription)")
            return []
        }
    }

    /// Reads Recently Deleted off the main thread and, when `sync` is given, first removes for good every recipe
    /// `RecentlyDeleted.mayPurge` allows — all its stamped rows together, judged by the latest stamp, so a duplicate
    /// row can't outlive the photos removed with the others.
    func loadRecentlyDeleted(now: Date = Date(), purgingWith sync: RecentlyDeleted.SyncState?) async -> RecentlyDeletedLoad {
        guard ensureStoreIsReady() else { return RecentlyDeletedLoad(wasRead: false) }
        let container = self.container
        return await withCheckedContinuation { continuation in
            container.performBackgroundTask { context in
                continuation.resume(returning: Self.loadRecentlyDeleted(in: context, now: now, purgingWith: sync))
            }
        }
    }

    /// Removes for good every stamped row with `id` (a copy of the same recipe still in the library is left alone).
    /// Returns whether a row went.
    @discardableResult
    func deleteRecentlyDeletedRecipe(withId id: UUID) -> Bool {
        guard ensureStoreIsReady() else { return false }
        let context = container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            Self.recipeIdPredicate(id), Self.recentlyDeletedPredicate,
        ])
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

    /// How many rows (library or Recently Deleted) hold `id`; nil when the store can't say. Photos go only at 0.
    func recipeRowCount(withId id: UUID) -> Int? {
        guard ensureStoreIsReady() else { return nil }
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
        request.predicate = Self.recipeIdPredicate(id)
        do {
            return try container.viewContext.count(for: request)
        } catch {
            persistenceLogger.error("❌ Failed to count recipe rows: \(error.localizedDescription)")
            return nil
        }
    }

    nonisolated static var recentlyDeletedPredicate: NSPredicate {
        NSPredicate(format: "%K != nil", RecipeKey.deletedAt)
    }

    /// Every stamped row as an item (duplicates included). Call on `context`'s queue.
    nonisolated private static func deletedItems(in context: NSManagedObjectContext) throws -> [DeletedRecipe] {
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
        request.predicate = recentlyDeletedPredicate
        return try context.fetch(request).compactMap { object -> DeletedRecipe? in
            guard let deletedAt = object.value(forKey: RecipeKey.deletedAt) as? Date,
                  let recipe = mapToRecipeModel(object) else { return nil }
            return DeletedRecipe(recipe: recipe, deletedAt: deletedAt)
        }
    }

    /// Call on `context`'s queue. A failed read or save purges nothing.
    nonisolated private static func loadRecentlyDeleted(
        in context: NSManagedObjectContext, now: Date, purgingWith sync: RecentlyDeleted.SyncState?
    ) -> RecentlyDeletedLoad {
        let items: [DeletedRecipe]
        do {
            items = try deletedItems(in: context)
        } catch {
            persistenceLogger.error("❌ Failed to read recently deleted recipes: \(error.localizedDescription)")
            return RecentlyDeletedLoad(wasRead: false)
        }
        let latest = RecentlyDeleted.oneEach(items)
        guard let sync else { return RecentlyDeletedLoad(trash: latest) }
        let due = latest.filter { RecentlyDeleted.mayPurge(deletedAt: $0.deletedAt, now: now, sync: sync) }
        guard !due.isEmpty else { return RecentlyDeletedLoad(trash: latest) }
        let dueIDs = Set(due.map(\.id))
        do {
            let request = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "%K IN %@", RecipeKey.id, Array(dueIDs) as NSArray), recentlyDeletedPredicate,
            ])
            for row in try context.fetch(request) { context.delete(row) }
            try context.save()
            // Photos go only for ids no row holds any more (a library copy of the same recipe keeps them).
            var gone: [RecipeModel] = []
            for item in due {
                let left = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
                left.predicate = recipeIdPredicate(item.id)
                if try context.count(for: left) == 0 { gone.append(item.recipe) }
            }
            persistenceLogger.info("Removed \(due.count) recipes from Recently Deleted after 30 days")
            return RecentlyDeletedLoad(trash: latest.filter { !dueIDs.contains($0.id) }, purged: gone)
        } catch {
            context.rollback()
            persistenceLogger.error("❌ Failed to remove old recently deleted recipes: \(error.localizedDescription)")
            return RecentlyDeletedLoad(trash: latest)
        }
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
