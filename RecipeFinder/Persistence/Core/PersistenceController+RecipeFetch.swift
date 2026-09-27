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
            return results.compactMap(Self.mapToRecipeModel)
        } catch {
            persistenceLogger.error("❌ Failed to fetch recipes: \(error.localizedDescription)")
            return []
        }
    }

    /// Off-main-thread fetch + per-recipe JSON decode on a background context; use for view loads so large libraries don't freeze the UI.
    func fetchRecipesAsync() async -> [RecipeModel] {
        guard ensureStoreIsReady(), let userId = userID() else { return [] }
        let container = self.container
        return await withCheckedContinuation { continuation in
            container.performBackgroundTask { context in
                let request = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
                request.sortDescriptors = [
                    NSSortDescriptor(
                        key: RecipeKey.name,
                        ascending: true,
                        selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))
                    )
                ]
                request.predicate = NSPredicate(format: "userId == %@", userId)
                do {
                    let results = try context.fetch(request)
                    continuation.resume(returning: results.compactMap(Self.mapToRecipeModel))
                } catch {
                    persistenceLogger.error("❌ Async recipe fetch failed: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                }
            }
        }
    }

    /// Fetches the single recipe with `id` in the current user's scope; the detail screen re-reads on appear to avoid stale in-memory copies.
    func fetchRecipe(withId id: UUID) -> RecipeModel? {
        guard ensureStoreIsReady(), let userId = userID() else { return nil }

        let context = container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.recipe)
        request.predicate = NSPredicate(format: "id == %@ AND userId == %@", id as CVarArg, userId)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first.flatMap(Self.mapToRecipeModel)
        } catch {
            persistenceLogger.error("❌ Failed to fetch recipe \(id): \(error.localizedDescription)")
            return nil
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
    
    nonisolated private static func mapToRecipeModel(_ object: NSManagedObject) -> RecipeModel? {
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
        let isSampleRecipe = object.value(forKey: RecipeKey.isSampleRecipe) as? Bool ?? false
        let tags = (object.value(forKey: RecipeKey.tags) as? [String]) ?? []
        let dietaryInfo: DietaryInfo = {
            guard let data = object.value(forKey: RecipeKey.dietaryInfo) as? Data,
                  let decoded = try? JSONDecoder().decode(DietaryInfo.self, from: data)
            else { return DietaryInfo() }
            return decoded
        }()
        let cookCount    = object.value(forKey: RecipeKey.cookCount)    as? Int ?? 0
        let lastCookedAt = object.value(forKey: RecipeKey.lastCookedAt) as? Date
        let rating       = object.value(forKey: RecipeKey.rating)       as? Int ?? 0
        let cuisine      = object.value(forKey: RecipeKey.cuisine)      as? String
        let photoNames   = (object.value(forKey: RecipeKey.photoNames)  as? [String]) ?? []

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
            tags: tags,
            dietaryInfo: dietaryInfo,
            isSampleRecipe: isSampleRecipe,
            cookCount: cookCount,
            lastCookedAt: lastCookedAt,
            rating: rating,
            cuisine: cuisine,
            photoNames: photoNames
        )
    }
}
