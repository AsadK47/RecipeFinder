import CoreData
import Foundation

/// Recipe fetch/count queries and managed-object → model mapping.
extension PersistenceController {

    func hasCurrentUserScope() -> Bool {
        userID() != nil
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
        
        if let userId = userID() {
            fetchRequest.predicate = NSPredicate(format: "userId == %@", userId)
        } else {
            return []
        }
        
        do {
            let results = try context.fetch(fetchRequest)
            persistenceLogger.debug("✅ Fetched \(results.count) recipes from database for current user")
            return results.compactMap(mapToRecipeModel)
        } catch {
            persistenceLogger.error("❌ Failed to fetch recipes: \(error.localizedDescription)")
            return []
        }
    }
    
    func fetchRecipeCount() -> Int {
        guard ensureStoreIsReady() else { return 0 }
        
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
        
        if let userId = userID() {
            fetchRequest.predicate = NSPredicate(format: "userId == %@", userId)
        } else {
            return 0
        }
        
        do {
            return try context.count(for: fetchRequest)
        } catch {
            persistenceLogger.error("❌ Failed to fetch recipe count: \(error.localizedDescription)")
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
            persistenceLogger.debug("⚠️ Skipping recipe with missing required fields")
            return nil
        }
        
        guard let ingredients = try? JSONDecoder().decode([Ingredient].self, from: ingredientsData) else {
            persistenceLogger.error("❌ Failed to decode ingredients for '\(name)'")
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
        let tags = (object.value(forKey: RecipeKey.tags) as? [String]) ?? []

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
            isFavorite: isFavorite,
            tags: tags
        )
    }
}
