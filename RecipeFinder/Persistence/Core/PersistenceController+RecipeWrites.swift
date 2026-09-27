import CoreData
import Foundation

/// Recipe create/update/delete/favorite operations.
extension PersistenceController {

    struct RecipeSaveParameters {
        let id: UUID?
        let name: String
        let category: String
        let difficulty: String
        let prepTime: String
        let cookingTime: String
        let baseServings: Int
        let currentServings: Int
        let ingredients: [Ingredient]
        let prePrepInstructions: [String]
        let instructions: [String]
        let notes: String
        let imageName: String
        let isFavorite: Bool
        let isSampleRecipe: Bool
        let dietaryInfo: DietaryInfo
        let tags: [String]
        let cookCount: Int
        let lastCookedAt: Date?
        let rating: Int
        let cuisine: String?
        let photoNames: [String]

        init(
            id: UUID? = nil,
            name: String,
            category: String,
            difficulty: String,
            prepTime: String,
            cookingTime: String,
            baseServings: Int,
            currentServings: Int,
            ingredients: [Ingredient],
            prePrepInstructions: [String],
            instructions: [String],
            notes: String,
            imageName: String,
            isFavorite: Bool,
            isSampleRecipe: Bool = false,
            dietaryInfo: DietaryInfo = DietaryInfo(),
            tags: [String] = [],
            cookCount: Int = 0,
            lastCookedAt: Date? = nil,
            rating: Int = 0,
            cuisine: String? = nil,
            photoNames: [String] = []
        ) {
            self.id = id
            self.name = name
            self.category = category
            self.difficulty = difficulty
            self.prepTime = prepTime
            self.cookingTime = cookingTime
            self.baseServings = baseServings
            self.currentServings = currentServings
            self.ingredients = ingredients
            self.prePrepInstructions = prePrepInstructions
            self.instructions = instructions
            self.notes = notes
            self.imageName = imageName
            self.isFavorite = isFavorite
            self.isSampleRecipe = isSampleRecipe
            self.dietaryInfo = dietaryInfo
            self.tags = tags
            self.cookCount = cookCount
            self.lastCookedAt = lastCookedAt
            self.rating = rating
            self.cuisine = cuisine
            self.photoNames = photoNames
        }

        init(from recipe: RecipeModel) {
            self.id = recipe.id
            self.name = recipe.name
            self.category = recipe.category
            self.difficulty = recipe.difficulty
            self.prepTime = recipe.prepTime
            self.cookingTime = recipe.cookingTime
            self.baseServings = recipe.baseServings
            self.currentServings = recipe.currentServings
            self.ingredients = recipe.ingredients
            self.prePrepInstructions = recipe.prePrepInstructions
            self.instructions = recipe.instructions
            self.notes = recipe.notes
            self.imageName = recipe.imageName ?? ""
            self.isFavorite = recipe.isFavorite
            self.isSampleRecipe = recipe.isSampleRecipe
            self.dietaryInfo = recipe.dietaryInfo
            self.tags = recipe.tags
            self.cookCount = recipe.cookCount
            self.lastCookedAt = recipe.lastCookedAt
            self.rating = recipe.rating
            self.cuisine = recipe.cuisine
            self.photoNames = recipe.photoNames
        }
    }
    
    /// Scopes a recipe lookup to the current user so the shared fixed seed UUIDs can't let one account's write land on another's row; id-only fallback for guests (no userId).
    private func recipeIdPredicate(_ id: UUID) -> NSPredicate {
        if let userId = userID() {
            return NSPredicate(format: "\(RecipeKey.id) == %@ AND userId == %@", id as CVarArg, userId)
        }
        return NSPredicate(format: "\(RecipeKey.id) == %@", id as CVarArg)
    }

