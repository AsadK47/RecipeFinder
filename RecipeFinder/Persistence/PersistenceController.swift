import CoreData
import Foundation

class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    private init() {
        container = NSPersistentContainer(name: "RecipeModel")
        
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description?.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                debugLog("❌ Failed to load persistent store: \(error.localizedDescription)")
                debugLog("❌ Error details: \(error.userInfo)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            } else {
                debugLog("✅ Core Data store loaded successfully at: \(storeDescription.url?.absoluteString ?? "unknown location")")
            }
        }
        
        // Enable automatic merging of changes
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    func clearDatabase() {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Recipe")
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
    /// This also resets the UserDefaults flag to allow repopulation
    func resetDatabase() {
        debugLog("🔄 Resetting database...")
        clearDatabase()
        UserDefaults.standard.set(false, forKey: Constants.UserDefaultsKeys.hasPopulatedDatabase)
        populateDatabase()
        UserDefaults.standard.set(true, forKey: Constants.UserDefaultsKeys.hasPopulatedDatabase)
        debugLog("✅ Database reset complete")
    }
    
    // Struct to encapsulate recipe save parameters
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
    }
    
    func saveRecipe(parameters: RecipeSaveParameters) {
        let context = container.viewContext
        
        guard let entity = NSEntityDescription.entity(forEntityName: "Recipe", in: context) else {
            debugLog("❌ Failed to find Recipe entity")
            return
        }
        
        let recipe = NSManagedObject(entity: entity, insertInto: context)
        
        // Encode ingredients
        guard let ingredientData = try? JSONEncoder().encode(parameters.ingredients) else {
            debugLog("❌ Failed to encode ingredients for recipe: \(parameters.name)")
            return
        }
        
        // Set values
        recipe.setValue(UUID(), forKey: "id")
        recipe.setValue(parameters.name, forKey: "name")
        recipe.setValue(parameters.category, forKey: "category")
        recipe.setValue(parameters.difficulty, forKey: "difficulty")
        recipe.setValue(parameters.prepTime, forKey: "prepTime")
        recipe.setValue(parameters.cookingTime, forKey: "cookingTime")
        recipe.setValue(parameters.baseServings, forKey: "baseServings")
        recipe.setValue(parameters.currentServings, forKey: "currentServings")
        recipe.setValue(ingredientData, forKey: "ingredients")
        recipe.setValue(parameters.prePrepInstructions, forKey: "prePrepInstructions")
        recipe.setValue(parameters.instructions, forKey: "instructions")
        recipe.setValue(parameters.notes, forKey: "notes")
        recipe.setValue(parameters.imageName, forKey: "imageName")
        recipe.setValue(parameters.isFavorite, forKey: "isFavorite")
        
        do {
            try context.save()
            debugLog("✅ Recipe '\(parameters.name)' saved successfully")
        } catch {
            debugLog("❌ Failed to save recipe '\(parameters.name)': \(error.localizedDescription)")
        }
    }
    
    // swiftlint:disable:next function_body_length
    
    // Helper method to save a RecipeModel directly
    func saveRecipeModel(_ recipe: RecipeModel) {
        let parameters = RecipeSaveParameters(
            name: recipe.name,
            category: recipe.category,
            difficulty: recipe.difficulty,
            prepTime: recipe.prepTime,
            cookingTime: recipe.cookingTime,
            baseServings: recipe.baseServings,
            currentServings: recipe.currentServings,
            ingredients: recipe.ingredients,
            prePrepInstructions: recipe.prePrepInstructions,
            instructions: recipe.instructions,
            notes: recipe.notes,
            imageName: recipe.imageName ?? "",
            isFavorite: recipe.isFavorite
        )
        saveRecipe(parameters: parameters)
    }
    
    func fetchRecipes() -> [RecipeModel] {
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Recipe")
        
        let sortDescriptor = NSSortDescriptor(
            key: "name",
            ascending: true,
            selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))
        )
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            let results = try context.fetch(fetchRequest)
            debugLog("✅ Fetched \(results.count) recipes from database")
            
            return results.compactMap { result in
                guard let id = result.value(forKey: "id") as? UUID,
                      let name = result.value(forKey: "name") as? String,
                      let ingredientsData = result.value(forKey: "ingredients") as? Data else {
                    debugLog("⚠️ Skipping recipe with missing required fields")
                    return nil
                }
                
                let category = result.value(forKey: "category") as? String ?? "Uncategorized"
                let difficulty = result.value(forKey: "difficulty") as? String ?? "Unknown"
                let prepTime = result.value(forKey: "prepTime") as? String ?? "Unknown"
                let cookingTime = result.value(forKey: "cookingTime") as? String ?? "Unknown"
                let baseServings = result.value(forKey: "baseServings") as? Int ?? 1
                let currentServings = result.value(forKey: "currentServings") as? Int ?? baseServings
                let prePrepInstructions = result.value(forKey: "prePrepInstructions") as? [String] ?? []
                let instructions = result.value(forKey: "instructions") as? [String] ?? []
                let notes = result.value(forKey: "notes") as? String ?? ""
                let imageName = result.value(forKey: "imageName") as? String
                let isFavorite = result.value(forKey: "isFavorite") as? Bool ?? false
                
                // Decode ingredients
                let ingredients: [Ingredient]
                do {
                    ingredients = try JSONDecoder().decode([Ingredient].self, from: ingredientsData)
                } catch {
                    debugLog("❌ Failed to decode ingredients for '\(name)': \(error.localizedDescription)")
                    return nil
                }
                
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
        } catch {
            debugLog("❌ Failed to fetch recipes: \(error.localizedDescription)")
            return []
        }
    }
    
    func deleteRecipe(withId id: UUID) {
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Recipe")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            for object in results {
                context.delete(object)
            }
            try context.save()
            debugLog("✅ Recipe deleted successfully")
        } catch {
            debugLog("❌ Failed to delete recipe: \(error.localizedDescription)")
        }
    }
    
    func toggleFavorite(withId id: UUID) {
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Recipe")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let recipe = results.first {
                let currentFavorite = recipe.value(forKey: "isFavorite") as? Bool ?? false
                recipe.setValue(!currentFavorite, forKey: "isFavorite")
                try context.save()
                debugLog("✅ Recipe favorite status toggled to \(!currentFavorite)")
            }
        } catch {
            debugLog("❌ Failed to toggle favorite: \(error.localizedDescription)")
        }
    }
}
