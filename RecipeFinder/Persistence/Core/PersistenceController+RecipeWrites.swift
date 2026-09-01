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
            isFavorite: Bool
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
        }
    }
    
    func saveRecipe(parameters: RecipeSaveParameters) {
        guard ensureStoreIsReady() else { return }
        
        let context = container.viewContext
        
        guard let entity = NSEntityDescription.entity(forEntityName: Entity.recipe, in: context) else {
            persistenceLogger.error("❌ Failed to find Recipe entity")
            return
        }
        
        let recipe = NSManagedObject(entity: entity, insertInto: context)
        
        guard let ingredientData = try? JSONEncoder().encode(parameters.ingredients) else {
            persistenceLogger.error("❌ Failed to encode ingredients for recipe: \(parameters.name)")
            return
        }
        
        let recipeId = parameters.id ?? UUID()
        recipe.setValue(recipeId, forKey: RecipeKey.id)
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
        
        if let userId = UserScopedStorage.shared.currentUserId {
            recipe.setValue(userId, forKey: "userId")
        }
        
        do {
            try context.save()
            persistenceLogger.debug("✅ Recipe '\(parameters.name)' saved successfully")
            
            let recipeCount = getRecipeCount()
            BadgeManager.shared.checkAndUnlockBadges(recipeCount: recipeCount)
        } catch {
            persistenceLogger.error("❌ Failed to save recipe '\(parameters.name)': \(error.localizedDescription)")
        }
    }
    
    func saveRecipeModel(_ recipe: RecipeModel) {
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
        fetchRequest.predicate = NSPredicate(format: "\(RecipeKey.id) == %@", recipe.id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let existingRecipes = try context.fetch(fetchRequest)
            if !existingRecipes.isEmpty {
                updateRecipe(recipe)
            } else {
                let parameters = RecipeSaveParameters(from: recipe)
                saveRecipe(parameters: parameters)
            }
        } catch {
            persistenceLogger.debug("⚠️ Failed to check if recipe exists, creating new: \(error.localizedDescription)")
            let parameters = RecipeSaveParameters(from: recipe)
            saveRecipe(parameters: parameters)
        }
    }
    
    /// Faithful, non-destructive restore of recipes from a backup. Existing recipes
    /// are left untouched; only genuinely new ones (per `BackupMerge.mergedRecipes`,
    /// which dedupes by id AND normalized name so re-imports with fresh UUIDs don't
    /// duplicate) are saved into the current user's scope.
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
        fetchRequest.predicate = NSPredicate(format: "\(RecipeKey.id) == %@", id as CVarArg)
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
    
    func updateRecipe(_ recipe: RecipeModel) {
        guard ensureStoreIsReady() else { return }
        
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
        fetchRequest.predicate = NSPredicate(format: "\(RecipeKey.id) == %@", recipe.id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            guard let managedRecipe = try context.fetch(fetchRequest).first else {
                persistenceLogger.debug("⚠️ Recipe with id \(recipe.id) not found")
                return
            }
            
            guard let ingredientData = try? JSONEncoder().encode(recipe.ingredients) else {
                persistenceLogger.error("❌ Failed to encode ingredients for recipe: \(recipe.name)")
                return
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
            
            try context.save()
            persistenceLogger.debug("✅ Recipe '\(recipe.name)' updated successfully")
        } catch {
            persistenceLogger.error("❌ Failed to update recipe: \(error.localizedDescription)")
        }
    }
    
    func toggleFavorite(withId id: UUID) {
        guard ensureStoreIsReady() else { return }
        
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
        fetchRequest.predicate = NSPredicate(format: "\(RecipeKey.id) == %@", id as CVarArg)
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
