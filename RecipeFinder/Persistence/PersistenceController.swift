import CoreData

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
                print("❌ Failed to load persistent store: \(error.localizedDescription)")
                print("❌ Error details: \(error.userInfo)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            } else {
                print("✅ Core Data store loaded successfully at: \(storeDescription.url?.absoluteString ?? "unknown location")")
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
            print("✅ Database cleared successfully")
        } catch {
            print("❌ Failed to clear database: \(error.localizedDescription)")
        }
    }
    
    /// Resets the database by clearing all data and repopulating with sample recipes
    /// This also resets the UserDefaults flag to allow repopulation
    func resetDatabase() {
        print("🔄 Resetting database...")
        clearDatabase()
        UserDefaults.standard.set(false, forKey: Constants.UserDefaultsKeys.hasPopulatedDatabase)
        populateDatabase()
        UserDefaults.standard.set(true, forKey: Constants.UserDefaultsKeys.hasPopulatedDatabase)
        print("✅ Database reset complete")
    }
    
    func saveRecipe(
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
        imageName: String
    ) {
        let context = container.viewContext
        
        guard let entity = NSEntityDescription.entity(forEntityName: "Recipe", in: context) else {
            print("❌ Failed to find Recipe entity")
            return
        }
        
        let recipe = NSManagedObject(entity: entity, insertInto: context)
        
        // Encode ingredients
        guard let ingredientData = try? JSONEncoder().encode(ingredients) else {
            print("❌ Failed to encode ingredients for recipe: \(name)")
            return
        }
        
        // Set values with proper capitalization
        recipe.setValue(UUID(), forKey: "id")
        recipe.setValue(name.capitalized, forKey: "name")
        recipe.setValue(category.capitalized, forKey: "category")
        recipe.setValue(difficulty.capitalized, forKey: "difficulty")
        recipe.setValue(prepTime, forKey: "prepTime")
        recipe.setValue(cookingTime, forKey: "cookingTime")
        recipe.setValue(baseServings, forKey: "baseServings")
        recipe.setValue(currentServings, forKey: "currentServings")
        recipe.setValue(ingredientData, forKey: "ingredients")
        recipe.setValue(prePrepInstructions, forKey: "prePrepInstructions")
        recipe.setValue(instructions, forKey: "instructions")
        recipe.setValue(notes, forKey: "notes")
        recipe.setValue(imageName, forKey: "imageName")
        
        do {
            try context.save()
            print("✅ Recipe '\(name)' saved successfully")
        } catch {
            print("❌ Failed to save recipe '\(name)': \(error.localizedDescription)")
        }
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
            print("✅ Fetched \(results.count) recipes from database")
            
            return results.compactMap { result in
                guard let id = result.value(forKey: "id") as? UUID,
                      let name = result.value(forKey: "name") as? String,
                      let ingredientsData = result.value(forKey: "ingredients") as? Data else {
                    print("⚠️ Skipping recipe with missing required fields")
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
                
                // Decode ingredients
                let ingredients: [Ingredient]
                do {
                    ingredients = try JSONDecoder().decode([Ingredient].self, from: ingredientsData)
                } catch {
                    print("❌ Failed to decode ingredients for '\(name)': \(error.localizedDescription)")
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
                    imageName: imageName
                )
            }
        } catch {
            print("❌ Failed to fetch recipes: \(error.localizedDescription)")
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
            print("✅ Recipe deleted successfully")
        } catch {
            print("❌ Failed to delete recipe: \(error.localizedDescription)")
        }
    }
}
