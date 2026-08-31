import Foundation
import SwiftUI

struct RecipeModel: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    let name: String
    let category: String
    let difficulty: String
    let prepTime: String
    let cookingTime: String
    let baseServings: Int
    var currentServings: Int
    var ingredients: [Ingredient]
    let prePrepInstructions: [String]
    let instructions: [String]
    let notes: String
    let imageName: String?
    var isFavorite: Bool
    var tags: [String]
    var dietaryInfo: DietaryInfo
    var isSampleRecipe: Bool

    init(
        id: UUID = UUID(),
        name: String,
        category: String,
        difficulty: String,
        prepTime: String,
        cookingTime: String,
        baseServings: Int,
        currentServings: Int? = nil,
        ingredients: [Ingredient],
        prePrepInstructions: [String],
        instructions: [String],
        notes: String,
        imageName: String? = nil,
        isFavorite: Bool = false,
        tags: [String] = [],
        dietaryInfo: DietaryInfo = DietaryInfo(),
        isSampleRecipe: Bool = false
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.difficulty = difficulty
        self.prepTime = prepTime
        self.cookingTime = cookingTime
        self.baseServings = baseServings
        self.currentServings = currentServings ?? baseServings
        self.ingredients = ingredients
        self.prePrepInstructions = prePrepInstructions
        self.instructions = instructions
        self.notes = notes
        self.imageName = imageName
        self.isFavorite = isFavorite
        self.tags = tags
        self.dietaryInfo = dietaryInfo
        self.isSampleRecipe = isSampleRecipe
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: RecipeModel, rhs: RecipeModel) -> Bool {
        lhs.id == rhs.id &&
        lhs.currentServings == rhs.currentServings &&
        lhs.ingredients == rhs.ingredients &&
        lhs.isFavorite == rhs.isFavorite
    }
    
    var totalTime: String {
        let prepMinutes = TimeExtractor.extractMinutes(from: prepTime)
        let cookMinutes = TimeExtractor.extractMinutes(from: cookingTime)
        let total = prepMinutes + cookMinutes
        return "\(total) minutes"
    }
    
    var scaleFactor: Double {
        // A zero base (possible via imports or old data) would make this
        // infinite, and Int(infinity) traps downstream in FractionFormatter.
        guard baseServings > 0 else { return 1.0 }
        return Double(currentServings) / Double(baseServings)
    }
    
    mutating func updateServings(to servings: Int) {
        currentServings = servings
    }
    
    func containsIngredient(_ searchTerm: String) -> Bool {
        let normalized = searchTerm.lowercased().trimmingCharacters(in: .whitespaces)
        return ingredients.contains { ingredient in
            ingredient.name.lowercased().contains(normalized) ||
            ingredient.mainIngredientName.lowercased().contains(normalized)
        }
    }
    
    func ingredientMatchPercentage(availableIngredients: Set<String>) -> Double {
        guard !ingredients.isEmpty else { return 0 }
        
        let matchCount = ingredients.filter { ingredient in
            let mainName = ingredient.mainIngredientName.lowercased()
            return availableIngredients.contains { available in
                mainName.contains(available.lowercased()) ||
                available.lowercased().contains(mainName)
            }
        }.count
        
        return Double(matchCount) / Double(ingredients.count)
    }
    
    func missingIngredients(from availableIngredients: Set<String>) -> [Ingredient] {
        ingredients.filter { ingredient in
            let mainName = ingredient.mainIngredientName.lowercased()
            return !availableIngredients.contains { available in
                mainName.contains(available.lowercased()) ||
                available.lowercased().contains(mainName)
            }
        }
    }
    
    init(
        name: String,
        ingredients: [Ingredient],
        instructions: String,
        prepTime: String,
        category: String,
        difficulty: Int,
        currentServings: Int,
        baseServings: Int,
        defaultServings: Int,
        isFavorite: Bool,
        imageName: String?,
        notes: String
    ) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.difficulty = "\(difficulty)"
        self.prepTime = prepTime
        self.cookingTime = "0 min"
        self.baseServings = baseServings
        self.currentServings = currentServings
        self.ingredients = ingredients
        self.prePrepInstructions = []
        self.instructions = [instructions]
        self.notes = notes
        self.imageName = imageName
        self.isFavorite = isFavorite
        self.tags = []
        self.dietaryInfo = DietaryInfo()
        self.isSampleRecipe = false
    }
}

extension RecipeModel {
    /// Plain-text representation of the recipe for sharing via the system share sheet
    var shareText: String {
        var lines: [String] = []
        
        lines.append("🍳 \(name)")
        
        var metadata: [String] = []
        if !category.isEmpty { metadata.append(category) }
        if !difficulty.isEmpty { metadata.append(difficulty) }
        if !metadata.isEmpty {
            lines.append(metadata.joined(separator: " • "))
        }
        
        var timings: [String] = []
        if !prepTime.isEmpty { timings.append("Prep: \(prepTime)") }
        if !cookingTime.isEmpty { timings.append("Cook: \(cookingTime)") }
        timings.append("Serves: \(baseServings)")
        lines.append("⏱ " + timings.joined(separator: " • "))
        
        if !ingredients.isEmpty {
            lines.append("")
            lines.append("Ingredients:")
            for ingredient in ingredients {
                let quantity = FractionFormatter.format(ingredient.baseQuantity)
                let unit = ingredient.unit.isEmpty ? "" : " \(ingredient.unit)"
                lines.append("• \(quantity)\(unit) \(ingredient.name)")
            }
        }
        
        if !prePrepInstructions.isEmpty {
            lines.append("")
            lines.append("Preparation:")
            for (index, step) in prePrepInstructions.enumerated() {
                lines.append("\(index + 1). \(step)")
            }
        }
        
        if !instructions.isEmpty {
            lines.append("")
            lines.append("Instructions:")
            for (index, step) in instructions.enumerated() {
                lines.append("\(index + 1). \(step)")
            }
        }
        
        if !notes.isEmpty {
            lines.append("")
            lines.append("Notes: \(notes)")
        }
        
        lines.append("")
        lines.append("Shared from RecipeFinder 🧡")
        
        return lines.joined(separator: "\n")
    }
}