    @discardableResult
    func saveRecipe(parameters: RecipeSaveParameters) -> Bool {
        guard ensureStoreIsReady() else { return false }

        let context = container.viewContext

        guard let entity = NSEntityDescription.entity(forEntityName: Entity.recipe, in: context) else {
            persistenceLogger.error("❌ Failed to find Recipe entity")
            return false
        }
        
        let recipe = NSManagedObject(entity: entity, insertInto: context)
        guard Self.populate(recipe, from: parameters, userId: userID()) else { return false }

        do {
            try context.save()
            persistenceLogger.debug("✅ Recipe '\(parameters.name)' saved successfully")

            let recipeCount = getRecipeCount()
            BadgeManager.shared.checkAndUnlockBadges(recipeCount: recipeCount)
            return true
        } catch {
            persistenceLogger.error("❌ Failed to save recipe '\(parameters.name)': \(error.localizedDescription)")
            return false
        }
    }

    /// Maps `RecipeSaveParameters` onto a fresh managed object; shared by `saveRecipe` and `seedRecipes` so the field list has one home. Returns false only if ingredients can't be encoded.
    nonisolated private static func populate(
        _ recipe: NSManagedObject,
        from parameters: RecipeSaveParameters,
        userId: String?
    ) -> Bool {
        guard let ingredientData = try? JSONEncoder().encode(parameters.ingredients) else {
            persistenceLogger.error("❌ Failed to encode ingredients for recipe: \(parameters.name)")
            return false
        }

        recipe.setValue(parameters.id ?? UUID(), forKey: RecipeKey.id)
        recipe.setValue(parameters.name, forKey: RecipeKey.name)
        recipe.setValue(parameters.category, forKey: RecipeKey.category)
        recipe.setValue(parameters.difficulty, forKey: RecipeKey.difficulty)
        recipe.setValue(parameters.prepTime, forKey: RecipeKey.prepTime)
        recipe.setValue(parameters.cookingTime, forKey: RecipeKey.cookingTime)
        recipe.setValue(parameters.baseServings, forKey: RecipeKey.baseServings)
        recipe.setValue(parameters.currentServings, forKey: RecipeKey.currentServings)
        recipe.setValue(ingredientData, forKey: RecipeKey.ingredients)
        recipe.setValue(parameters.prePrepInstructions, forKey: RecipeKey.prePrepInstructions)
        recipe.setValue(parameters.instructions, forKey: RecipeKey.instructions)
        recipe.setValue(parameters.notes, forKey: RecipeKey.notes)
        recipe.setValue(parameters.imageName, forKey: RecipeKey.imageName)
        recipe.setValue(parameters.isFavorite, forKey: RecipeKey.isFavorite)
        recipe.setValue(parameters.isSampleRecipe, forKey: RecipeKey.isSampleRecipe)
        recipe.setValue(parameters.tags as NSArray, forKey: RecipeKey.tags)
        recipe.setValue(parameters.cookCount, forKey: RecipeKey.cookCount)
        recipe.setValue(parameters.lastCookedAt, forKey: RecipeKey.lastCookedAt)
        recipe.setValue(parameters.rating, forKey: RecipeKey.rating)
        recipe.setValue(parameters.cuisine, forKey: RecipeKey.cuisine)
        recipe.setValue(parameters.photoNames as NSArray, forKey: RecipeKey.photoNames)
        if let dietaryData = try? JSONEncoder().encode(parameters.dietaryInfo) {
            recipe.setValue(dietaryData, forKey: RecipeKey.dietaryInfo)
        }
        if let userId {
            recipe.setValue(userId, forKey: "userId")
        }
        return true
    }

    /// Bulk-inserts starter recipes on a background context in one save so first sign-in doesn't freeze; skips per-recipe count/badge work by design.
    func seedRecipes(_ models: [RecipeModel]) async {
        guard ensureStoreIsReady(), let userId = userID() else { return }
        let container = self.container
        await withCheckedContinuation { continuation in
            container.performBackgroundTask { context in
                guard let entity = NSEntityDescription.entity(forEntityName: Entity.recipe, in: context) else {
                    persistenceLogger.error("❌ Failed to find Recipe entity while seeding")
                    continuation.resume()
                    return
                }
                for model in models {
                    let object = NSManagedObject(entity: entity, insertInto: context)
                    _ = Self.populate(object, from: RecipeSaveParameters(from: model), userId: userId)
                }
                do {
                    try context.save()
                    persistenceLogger.debug("✅ Seeded \(models.count) starter recipes")
                } catch {
                    persistenceLogger.error("❌ Failed to seed starter recipes: \(error.localizedDescription)")
                }
                continuation.resume()
            }
        }
    }

