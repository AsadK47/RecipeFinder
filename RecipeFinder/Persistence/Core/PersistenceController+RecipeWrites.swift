import CoreData
import Foundation

/// Single-recipe create/update/delete/favorite/cook/rating writes, plus the background content refresh.
extension PersistenceController {

    @discardableResult
    func saveRecipe(parameters: RecipeSaveParameters) -> Bool {
        guard ensureStoreIsReady() else { return false }

        let context = container.viewContext

        guard let entity = NSEntityDescription.entity(forEntityName: Entity.recipe, in: context) else {
            persistenceLogger.error("❌ Failed to find Recipe entity")
            return false
        }
        
        let recipe = NSManagedObject(entity: entity, insertInto: context)
        guard Self.populate(recipe, from: parameters) else { return false }

        do {
            try context.save()
            persistenceLogger.debug("✅ Recipe '\(parameters.name)' saved successfully")

            BadgeManager.shared.checkAndUnlockBadges(recipeCount: fetchCollectedRecipeCount())
            return true
        } catch {
            persistenceLogger.error("❌ Failed to save recipe '\(parameters.name)': \(error.localizedDescription)")
            return false
        }
    }

    /// Rewrites existing recipes' content on a background context in one save (the stale-sample refresh touched up to
    /// ~330 recipes one main-thread save at a time). Cook history is re-read from the store, never overwritten.
    /// Missing ids are skipped. With `snapshots`, a recipe whose stored copy no longer matches its snapshot (or has
    /// none) is skipped too — an edit, favourite or rating synced in from iCloud since the caller read it wins.
    /// Returns the ids written, or nil if the save failed.
    func updateRecipesInBackground(
        _ models: [RecipeModel], unlessChangedSince snapshots: [UUID: RecipeModel]? = nil
    ) async -> Set<UUID>? {
        guard !models.isEmpty else { return [] }
        guard ensureStoreIsReady() else { return nil }
        let container = self.container
        return await withCheckedContinuation { continuation in
            container.performBackgroundTask { context in
                do {
                    var written = Set<UUID>()
                    for model in models {
                        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
                        request.predicate = Self.recipeIdPredicate(model.id)
                        request.fetchLimit = 1
                        guard let object = try context.fetch(request).first else { continue }
                        if let snapshots {
                            guard let snapshot = snapshots[model.id],
                                  let stored = Self.mapToRecipeModel(object),
                                  BundledRecipeCatalog.isUnchanged(stored, since: snapshot) else { continue }
                        }
                        let cookCount = object.value(forKey: RecipeKey.cookCount)
                        let lastCookedAt = object.value(forKey: RecipeKey.lastCookedAt)
                        guard Self.populate(object, from: RecipeSaveParameters(from: model)) else { continue }
                        object.setValue(cookCount, forKey: RecipeKey.cookCount)
                        object.setValue(lastCookedAt, forKey: RecipeKey.lastCookedAt)
                        written.insert(model.id)
                    }
                    try context.save()
                    continuation.resume(returning: written)
                } catch {
                    persistenceLogger.error("❌ Failed to batch-update recipes: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    @discardableResult
    func saveRecipeModel(_ recipe: RecipeModel) -> Bool {
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
        fetchRequest.predicate = Self.recipeIdPredicate(recipe.id)
        fetchRequest.fetchLimit = 1

        do {
            let existingRecipes = try context.fetch(fetchRequest)
            if !existingRecipes.isEmpty {
                return updateRecipe(recipe)
            } else {
                return saveRecipe(parameters: RecipeSaveParameters(from: recipe))
            }
        } catch {
            persistenceLogger.error("❌ Failed to check if recipe exists, creating new: \(error.localizedDescription)")
            return saveRecipe(parameters: RecipeSaveParameters(from: recipe))
        }
    }
    
    func deleteRecipe(withId id: UUID) {
        guard ensureStoreIsReady() else { return }
        
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
        fetchRequest.predicate = Self.recipeIdPredicate(id)

        do {
            // Every row with the id: with iCloud sync on, another device's copy may not be merged yet.
            let rows = try context.fetch(fetchRequest)
            guard !rows.isEmpty else {
                persistenceLogger.debug("⚠️ Recipe with id \(id) not found")
                return
            }

            for row in rows { context.delete(row) }
            try context.save()
            persistenceLogger.debug("✅ Recipe deleted successfully")
        } catch {
            persistenceLogger.error("❌ Failed to delete recipe: \(error.localizedDescription)")
        }
    }
    
    @discardableResult
    func updateRecipe(_ recipe: RecipeModel, includingCookHistory: Bool = false) -> Bool {
        guard ensureStoreIsReady() else { return false }

        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
        fetchRequest.predicate = Self.recipeIdPredicate(recipe.id)

        do {
            // Every row with the id: with iCloud sync on, another device's copy may not be merged yet.
            let rows = try context.fetch(fetchRequest)
            guard !rows.isEmpty else {
                persistenceLogger.debug("⚠️ Recipe with id \(recipe.id) not found")
                return false
            }

            guard let ingredientData = try? JSONEncoder().encode(recipe.ingredients) else {
                persistenceLogger.error("❌ Failed to encode ingredients for recipe: \(recipe.name)")
                return false
            }

            for managedRecipe in rows {
                managedRecipe.setValue(recipe.name, forKey: RecipeKey.name)
                managedRecipe.setValue(recipe.category, forKey: RecipeKey.category)
                managedRecipe.setValue(recipe.difficulty, forKey: RecipeKey.difficulty)
                managedRecipe.setValue(recipe.prepTime, forKey: RecipeKey.prepTime)
                managedRecipe.setValue(recipe.cookingTime, forKey: RecipeKey.cookingTime)
                managedRecipe.setValue(recipe.baseServings, forKey: RecipeKey.baseServings)
                managedRecipe.setValue(recipe.currentServings, forKey: RecipeKey.currentServings)
                managedRecipe.setValue(ingredientData, forKey: RecipeKey.ingredients)
                managedRecipe.setValue(recipe.prePrepInstructions, forKey: RecipeKey.prePrepInstructions)
                managedRecipe.setValue(recipe.instructions, forKey: RecipeKey.instructions)
                managedRecipe.setValue(recipe.notes, forKey: RecipeKey.notes)
                managedRecipe.setValue(recipe.imageName, forKey: RecipeKey.imageName)
                managedRecipe.setValue(recipe.isFavorite, forKey: RecipeKey.isFavorite)
                managedRecipe.setValue(recipe.isSampleRecipe, forKey: RecipeKey.isSampleRecipe)
                managedRecipe.setValue(recipe.tags as NSArray, forKey: RecipeKey.tags)
                managedRecipe.setValue(recipe.rating, forKey: RecipeKey.rating)
                managedRecipe.setValue(recipe.cuisine, forKey: RecipeKey.cuisine)
                managedRecipe.setValue(recipe.photoNames as NSArray, forKey: RecipeKey.photoNames)
                managedRecipe.setValue(recipe.sourceText, forKey: RecipeKey.sourceText)
                if let dietaryData = try? JSONEncoder().encode(recipe.dietaryInfo) {
                    managedRecipe.setValue(dietaryData, forKey: RecipeKey.dietaryInfo)
                }
                // cookCount/lastCookedAt normally untouched — recordCook(_:) owns them, preserving cook history across edits.
                // Restore is the exception: it writes the merged history from a backup.
                if includingCookHistory {
                    managedRecipe.setValue(recipe.cookCount, forKey: RecipeKey.cookCount)
                    managedRecipe.setValue(recipe.lastCookedAt, forKey: RecipeKey.lastCookedAt)
                }
            }

            try context.save()
            persistenceLogger.debug("✅ Recipe '\(recipe.name)' updated successfully")
            return true
        } catch {
            persistenceLogger.error("❌ Failed to update recipe: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Recipe lookup by id. `nonisolated static` so it can be built inside a `performBackgroundTask` closure without
    /// touching the @MainActor instance.
    nonisolated static func recipeIdPredicate(_ id: UUID) -> NSPredicate {
        NSPredicate(format: "\(RecipeKey.id) == %@", id as CVarArg)
    }

    /// Increments `cookCount` and stamps `lastCookedAt` on a background context so the post-cook flow never blocks
    /// the main thread; `await`s the save so callers/tests observe a completed write. Bypasses `updateRecipe` since
    /// cook history is separate from content edits.
    func recordCook(withId id: UUID) async {
        guard ensureStoreIsReady() else { return }
        let container = self.container
        await withCheckedContinuation { continuation in
            container.performBackgroundTask { context in
                let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
                fetchRequest.predicate = Self.recipeIdPredicate(id)
                fetchRequest.fetchLimit = 1
                do {
                    guard let recipe = try context.fetch(fetchRequest).first else {
                        persistenceLogger.debug("⚠️ Recipe with id \(id) not found")
                        continuation.resume()
                        return
                    }
                    let current = recipe.value(forKey: RecipeKey.cookCount) as? Int ?? 0
                    recipe.setValue(current + 1, forKey: RecipeKey.cookCount)
                    recipe.setValue(Date(), forKey: RecipeKey.lastCookedAt)
                    try context.save()
                    persistenceLogger.debug("✅ Cook recorded for recipe \(id), count now \(current + 1)")
                } catch {
                    persistenceLogger.error("❌ Failed to record cook: \(error.localizedDescription)")
                }
                continuation.resume()
            }
        }
    }

    /// Persists a rating on a background context (off the main thread); `await`s the save.
    func updateRating(withId id: UUID, rating: Int) async {
        guard ensureStoreIsReady() else { return }
        let container = self.container
        await withCheckedContinuation { continuation in
            container.performBackgroundTask { context in
                let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
                fetchRequest.predicate = Self.recipeIdPredicate(id)
                fetchRequest.fetchLimit = 1
                do {
                    guard let recipe = try context.fetch(fetchRequest).first else {
                        persistenceLogger.debug("⚠️ Recipe with id \(id) not found")
                        continuation.resume()
                        return
                    }
                    recipe.setValue(rating, forKey: RecipeKey.rating)
                    try context.save()
                    persistenceLogger.debug("✅ Rating updated to \(rating) for recipe \(id)")
                } catch {
                    persistenceLogger.error("❌ Failed to update rating: \(error.localizedDescription)")
                }
                continuation.resume()
            }
        }
    }

    func toggleFavorite(withId id: UUID) {
        guard ensureStoreIsReady() else { return }
        
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
        fetchRequest.predicate = Self.recipeIdPredicate(id)
        fetchRequest.fetchLimit = 1
        
        do {
            guard let recipe = try context.fetch(fetchRequest).first else {
                persistenceLogger.debug("⚠️ Recipe with id \(id) not found")
                return
            }
            
            let currentFavorite = recipe.value(forKey: RecipeKey.isFavorite) as? Bool ?? false
            let newFavorite = !currentFavorite
            recipe.setValue(newFavorite, forKey: RecipeKey.isFavorite)
            
            try context.save()
            persistenceLogger.debug("✅ Recipe favorite status toggled to \(newFavorite)")
        } catch {
            persistenceLogger.error("❌ Failed to toggle favorite: \(error.localizedDescription)")
        }
    }
}
