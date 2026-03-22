import Foundation
import SwiftUI

struct Ingredient: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    let baseQuantity: Double  // Changed to let - should never be mutated
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
    
    // Codable
    enum CodingKeys: String, CodingKey {
        case id, baseQuantity, unit
        case _name = "name"
    }
    
    // Hashable Conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Ingredient, rhs: Ingredient) -> Bool {
        lhs.id == rhs.id
    }
    
    // Computed Properties (Required for scaling)
    func scaledQuantity(for scaleFactor: Double) -> Double {
        baseQuantity * scaleFactor
    }
    
    func formattedQuantity(for scaleFactor: Double) -> String {
        FractionFormatter.format(scaledQuantity(for: scaleFactor))
    }
    
    // Unit Conversion (for metric/imperial)
    func converted(to system: MeasurementSystem, scaleFactor: Double = 1.0) -> (quantity: Double, unit: String) {
        let scaledQty = scaledQuantity(for: scaleFactor)
        return UnitConversion.convert(value: scaledQty, unit: unit, to: system, ingredientName: name)
    }
    
    func formattedWithUnit(for scaleFactor: Double, system: MeasurementSystem) -> String {
        let converted = converted(to: system, scaleFactor: scaleFactor)
        let formattedValue = FractionFormatter.format(converted.quantity)
        return converted.unit.isEmpty ? formattedValue : "\(formattedValue) \(converted.unit)"
    }
    
    // MARK: - Smart Name Parsing
    
    /// Returns the display name with proper title case formatting
    var displayName: String {
        return IngredientNameFormatter.formatForDisplay(name)
    }
    
    /// Returns the main ingredient name (without prep notes)
    var mainIngredientName: String {
        return IngredientNameFormatter.extractMainName(name)
    }
    
    /// Returns preparation notes if any (e.g., "diced", "chopped", "boneless")
    var preparationNotes: String? {
        return IngredientNameFormatter.extractPreparationNotes(name)
    }
}

// MARK: - Ingredient Name Formatter

struct IngredientNameFormatter {
    
    // Common preparation keywords that indicate secondary information
    private static let preparationKeywords = [
        "diced", "chopped", "sliced", "minced", "grated", "shredded",
        "cut", "bite-sized", "pieces", "cubed", "julienned",
        "boneless", "skinless", "trimmed", "peeled", "seeded",
        "fresh", "dried", "frozen", "canned", "cooked",
        "room temperature", "softened", "melted", "beaten"
    ]
    
    /// Format ingredient name with proper title case
    static func formatForDisplay(_ name: String) -> String {
        // Keep parenthetical names intact: "Fenugreek (Methi) Seeds"
        return name.capitalized
    }
    
    /// Extract the main ingredient name from a complex string
    /// "Skinless And Boneless Chicken Thighs, Cut Into Bite-Sized Pieces" → "Chicken Thighs"
    static func extractMainName(_ name: String) -> String {
        let lowercased = name.lowercased()
        
        // Check if contains comma - often separates main ingredient from prep
        if let commaIndex = lowercased.firstIndex(of: ",") {
            let mainPart = String(name[..<commaIndex]).trimmingCharacters(in: .whitespaces)
            // Remove leading prep words from main part
            return removeLeadingPrepWords(mainPart)
        }
        
        // No comma, but might have prep words at the start
        return removeLeadingPrepWords(name)
    }
    
    /// Extract preparation notes from the ingredient name
    /// "Skinless And Boneless Chicken Thighs, Cut Into Bite-Sized Pieces" → "skinless, boneless, bite-sized"
    static func extractPreparationNotes(_ name: String) -> String? {
        var notes: [String] = []
        let lowercased = name.lowercased()
        
        // Check for comma-separated prep instructions
        if let commaIndex = lowercased.firstIndex(of: ",") {
            let prepPart = String(name[name.index(after: commaIndex)...])
                .trimmingCharacters(in: .whitespaces)
            notes.append(prepPart.lowercased())
        }
        
        // Extract prep words from the beginning
        let words = name.components(separatedBy: .whitespaces)
        for word in words {
            let cleanWord = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
            if preparationKeywords.contains(cleanWord.lowercased()) {
                notes.append(cleanWord.lowercased())
            }
        }
        
        // Remove duplicates and format
        let uniqueNotes = Array(Set(notes)).sorted()
        return uniqueNotes.isEmpty ? nil : uniqueNotes.joined(separator: ", ")
    }
    
    /// Remove leading preparation words
    private static func removeLeadingPrepWords(_ text: String) -> String {
        var words = text.components(separatedBy: .whitespaces)
        
        // Remove prep words from the beginning
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

// MARK: - Dietary Info

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
    
    //  Hashable Conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: RecipeModel, rhs: RecipeModel) -> Bool {
        lhs.id == rhs.id &&
        lhs.currentServings == rhs.currentServings &&
        lhs.ingredients == rhs.ingredients &&
        lhs.isFavorite == rhs.isFavorite
    }
    
    //  Computed Properties (Required for UI)
    var totalTime: String {
        let prepMinutes = TimeExtractor.extractMinutes(from: prepTime)
        let cookMinutes = TimeExtractor.extractMinutes(from: cookingTime)
        let total = prepMinutes + cookMinutes
        return "\(total) minutes"
    }
    
    //  Scaling Methods (Required for RecipeDetailView)
    var scaleFactor: Double {
        Double(currentServings) / Double(baseServings)
    }
    
    mutating func updateServings(to servings: Int) {
        currentServings = servings
    }
    
    // MARK: - Ingredient Matching
    
    /// Check if recipe contains a specific ingredient (fuzzy matching)
    func containsIngredient(_ searchTerm: String) -> Bool {
        let normalized = searchTerm.lowercased().trimmingCharacters(in: .whitespaces)
        return ingredients.contains { ingredient in
            ingredient.name.lowercased().contains(normalized) ||
            ingredient.mainIngredientName.lowercased().contains(normalized)
        }
    }
    
    /// Get percentage of ingredients you have
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
    
    /// Get list of missing ingredients
    func missingIngredients(from availableIngredients: Set<String>) -> [Ingredient] {
        ingredients.filter { ingredient in
            let mainName = ingredient.mainIngredientName.lowercased()
            return !availableIngredients.contains { available in
                mainName.contains(available.lowercased()) ||
                available.lowercased().contains(mainName)
            }
        }
    }
    
    // MARK: - Convenience Initializers
    
    /// Simplified initializer for quick snacks with minimal data
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

// MARK: - Fraction Formatter

enum FractionFormatter {
    /// Converts a decimal to a fraction string (e.g., 0.5 → "½", 1.5 → "1½", 0.75 → "¾")
    static func toFraction(_ value: Double) -> String? {
        let tolerance = 0.001
        let whole = Int(value)
        let decimal = value - Double(whole)
        
        // Check common fractions
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

    /// Single canonical formatter used everywhere a quantity is displayed.
    /// Whole numbers → "2", known fractions → "1½", everything else → up to 2 decimal places.
    static func format(_ value: Double) -> String {
        // Whole number — no decimal noise
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        // Known fraction symbol (handles both < 1 and mixed numbers like 1.5)
        if let fraction = toFraction(value) {
            return fraction
        }
        // Fallback: up to 2 significant decimal places, no trailing zeros
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2g", value)
    }
}

// Time Extraction Helper
enum TimeExtractor {
    static func extractMinutes(from timeString: String) -> Int {
        let components = timeString.components(separatedBy: " ")
        if let minutes = components.first, let value = Int(minutes) {
            return value
        }
        return 0
    }
}

// Helper Function
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