    @discardableResult
    func saveRecipeModel(_ recipe: RecipeModel) -> Bool {
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
        fetchRequest.predicate = recipeIdPredicate(recipe.id)
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
    
    /// Non-destructive restore: saves only new recipes per `BackupMerge.mergedRecipes` (dedupes by id AND normalized name so re-imports don't duplicate).
    func mergeRecipes(_ incoming: [RecipeModel]) {
        let existing = fetchRecipes()
        let existingIDs = Set(existing.map(\.id))
        let merged = BackupMerge.mergedRecipes(existing: existing, incoming: incoming)
        for recipe in merged where !existingIDs.contains(recipe.id) {
            saveRecipeModel(recipe)
        }
    }

    func deleteRecipe(withId id: UUID) {
        guard ensureStoreIsReady() else { return }
        
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
        fetchRequest.predicate = recipeIdPredicate(id)
        fetchRequest.fetchLimit = 1
        
        do {
            guard let recipe = try context.fetch(fetchRequest).first else {
                persistenceLogger.debug("⚠️ Recipe with id \(id) not found")
                return
            }
            
            context.delete(recipe)
            try context.save()
            persistenceLogger.debug("✅ Recipe deleted successfully")
        } catch {
            persistenceLogger.error("❌ Failed to delete recipe: \(error.localizedDescription)")
        }
    }
    
    @discardableResult
    func updateRecipe(_ recipe: RecipeModel) -> Bool {
        guard ensureStoreIsReady() else { return false }

        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
        fetchRequest.predicate = recipeIdPredicate(recipe.id)
        fetchRequest.fetchLimit = 1

        do {
            guard let managedRecipe = try context.fetch(fetchRequest).first else {
                persistenceLogger.debug("⚠️ Recipe with id \(recipe.id) not found")
                return false
            }

            guard let ingredientData = try? JSONEncoder().encode(recipe.ingredients) else {
                persistenceLogger.error("❌ Failed to encode ingredients for recipe: \(recipe.name)")
                return false
            }

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
            if let dietaryData = try? JSONEncoder().encode(recipe.dietaryInfo) {
                managedRecipe.setValue(dietaryData, forKey: RecipeKey.dietaryInfo)
            }
            // cookCount/lastCookedAt intentionally not updated here — only recordCook(_:) touches them, preserving cook history across edits.

            try context.save()
            persistenceLogger.debug("✅ Recipe '\(recipe.name)' updated successfully")
            return true
        } catch {
            persistenceLogger.error("❌ Failed to update recipe: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Increments `cookCount` and stamps `lastCookedAt`; bypasses `updateRecipe` since cook history is separate from content edits.
    func recordCook(withId id: UUID) {
        guard ensureStoreIsReady() else { return }

        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
        fetchRequest.predicate = recipeIdPredicate(id)
        fetchRequest.fetchLimit = 1

        do {
            guard let recipe = try context.fetch(fetchRequest).first else {
                persistenceLogger.debug("⚠️ Recipe with id \(id) not found")
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
    }

    func updateRating(withId id: UUID, rating: Int) {
        guard ensureStoreIsReady() else { return }

        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
        fetchRequest.predicate = recipeIdPredicate(id)
        fetchRequest.fetchLimit = 1

        do {
            guard let recipe = try context.fetch(fetchRequest).first else {
                persistenceLogger.debug("⚠️ Recipe with id \(id) not found")
                return
            }

            recipe.setValue(rating, forKey: RecipeKey.rating)
            try context.save()
            persistenceLogger.debug("✅ Rating updated to \(rating) for recipe \(id)")
        } catch {
            persistenceLogger.error("❌ Failed to update rating: \(error.localizedDescription)")
        }
    }

    func toggleFavorite(withId id: UUID) {
        guard ensureStoreIsReady() else { return }
        
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
        fetchRequest.predicate = recipeIdPredicate(id)
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
