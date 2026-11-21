import CoreData
import Foundation

/// Many-recipe writes: first-launch seeding and backup merge-restore. (`updateRecipesInBackground` moves here once
/// `agent/recently-deleted` lands — that branch edits it in `+RecipeWrites`.)
extension PersistenceController {

    /// Bulk-inserts starter recipes on a background context in one save so first launch doesn't freeze; skips
    /// per-recipe count/badge work by design. Returns `true` only if the save succeeded, so the caller can
    /// clear the "seeded" flag and retry next launch rather than strand the user with an empty library.
    @discardableResult
    func seedRecipes(_ models: [RecipeModel]) async -> Bool {
        guard ensureStoreIsReady() else { return false }
        let container = self.container
        return await withCheckedContinuation { continuation in
            container.performBackgroundTask { context in
                guard let entity = NSEntityDescription.entity(forEntityName: Entity.recipe, in: context) else {
                    persistenceLogger.error("❌ Failed to find Recipe entity while seeding")
                    continuation.resume(returning: false)
                    return
                }
                for model in models {
                    let object = NSManagedObject(entity: entity, insertInto: context)
                    _ = Self.populate(object, from: RecipeSaveParameters(from: model))
                }
                do {
                    try context.save()
                    persistenceLogger.debug("✅ Seeded \(models.count) starter recipes")
                    continuation.resume(returning: true)
                } catch {
                    persistenceLogger.error("❌ Failed to seed starter recipes: \(error.localizedDescription)")
                    continuation.resume(returning: false)
                }
            }
        }
    }

    /// Non-destructive restore: saves new recipes per `BackupMerge.mergedRecipesWithAdditions` (dedupes by id AND
    /// normalized name so re-imports don't duplicate) and restores user state (`BackupMerge.restoredUserState`) onto existing ones.
    func mergeRecipes(_ incoming: [RecipeModel]) {
        let existing = fetchRecipes()
        let added = BackupMerge.mergedRecipesWithAdditions(existing: existing, incoming: incoming).added
        let shipped = Dictionary(
            (SeedRecipeProvider.recipes + BundledRecipeCatalog.load()).map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let restored = BackupMerge.restoredUserState(existing: existing, incoming: incoming) { stored in
            guard stored.isSampleRecipe, let fresh = shipped[stored.id] else { return false }
            return BundledRecipeCatalog.hasSameContent(stored, fresh)
        }
        // Suppress milestone-badge celebrations during restore: crossing count thresholds here would pop a parade of
        // sheets for a library the user already had. Badges still persist, mirroring how `BadgeManager.merge` silences
        // the explicitly-restored badges (BackupService.restore calls that straight after this).
        BadgeManager.shared.isBulkImporting = true
        defer { BadgeManager.shared.isBulkImporting = false }
        for recipe in added {
            saveRecipeModel(recipe)
        }
        for recipe in restored {
            updateRecipe(recipe, includingCookHistory: true)
        }
    }
}
