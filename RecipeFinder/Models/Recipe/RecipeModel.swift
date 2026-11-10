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
    /// The raw text a recipe was imported from (page text, paste or OCR), kept so it can be re-imported later.
    var sourceText: String?

    enum CodingKeys: String, CodingKey {
        case id, name, category, difficulty, prepTime, cookingTime
        case baseServings, currentServings, ingredients
        case prePrepInstructions, instructions, notes
        case imageName, isFavorite, tags, dietaryInfo, isSampleRecipe
        case cookCount, lastCookedAt, rating, cuisine, photoNames, sourceText
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
        self.sourceText = sourceText
    }

    // Custom decoder so pre-v13 backups lacking new keys decode with safe defaults instead of throwing .keyNotFound.
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
        sourceText          =  try? c.decodeIfPresent(String.self,     forKey: .sourceText)
    }
    
    // Mirror the fields `==` compares, not just `id`, so content-keyed caches invalidate on rating/photo changes.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(currentServings)
        hasher.combine(ingredients)
        hasher.combine(isFavorite)
        hasher.combine(cookCount)
        hasher.combine(rating)
        hasher.combine(cuisine)
        hasher.combine(photoNames)
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
    
    /// Image for lists/cards: main image if set, else the first post-cook photo.
    var heroImageName: String? {
        if let imageName, !imageName.isEmpty { return imageName }
        return photoNames.first
    }

    /// False when no time is known (imports without timings) — cards hide the clock rather than show "0 minutes".
    var hasTotalTime: Bool {
        TimeExtractor.extractMinutes(from: prepTime) + TimeExtractor.extractMinutes(from: cookingTime) > 0
    }

    var totalTime: String {
        let prepMinutes = TimeExtractor.extractMinutes(from: prepTime)
        let cookMinutes = TimeExtractor.extractMinutes(from: cookingTime)
        return DurationFormatter.label(minutes: prepMinutes + cookMinutes)
    }

    // "Not set" rather than a fake "0 minutes" when the source gave no time (the card stays tappable to add one).
    var prepTimeDisplay: String { Self.timeLabel(TimeExtractor.extractMinutes(from: prepTime)) }
    var cookTimeDisplay: String { Self.timeLabel(TimeExtractor.extractMinutes(from: cookingTime)) }

    private static func timeLabel(_ minutes: Int) -> String {
        minutes > 0 ? DurationFormatter.label(minutes: minutes) : "Not set"
    }
    
    var scaleFactor: Double {
        // A zero base would make this infinite; Int(infinity) traps downstream in FractionFormatter.
        guard baseServings > 0 else { return 1.0 }
        return Double(currentServings) / Double(baseServings)
    }
    
    var nutritionInfo: NutritionInfo? {
        // Per-serving nutrition must divide by `baseServings`, never `currentServings`, or figures drift as the user scales.
        NutritionCalculator.calculate(ingredients: ingredients, servings: baseServings)
    }

    /// Import URL derived from the last line of notes; nil for manual recipes or notes with no trailing URL.
    var importedFromURL: URL? {
        guard let lastLine = notes.components(separatedBy: "\n")
            .last(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }),
              let url = URL(string: lastLine),
              url.scheme == "https" || url.scheme == "http" else { return nil }
        return url
    }

    /// "Re-import from original" re-parses saved text. Link imports keep only script-stripped page text (the
    /// structured data is gone), so they use refresh-from-source instead; an empty capture can never parse.
    var canReimportFromOriginal: Bool {
        importedFromURL == nil && sourceText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    /// Whether opening the recipe should re-check its source page for changes: the user's own URL imports only.
    /// Bundled recipes are a fixed snapshot — checking would hit a third-party site on every open and always "differ".
    var shouldAutoRefreshFromSource: Bool {
        importedFromURL != nil && !isSampleRecipe
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

    /// Whether the normalised pantry covers `ingredient`, via the word-boundary matcher so "ice" doesn't satisfy "rice".
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
        self.sourceText = nil
    }
}

extension RecipeModel {
    /// True when a cook was already logged today — finishing cooking mode logs one, so the manual
    /// "Mark as Cooked" button is disabled to stop an accidental second tap double-counting.
    func wasCookedToday(now: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard let lastCookedAt else { return false }
        return calendar.isDate(lastCookedAt, inSameDayAs: now)
    }

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
