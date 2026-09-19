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
    var imageName: String?
    var isFavorite: Bool
    var tags: [String]
    var dietaryInfo: DietaryInfo
    var isSampleRecipe: Bool
    var cookCount: Int
    var lastCookedAt: Date?
    var rating: Int         // 0 = unrated, 1–5
    var cuisine: String?
    var photoNames: [String]

    enum CodingKeys: String, CodingKey {
        case id, name, category, difficulty, prepTime, cookingTime
        case baseServings, currentServings, ingredients
        case prePrepInstructions, instructions, notes
        case imageName, isFavorite, tags, dietaryInfo, isSampleRecipe
        case cookCount, lastCookedAt, rating, cuisine, photoNames
    }

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
        isSampleRecipe: Bool = false,
        cookCount: Int = 0,
        lastCookedAt: Date? = nil,
        rating: Int = 0,
        cuisine: String? = nil,
        photoNames: [String] = []
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
        self.cookCount = cookCount
        self.lastCookedAt = lastCookedAt
        self.rating = rating
        self.cuisine = cuisine
        self.photoNames = photoNames
    }

    // Custom decoder so old backups (pre-v13) that lack the new keys still
    // decode cleanly with safe defaults rather than throwing .keyNotFound.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                  = try c.decode(UUID.self,          forKey: .id)
        name                = try c.decode(String.self,        forKey: .name)
        category            = try c.decode(String.self,        forKey: .category)
        difficulty          = try c.decode(String.self,        forKey: .difficulty)
        prepTime            = try c.decode(String.self,        forKey: .prepTime)
        cookingTime         = try c.decode(String.self,        forKey: .cookingTime)
        baseServings        = try c.decode(Int.self,           forKey: .baseServings)
        currentServings     = try c.decode(Int.self,           forKey: .currentServings)
        ingredients         = try c.decode([Ingredient].self,  forKey: .ingredients)
        prePrepInstructions = try c.decode([String].self,      forKey: .prePrepInstructions)
        instructions        = try c.decode([String].self,      forKey: .instructions)
        notes               = try c.decode(String.self,        forKey: .notes)
        imageName           = try c.decodeIfPresent(String.self,   forKey: .imageName)
        isFavorite          = try c.decode(Bool.self,              forKey: .isFavorite)
        tags                = (try? c.decodeIfPresent([String].self,   forKey: .tags))       ?? []
        dietaryInfo         = (try? c.decodeIfPresent(DietaryInfo.self, forKey: .dietaryInfo)) ?? DietaryInfo()
        isSampleRecipe      = (try? c.decodeIfPresent(Bool.self,       forKey: .isSampleRecipe)) ?? false
        cookCount           = (try? c.decodeIfPresent(Int.self,        forKey: .cookCount))   ?? 0
        lastCookedAt        =  try? c.decodeIfPresent(Date.self,       forKey: .lastCookedAt)
        rating              = (try? c.decodeIfPresent(Int.self,        forKey: .rating))      ?? 0
        cuisine             =  try? c.decodeIfPresent(String.self,     forKey: .cuisine)
        photoNames          = (try? c.decodeIfPresent([String].self,   forKey: .photoNames))  ?? []
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: RecipeModel, rhs: RecipeModel) -> Bool {
        lhs.id == rhs.id &&
        lhs.currentServings == rhs.currentServings &&
        lhs.ingredients == rhs.ingredients &&
        lhs.isFavorite == rhs.isFavorite &&
        lhs.cookCount == rhs.cookCount &&
        lhs.rating == rhs.rating &&
        lhs.cuisine == rhs.cuisine &&
        lhs.photoNames == rhs.photoNames
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
    
    var nutritionInfo: NutritionInfo? {
        NutritionCalculator.calculate(ingredients: ingredients, servings: currentServings)
    }

    /// URL this recipe was imported from, derived from the last line of notes.
    /// Returns nil for manually created recipes or notes with no trailing URL.
    var importedFromURL: URL? {
        guard let lastLine = notes.components(separatedBy: "\n")
            .last(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }),
              let url = URL(string: lastLine),
              url.scheme == "https" || url.scheme == "http" else { return nil }
        return url
    }

    /// Notes with the auto-generated import footer ("Imported · date\nURL") stripped.
    var notesForDisplay: String {
        guard importedFromURL != nil else { return notes }
        var lines = notes.components(separatedBy: "\n")
        if let idx = lines.lastIndex(where: { $0.hasPrefix("Imported ·") }) {
            lines = Array(lines[..<idx])
        }
        while lines.last?.trimmingCharacters(in: .whitespaces).isEmpty == true {
            lines.removeLast()
        }
        return lines.joined(separator: "\n")
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

        let pantry = Self.normalizedPantry(availableIngredients)
        let matchCount = ingredients.filter { Self.isSatisfied($0, by: pantry) }.count
        return Double(matchCount) / Double(ingredients.count)
    }

    func missingIngredients(from availableIngredients: Set<String>) -> [Ingredient] {
        let pantry = Self.normalizedPantry(availableIngredients)
        return ingredients.filter { !Self.isSatisfied($0, by: pantry) }
    }

    /// Normalises pantry terms once for reuse across a batch of ingredient checks.
    private static func normalizedPantry(_ availableIngredients: Set<String>) -> Set<String> {
        Set(availableIngredients
            .map { KitchenRecipeMatcher.normalizedTerm($0) }
            .filter { !$0.isEmpty })
    }

    /// Whether `ingredient` is covered by the (already normalised) pantry, using
    /// the shared word-boundary matcher so short terms don't match inside longer
    /// words (e.g. "ice" must not satisfy "rice").
    private static func isSatisfied(_ ingredient: Ingredient, by pantry: Set<String>) -> Bool {
        let term = KitchenRecipeMatcher.normalizedTerm(ingredient.name)
        guard !term.isEmpty else { return false }
        return pantry.contains { KitchenRecipeMatcher.ingredientMatches(term, $0) }
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
        self.cookCount = 0
        self.lastCookedAt = nil
        self.rating = 0
        self.cuisine = nil
        self.photoNames = []
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
