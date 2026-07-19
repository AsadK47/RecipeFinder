import CoreData
import Foundation

private let logger = AppLogger.logger(category: "PersistenceController")

@MainActor
final class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    private(set) var loadError: Error?
    private(set) var isStoreLoaded = false
    
    private enum Entity {
        static let recipe = "Recipe"
    }
    
    private enum RecipeKey {
        static let id = "id"
        static let name = "name"
        static let category = "category"
        static let difficulty = "difficulty"
        static let prepTime = "prepTime"
        static let cookingTime = "cookingTime"
        static let baseServings = "baseServings"
        static let currentServings = "currentServings"
        static let ingredients = "ingredients"
        static let prePrepInstructions = "prePrepInstructions"
        static let instructions = "instructions"
        static let notes = "notes"
        static let imageName = "imageName"
        static let isFavorite = "isFavorite"
        static let userId = "userId"
    }
    
    private init() {
        container = NSPersistentContainer(name: "RecipeModel")
        configureStore()
        loadStore()
    }
    
    private func configureStore() {
        guard let description = container.persistentStoreDescriptions.first else { return }
        
        description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }
    
    private func loadStore() {
        // The store loads synchronously (shouldAddStoreAsynchronously is
        // false by default), so this completion runs on the main thread
        // before loadPersistentStores returns. isStoreLoaded must be set
        // right here, not via a deferred Task: deferring it left the flag
        // false for the first runloop turn, so the launch-time fetchRecipes()
        // returned [] with no retry and the recipe list stayed empty for the
        // whole session — intermittently, depending on scheduling.
        container.loadPersistentStores { [weak self] storeDescription, error in
            MainActor.assumeIsolated {
                guard let self else { return }
                let storeURL = storeDescription.url?.absoluteString ?? "unknown location"

                if let error = error as NSError? {
                    logger.error("❌ Failed to load persistent store: \(error.localizedDescription)")
                    logger.error("❌ Error details: \(error.userInfo)")

                    self.loadError = error
                    self.isStoreLoaded = false
                    self.attemptStoreRecovery()
                } else {
                    logger.debug("✅ Core Data store loaded successfully at: \(storeURL)")
                    self.isStoreLoaded = true
                    self.loadError = nil
                }
            }
        }
    }
    
    private func attemptStoreRecovery() {
        logger.debug("🔄 Attempting to recover from Core Data store failure...")
        
        guard let storeURL = container.persistentStoreDescriptions.first?.url else {
            logger.error("❌ Cannot recover: store URL not found")
            return
        }
        
        do {
            try FileManager.default.removeItem(at: storeURL)
            logger.debug("✅ Removed corrupted store file")
            
            container.loadPersistentStores { [weak self] _, error in
                MainActor.assumeIsolated {
                    guard let self else { return }

                    if let error {
                        logger.error("❌ Recovery failed: \(error.localizedDescription)")
                        self.loadError = error
                        self.isStoreLoaded = false
                    } else {
                        logger.debug("✅ Store recovered successfully")
                        self.isStoreLoaded = true
                        self.loadError = nil
                        self.populateDatabase()
                    }
                }
            }
        } catch {
            logger.error("❌ Failed to remove corrupted store: \(error.localizedDescription)")
            self.loadError = error
        }
    }
    
    @discardableResult
    private func ensureStoreIsReady() -> Bool {
        guard isStoreLoaded else {
            logger.debug("⚠️ Store not loaded. Cannot perform operation.")
            return false
        }
        return true
    }
    
    func clearDatabase() {
        guard ensureStoreIsReady() else { return }
        
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: Entity.recipe)
        
        if let userId = UserScopedStorage.shared.currentUserId {
            fetchRequest.predicate = NSPredicate(format: "userId == %@", userId)
        } else {
            logger.debug("⚠️ No user logged in, skipping database clear to protect other users' data")
            return
        }
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
            logger.debug("✅ Database cleared successfully for current user")
        } catch {
            logger.error("❌ Failed to clear database: \(error.localizedDescription)")
        }
    }
    
    func resetDatabase() {
        logger.debug("🔄 Resetting database...")
        clearDatabase()
        UserScopedStorage.shared.set(false, forKey: Constants.UserDefaultsKeys.hasPopulatedDatabase)
        populateDatabase()
        UserScopedStorage.shared.set(true, forKey: Constants.UserDefaultsKeys.hasPopulatedDatabase)
        logger.debug("✅ Database reset complete")
    }
    
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
            logger.error("❌ Failed to find Recipe entity")
            return
        }
        
        let recipe = NSManagedObject(entity: entity, insertInto: context)
        
        guard let ingredientData = try? JSONEncoder().encode(parameters.ingredients) else {
            logger.error("❌ Failed to encode ingredients for recipe: \(parameters.name)")
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
            logger.debug("✅ Recipe '\(parameters.name)' saved successfully")
            
            let recipeCount = getRecipeCount()
            BadgeManager.shared.checkAndUnlockBadges(recipeCount: recipeCount)
        } catch {
            logger.error("❌ Failed to save recipe '\(parameters.name)': \(error.localizedDescription)")
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
            logger.debug("⚠️ Failed to check if recipe exists, creating new: \(error.localizedDescription)")
            let parameters = RecipeSaveParameters(from: recipe)
            saveRecipe(parameters: parameters)
        }
    }

    func hasCurrentUserScope() -> Bool {
        UserScopedStorage.shared.currentUserId != nil
    }
    
    func fetchRecipes() -> [RecipeModel] {
        guard ensureStoreIsReady() else { return [] }
        
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
        
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(
                key: RecipeKey.name,
                ascending: true,
                selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))
            )
        ]
        
        if let userId = UserScopedStorage.shared.currentUserId {
            fetchRequest.predicate = NSPredicate(format: "userId == %@", userId)
        } else {
            return []
        }
        
        do {
            let results = try context.fetch(fetchRequest)
            logger.debug("✅ Fetched \(results.count) recipes from database for current user")
            return results.compactMap(mapToRecipeModel)
        } catch {
            logger.error("❌ Failed to fetch recipes: \(error.localizedDescription)")
            return []
        }
    }
    
    func fetchRecipeCount() -> Int {
        guard ensureStoreIsReady() else { return 0 }
        
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
        
        if let userId = UserScopedStorage.shared.currentUserId {
            fetchRequest.predicate = NSPredicate(format: "userId == %@", userId)
        } else {
            return 0
        }
        
        do {
            return try context.count(for: fetchRequest)
        } catch {
            logger.error("❌ Failed to fetch recipe count: \(error.localizedDescription)")
            return 0
        }
    }
    
    func getRecipeCount() -> Int {
        return fetchRecipeCount()
    }
    
    private func mapToRecipeModel(_ object: NSManagedObject) -> RecipeModel? {
        guard 
            let id = object.value(forKey: RecipeKey.id) as? UUID,
            let name = object.value(forKey: RecipeKey.name) as? String,
            let ingredientsData = object.value(forKey: RecipeKey.ingredients) as? Data
        else {
            logger.debug("⚠️ Skipping recipe with missing required fields")
            return nil
        }
        
        guard let ingredients = try? JSONDecoder().decode([Ingredient].self, from: ingredientsData) else {
            logger.error("❌ Failed to decode ingredients for '\(name)'")
            return nil
        }
        
        let category = object.value(forKey: RecipeKey.category) as? String ?? "Uncategorized"
        let difficulty = object.value(forKey: RecipeKey.difficulty) as? String ?? "Unknown"
        let prepTime = object.value(forKey: RecipeKey.prepTime) as? String ?? "Unknown"
        let cookingTime = object.value(forKey: RecipeKey.cookingTime) as? String ?? "Unknown"
        let baseServings = object.value(forKey: RecipeKey.baseServings) as? Int ?? 1
        let currentServings = object.value(forKey: RecipeKey.currentServings) as? Int ?? baseServings
        let prePrepInstructions = object.value(forKey: RecipeKey.prePrepInstructions) as? [String] ?? []
        let instructions = object.value(forKey: RecipeKey.instructions) as? [String] ?? []
        let notes = object.value(forKey: RecipeKey.notes) as? String ?? ""
        let imageName = object.value(forKey: RecipeKey.imageName) as? String
        let isFavorite = object.value(forKey: RecipeKey.isFavorite) as? Bool ?? false
        
        return RecipeModel(
            id: id,
            name: name,
            category: category,
            difficulty: difficulty,
            prepTime: prepTime,
            cookingTime: cookingTime,
            baseServings: baseServings,
            currentServings: currentServings,
            ingredients: ingredients,
            prePrepInstructions: prePrepInstructions,
            instructions: instructions,
            notes: notes,
            imageName: imageName,
            isFavorite: isFavorite
        )
    }
    
    func deleteRecipe(withId id: UUID) {
        guard ensureStoreIsReady() else { return }
        
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
        fetchRequest.predicate = NSPredicate(format: "\(RecipeKey.id) == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            guard let recipe = try context.fetch(fetchRequest).first else {
                logger.debug("⚠️ Recipe with id \(id) not found")
                return
            }
            
            context.delete(recipe)
            try context.save()
            logger.debug("✅ Recipe deleted successfully")
        } catch {
            logger.error("❌ Failed to delete recipe: \(error.localizedDescription)")
        }
    }
    
    func clearAllRecipes() {
        clearDatabase()
    }
    
    func updateRecipe(_ recipe: RecipeModel) {
        guard ensureStoreIsReady() else { return }
        
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
        fetchRequest.predicate = NSPredicate(format: "\(RecipeKey.id) == %@", recipe.id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            guard let managedRecipe = try context.fetch(fetchRequest).first else {
                logger.debug("⚠️ Recipe with id \(recipe.id) not found")
                return
            }
            
            guard let ingredientData = try? JSONEncoder().encode(recipe.ingredients) else {
                logger.error("❌ Failed to encode ingredients for recipe: \(recipe.name)")
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
            logger.debug("✅ Recipe '\(recipe.name)' updated successfully")
        } catch {
            logger.error("❌ Failed to update recipe: \(error.localizedDescription)")
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
                logger.debug("⚠️ Recipe with id \(id) not found")
                return
            }
            
            let currentFavorite = recipe.value(forKey: RecipeKey.isFavorite) as? Bool ?? false
            let newFavorite = !currentFavorite
            recipe.setValue(newFavorite, forKey: RecipeKey.isFavorite)
            
            try context.save()
            logger.debug("✅ Recipe favorite status toggled to \(newFavorite)")
        } catch {
            logger.error("❌ Failed to toggle favorite: \(error.localizedDescription)")
        }
    }
}
