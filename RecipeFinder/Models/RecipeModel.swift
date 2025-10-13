import Foundation
import SwiftUI

struct Ingredient: Identifiable, Codable {
    var id: UUID = UUID()
    var baseQuantity: Double
    var unit: String
    private var _name: String
    
    var name: String {
        get { _name.capitalized }
        set { _name = newValue }
    }
    
    init(id: UUID = UUID(), baseQuantity: Double, unit: String, name: String) {
        self.id = id
        self.baseQuantity = baseQuantity
        self.unit = unit
        self._name = name
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, baseQuantity, unit
        case _name = "name"
    }
    
    // MARK: - Computed Properties (Required for scaling)
    var scaledQuantity: Double {
        baseQuantity
    }
    
    var formattedQuantity: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        
        if scaledQuantity.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", scaledQuantity)
        } else {
            return formatter.string(from: NSNumber(value: scaledQuantity)) ?? "\(scaledQuantity)"
        }
    }
}

struct RecipeModel: Identifiable, Codable {
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
        imageName: String? = nil
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
    }
    
    // MARK: - Computed Properties (Required for UI)
    var totalTime: String {
        let prepMinutes = extractMinutes(from: prepTime)
        let cookMinutes = extractMinutes(from: cookingTime)
        let total = prepMinutes + cookMinutes
        return "\(total) minutes"
    }
    
    private func extractMinutes(from timeString: String) -> Int {
        let components = timeString.components(separatedBy: " ")
        if let minutes = components.first, let value = Int(minutes) {
            return value
        }
        return 0
    }
    
    // MARK: - Scaling Methods (Required for RecipeDetailView)
    var scaledIngredients: [Ingredient] {
        let scaleFactor = Double(currentServings) / Double(baseServings)
        return ingredients.map { ingredient in
            var scaled = ingredient
            scaled.baseQuantity = ingredient.baseQuantity * scaleFactor
            return scaled
        }
    }
    
    mutating func updateServings(to servings: Int) {
        currentServings = servings
    }
}

// MARK: - Helper Function
func formattedImageName(for recipeName: String) -> String {
    return recipeName
        .lowercased()
        .replacingOccurrences(of: " ", with: "_")
        .replacingOccurrences(of: "(", with: "")
        .replacingOccurrences(of: ")", with: "")
        .replacingOccurrences(of: ",", with: "")
        .replacingOccurrences(of: "'", with: "")
        .replacingOccurrences(of: "&", with: "and")
}
