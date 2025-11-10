import CoreData
import Foundation

final class PersistenceController {
    nonisolated(unsafe) static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    private(set) var loadError: Error?
    private(set) var isStoreLoaded = false
    
    // Constants for entity and keys
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
        
        // Enable automatic merging of changes
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }
    
    private func loadStore() {
        container.loadPersistentStores { [weak self] storeDescription, error in
            guard let self = self else { return }
            let storeURL = storeDescription.url?.absoluteString ?? "unknown location"
            
            if let error = error as NSError? {
                debugLog("❌ Failed to load persistent store: \(error.localizedDescription)")
                debugLog("❌ Error details: \(error.userInfo)")
                
                self.loadError = error
                self.isStoreLoaded = false
                self.attemptStoreRecovery()
            } else {
                debugLog("✅ Core Data store loaded successfully at: \(storeURL)")
                self.isStoreLoaded = true
                self.loadError = nil
            }
        }
    }
    
    /// Attempts to recover from a store loading failure by removing corrupted data
    private func attemptStoreRecovery() {
        debugLog("🔄 Attempting to recover from Core Data store failure...")
        
        guard let storeURL = container.persistentStoreDescriptions.first?.url else {
            debugLog("❌ Cannot recover: store URL not found")
            return
        }
        
        do {
            try FileManager.default.removeItem(at: storeURL)
            debugLog("✅ Removed corrupted store file")
            
            container.loadPersistentStores { [weak self] _, error in
                guard let self = self else { return }
                
                if let error {
                    debugLog("❌ Recovery failed: \(error.localizedDescription)")
                    self.loadError = error
                    self.isStoreLoaded = false
                } else {
                    debugLog("✅ Store recovered successfully")
                    self.isStoreLoaded = true
                    self.loadError = nil
                    self.populateDatabase()
                }
            }
        } catch {
            debugLog("❌ Failed to remove corrupted store: \(error.localizedDescription)")
            self.loadError = error
        }
    }
    
    /// Checks if the persistent store is ready for operations
    @discardableResult
    private func ensureStoreIsReady() -> Bool {
        guard isStoreLoaded else {
            debugLog("⚠️ Store not loaded. Cannot perform operation.")
            return false
        }
        return true
    }
    
    func clearDatabase() {
        guard ensureStoreIsReady() else { return }
        
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: Entity.recipe)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
            debugLog("✅ Database cleared successfully")
        } catch {
            debugLog("❌ Failed to clear database: \(error.localizedDescription)")
        }
    }
    
    /// Resets the database by clearing all data and repopulating with sample recipes
    func resetDatabase() {
        debugLog("🔄 Resetting database...")
        clearDatabase()
        UserDefaults.standard.set(false, forKey: Constants.UserDefaultsKeys.hasPopulatedDatabase)
        populateDatabase()
        UserDefaults.standard.set(true, forKey: Constants.UserDefaultsKeys.hasPopulatedDatabase)
        debugLog("✅ Database reset complete")
    }
    
    // MARK: - Recipe Save Parameters
    
    struct RecipeSaveParameters {
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
        
        // Memberwise initializer for direct parameter passing
        init(
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
        
        // Convenience initializer from RecipeModel
        init(from recipe: RecipeModel) {
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
    
    // MARK: - Save Operations
    
    func saveRecipe(parameters: RecipeSaveParameters) {
        guard ensureStoreIsReady() else { return }
        
        let context = container.viewContext
        
        guard let entity = NSEntityDescription.entity(forEntityName: Entity.recipe, in: context) else {
            debugLog("❌ Failed to find Recipe entity")
            return
        }
        
        let recipe = NSManagedObject(entity: entity, insertInto: context)
        
        // Encode ingredients
        guard let ingredientData = try? JSONEncoder().encode(parameters.ingredients) else {
            debugLog("❌ Failed to encode ingredients for recipe: \(parameters.name)")
            return
        }
        
        // Set values using constants
        recipe.setValue(UUID(), forKey: RecipeKey.id)
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
        
        do {
            try context.save()
            debugLog("✅ Recipe '\(parameters.name)' saved successfully")
        } catch {
            debugLog("❌ Failed to save recipe '\(parameters.name)': \(error.localizedDescription)")
        }
    }
    
    func saveRecipeModel(_ recipe: RecipeModel) {
        let parameters = RecipeSaveParameters(from: recipe)
        saveRecipe(parameters: parameters)
    }
    
    // MARK: - Fetch Operations
    
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
        
        do {
            let results = try context.fetch(fetchRequest)
            debugLog("✅ Fetched \(results.count) recipes from database")
            return results.compactMap(mapToRecipeModel)
        } catch {
            debugLog("❌ Failed to fetch recipes: \(error.localizedDescription)")
            return []
        }
    }
    
    func fetchRecipeCount() -> Int {
        guard ensureStoreIsReady() else { return 0 }
        
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
        
        do {
            return try context.count(for: fetchRequest)
        } catch {
            debugLog("❌ Failed to fetch recipe count: \(error.localizedDescription)")
            return 0
        }
    }
    
    // MARK: - Mapping
    
    private func mapToRecipeModel(_ object: NSManagedObject) -> RecipeModel? {
        guard 
            let id = object.value(forKey: RecipeKey.id) as? UUID,
            let name = object.value(forKey: RecipeKey.name) as? String,
            let ingredientsData = object.value(forKey: RecipeKey.ingredients) as? Data
        else {
            debugLog("⚠️ Skipping recipe with missing required fields")
            return nil
        }
        
        // Decode ingredients
        guard let ingredients = try? JSONDecoder().decode([Ingredient].self, from: ingredientsData) else {
            debugLog("❌ Failed to decode ingredients for '\(name)'")
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
    
    // MARK: - Delete Operations
    
    func deleteRecipe(withId id: UUID) {
        guard ensureStoreIsReady() else { return }
        
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
        fetchRequest.predicate = NSPredicate(format: "\(RecipeKey.id) == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            guard let recipe = try context.fetch(fetchRequest).first else {
                debugLog("⚠️ Recipe with id \(id) not found")
                return
            }
            
            context.delete(recipe)
            try context.save()
            debugLog("✅ Recipe deleted successfully")
        } catch {
            debugLog("❌ Failed to delete recipe: \(error.localizedDescription)")
        }
    }
    
    func clearAllRecipes() {
        clearDatabase()
    }
    
    // MARK: - Update Operations
    
    func updateRecipe(_ recipe: RecipeModel) {
        guard ensureStoreIsReady() else { return }
        
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
        fetchRequest.predicate = NSPredicate(format: "\(RecipeKey.id) == %@", recipe.id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            guard let managedRecipe = try context.fetch(fetchRequest).first else {
                debugLog("⚠️ Recipe with id \(recipe.id) not found")
                return
            }
            
            // Encode ingredients
            guard let ingredientData = try? JSONEncoder().encode(recipe.ingredients) else {
                debugLog("❌ Failed to encode ingredients for recipe: \(recipe.name)")
                return
            }
            
            // Update values
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
            debugLog("✅ Recipe '\(recipe.name)' updated successfully")
        } catch {
            debugLog("❌ Failed to update recipe: \(error.localizedDescription)")
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
                debugLog("⚠️ Recipe with id \(id) not found")
                return
            }
            
            let currentFavorite = recipe.value(forKey: RecipeKey.isFavorite) as? Bool ?? false
            let newFavorite = !currentFavorite
            recipe.setValue(newFavorite, forKey: RecipeKey.isFavorite)
            
            try context.save()
            debugLog("✅ Recipe favorite status toggled to \(newFavorite)")
        } catch {
            debugLog("❌ Failed to toggle favorite: \(error.localizedDescription)")
        }
    }
}
