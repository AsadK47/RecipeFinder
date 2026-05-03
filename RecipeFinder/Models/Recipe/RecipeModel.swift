import Foundation
import SwiftUI

struct Ingredient: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    let baseQuantity: Double
    let unit: String
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
    
    enum CodingKeys: String, CodingKey {
        case id, baseQuantity, unit
        case _name = "name"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Ingredient, rhs: Ingredient) -> Bool {
        lhs.id == rhs.id
    }
    
    func scaledQuantity(for scaleFactor: Double) -> Double {
        baseQuantity * scaleFactor
    }
    
    func formattedQuantity(for scaleFactor: Double) -> String {
        FractionFormatter.format(scaledQuantity(for: scaleFactor))
    }
    
    func converted(to system: MeasurementSystem, scaleFactor: Double = 1.0) -> (quantity: Double, unit: String) {
        let scaledQty = scaledQuantity(for: scaleFactor)
        return UnitConversion.convert(value: scaledQty, unit: unit, to: system, ingredientName: name)
    }
    
    func formattedWithUnit(for scaleFactor: Double, system: MeasurementSystem) -> String {
        let converted = converted(to: system, scaleFactor: scaleFactor)
        let formattedValue = FractionFormatter.format(converted.quantity)
        return converted.unit.isEmpty ? formattedValue : "\(formattedValue) \(converted.unit)"
    }
    
    var displayName: String {
        return IngredientNameFormatter.formatForDisplay(name)
    }
    
    var mainIngredientName: String {
        return IngredientNameFormatter.extractMainName(name)
    }
    
    var preparationNotes: String? {
        return IngredientNameFormatter.extractPreparationNotes(name)
    }
}

struct IngredientNameFormatter {
    
    private static let preparationKeywords = [
        "diced", "chopped", "sliced", "minced", "grated", "shredded",
        "cut", "bite-sized", "pieces", "cubed", "julienned",
        "boneless", "skinless", "trimmed", "peeled", "seeded",
        "fresh", "dried", "frozen", "canned", "cooked",
        "room temperature", "softened", "melted", "beaten"
    ]
    
    static func formatForDisplay(_ name: String) -> String {
        return name.capitalized
    }
    
    static func extractMainName(_ name: String) -> String {
        let lowercased = name.lowercased()
        
        if let commaIndex = lowercased.firstIndex(of: ",") {
            let mainPart = String(name[..<commaIndex]).trimmingCharacters(in: .whitespaces)
            return removeLeadingPrepWords(mainPart)
        }
        
        return removeLeadingPrepWords(name)
    }
    
    static func extractPreparationNotes(_ name: String) -> String? {
        var notes: [String] = []
        let lowercased = name.lowercased()
        
        if let commaIndex = lowercased.firstIndex(of: ",") {
            let prepPart = String(name[name.index(after: commaIndex)...])
                .trimmingCharacters(in: .whitespaces)
            notes.append(prepPart.lowercased())
        }
        
        let words = name.components(separatedBy: .whitespaces)
        for word in words {
            let cleanWord = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
            if preparationKeywords.contains(cleanWord.lowercased()) {
                notes.append(cleanWord.lowercased())
            }
        }
        
        let uniqueNotes = Array(Set(notes)).sorted()
        return uniqueNotes.isEmpty ? nil : uniqueNotes.joined(separator: ", ")
    }
    
    private static func removeLeadingPrepWords(_ text: String) -> String {
        var words = text.components(separatedBy: .whitespaces)
        
        while let firstWord = words.first {
            let cleanedWord = firstWord.trimmingCharacters(in: CharacterSet.punctuationCharacters)
            if preparationKeywords.contains(cleanedWord.lowercased()) {
                words.removeFirst()
            } else {
                break
            }
        }
        
        return words.joined(separator: " ")
    }
}

struct DietaryInfo: Codable, Hashable {
    var isVegetarian: Bool
    var isVegan: Bool
    var isGlutenFree: Bool
    var isDairyFree: Bool
    var isNutFree: Bool
    var isLowCarb: Bool
    var isKeto: Bool
    
    init(
        isVegetarian: Bool = false,
        isVegan: Bool = false,
        isGlutenFree: Bool = false,
        isDairyFree: Bool = false,
        isNutFree: Bool = false,
        isLowCarb: Bool = false,
        isKeto: Bool = false
    ) {
        self.isVegetarian = isVegetarian
        self.isVegan = isVegan
        self.isGlutenFree = isGlutenFree
        self.isDairyFree = isDairyFree
        self.isNutFree = isNutFree
        self.isLowCarb = isLowCarb
        self.isKeto = isKeto
    }
    
    var activeTags: [String] {
        var tags: [String] = []
        if isVegetarian { tags.append("Vegetarian") }
        if isVegan { tags.append("Vegan") }
        if isGlutenFree { tags.append("Gluten-Free") }
        if isDairyFree { tags.append("Dairy-Free") }
        if isNutFree { tags.append("Nut-Free") }
        if isLowCarb { tags.append("Low-Carb") }
        if isKeto { tags.append("Keto") }
        return tags
    }
}

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
        Double(currentServings) / Double(baseServings)
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

enum FractionFormatter {
    static func toFraction(_ value: Double) -> String? {
        let tolerance = 0.001
        let whole = Int(value)
        let decimal = value - Double(whole)
        
        let fractions: [(Double, String)] = [
            (0.125, "⅛"), (0.25, "¼"), (0.333, "⅓"), (0.375, "⅜"),
            (0.5, "½"), (0.625, "⅝"), (0.666, "⅔"), (0.75, "¾"), (0.875, "⅞")
        ]
        
        for (decimalValue, fractionSymbol) in fractions {
            if abs(decimal - decimalValue) < tolerance {
                if whole == 0 {
                    return fractionSymbol
                } else {
                    return "\(whole)\(fractionSymbol)"
                }
            }
        }
        
        return nil
    }

    static func format(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        if let fraction = toFraction(value) {
            return fraction
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2g", value)
    }
}

enum TimeExtractor {
    static func extractMinutes(from timeString: String) -> Int {
        let components = timeString.components(separatedBy: " ")
        if let minutes = components.first, let value = Int(minutes) {
            return value
        }
        return 0
    }
}

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
