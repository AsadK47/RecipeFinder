import CoreData
import Foundation

/// `RecipeSaveParameters` and `populate`, the mapping onto a managed object used by saves, seeding, background
/// updates and remote-change merging. (`updateRecipe` still keeps its own field list.)
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
        let sourceText: String?

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
            photoNames: [String] = [],
            sourceText: String? = nil
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
            self.sourceText = sourceText
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
            self.sourceText = recipe.sourceText
        }
    }

    /// Maps `RecipeSaveParameters` onto a new or existing managed object (`saveRecipe`, `seedRecipes`,
    /// `updateRecipesInBackground`, remote-change merging). Returns false only if ingredients can't be encoded.
    nonisolated static func populate(
        _ recipe: NSManagedObject,
        from parameters: RecipeSaveParameters
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
        recipe.setValue(parameters.sourceText, forKey: RecipeKey.sourceText)
        if let dietaryData = try? JSONEncoder().encode(parameters.dietaryInfo) {
            recipe.setValue(dietaryData, forKey: RecipeKey.dietaryInfo)
        }
        return true
    }
}
