import Foundation

/// Content fields that differ between a stored recipe and a freshly-fetched upstream; personal data (notes, tags, servings, ratings, cook history) is never included and always preserved on apply.
enum RecipeDiffField: String, CaseIterable, Hashable {
    case name
    case ingredients
    case instructions
    case prepTime
    case cookingTime
    case difficulty
    case category
    case cuisine
    case imageName

    var displayName: String {
        switch self {
        case .name:         "Recipe Name"
        case .ingredients:  "Ingredients"
        case .instructions: "Instructions"
        case .prepTime:     "Prep Time"
        case .cookingTime:  "Cook Time"
        case .difficulty:   "Difficulty"
        case .category:     "Category"
        case .cuisine:      "Cuisine"
        case .imageName:    "Hero Image"
        }
    }
}

struct RecipeDiff: Identifiable {
    let changed: Set<RecipeDiffField>
    let stored: RecipeModel
    let upstream: RecipeModel

    // Identifiable so the refresh sheet presents via `.sheet(item:)` — content rebuilds from the diff rather than
    // reading a separately-set `@State`, which rendered an empty sheet on first open.
    var id: UUID { stored.id }

    var hasChanges: Bool { !changed.isEmpty }

    /// Fields ticked when the review sheet opens. A source refresh pre-ticks every change; a re-import from the original
    /// text ticks nothing, since a re-parse can be noisier than what the user already fixed by hand.
    func initialSelection(isReimport: Bool) -> Set<RecipeDiffField> {
        isReimport ? [] : changed
    }

    /// Content fields differing between `stored` and `upstream`; ingredient equality is content-based (each import assigns new UUIDs).
    static func compute(stored: RecipeModel, upstream: RecipeModel) -> RecipeDiff {
        var changed = Set<RecipeDiffField>()
        if stored.name != upstream.name                             { changed.insert(.name) }
        if !ingredientsContentEqual(stored.ingredients, upstream.ingredients) { changed.insert(.ingredients) }
        if stored.instructions != upstream.instructions             { changed.insert(.instructions) }
        if stored.prepTime != upstream.prepTime                     { changed.insert(.prepTime) }
        if stored.cookingTime != upstream.cookingTime               { changed.insert(.cookingTime) }
        if stored.difficulty != upstream.difficulty                 { changed.insert(.difficulty) }
        if stored.category != upstream.category                     { changed.insert(.category) }
        if stored.cuisine != upstream.cuisine                       { changed.insert(.cuisine) }
        if stored.imageName != upstream.imageName                   { changed.insert(.imageName) }
        return RecipeDiff(changed: changed, stored: stored, upstream: upstream)
    }

    private static func ingredientsContentEqual(_ a: [Ingredient], _ b: [Ingredient]) -> Bool {
        guard a.count == b.count else { return false }
        return zip(a, b).allSatisfy {
            $0.baseQuantity == $1.baseQuantity && $0.unit == $1.unit && $0.name == $1.name
        }
    }

    /// New recipe with only `selections` replaced by upstream; personal data (notes, tags, servings, ratings, cook history, gallery) carried from `stored` unchanged.
    func applying(selections: Set<RecipeDiffField>) -> RecipeModel {
        RecipeModel(
            id:                  stored.id,
            name:                selections.contains(.name)         ? upstream.name         : stored.name,
            category:            selections.contains(.category)     ? upstream.category     : stored.category,
            difficulty:          selections.contains(.difficulty)   ? upstream.difficulty   : stored.difficulty,
            prepTime:            selections.contains(.prepTime)     ? upstream.prepTime     : stored.prepTime,
            cookingTime:         selections.contains(.cookingTime)  ? upstream.cookingTime  : stored.cookingTime,
            baseServings:        stored.baseServings,
            currentServings:     stored.currentServings,
            ingredients:         selections.contains(.ingredients)  ? upstream.ingredients  : stored.ingredients,
            prePrepInstructions: stored.prePrepInstructions,
            instructions:        selections.contains(.instructions) ? upstream.instructions : stored.instructions,
            notes:               stored.notes,
            imageName:           selections.contains(.imageName)    ? upstream.imageName    : stored.imageName,
            isFavorite:          stored.isFavorite,
            tags:                stored.tags,
            dietaryInfo:         stored.dietaryInfo,
            isSampleRecipe:      stored.isSampleRecipe,
            cookCount:           stored.cookCount,
            lastCookedAt:        stored.lastCookedAt,
            rating:              stored.rating,
            cuisine:             selections.contains(.cuisine)      ? upstream.cuisine      : stored.cuisine,
            photoNames:          stored.photoNames,
            sourceText:          stored.sourceText
        )
    }
}

extension RecipeDiff {
    /// Diff for "Re-import from original": the stored recipe vs a fresh parse of its saved `sourceText`. A field the
    /// parse didn't find keeps the stored value, so a weaker parse never proposes blanking something.
    static func reimport(stored: RecipeModel, prefill: RecipeWizardView.PrefilledRecipeData) -> RecipeDiff {
        let ingredientParser = RecipeImportBuilder()
        let ingredients = (prefill.ingredients ?? [])
            .filter { !$0.trimmed.isEmpty }
            .map { ingredientParser.parseIngredient($0) }
        let instructions = (prefill.instructions ?? []).filter { !$0.trimmed.isEmpty }
        let name = prefill.name?.trimmed ?? ""
        let category = prefill.category?.trimmed ?? ""
        let cuisine = prefill.cuisine?.trimmed ?? ""
        let difficulty = prefill.difficulty?.trimmed ?? ""
        func minutes(_ value: Int?, else fallback: String) -> String {
            guard let value, value > 0 else { return fallback }
            return "\(value) minutes"
        }

        let upstream = RecipeModel(
            id: stored.id,
            name: name.isEmpty ? stored.name : name,
            category: category.isEmpty ? stored.category : category,
            difficulty: difficulty.isEmpty ? stored.difficulty : RecipeWizardBuilder.normalizeDifficulty(difficulty),
            prepTime: minutes(prefill.prepTime, else: stored.prepTime),
            cookingTime: minutes(prefill.cookTime, else: stored.cookingTime),
            baseServings: stored.baseServings,
            ingredients: ingredients.isEmpty ? stored.ingredients : ingredients,
            prePrepInstructions: stored.prePrepInstructions,
            instructions: instructions.isEmpty ? stored.instructions : instructions,
            notes: stored.notes,
            imageName: stored.imageName,
            cuisine: cuisine.isEmpty ? stored.cuisine : cuisine
        )
        return compute(stored: stored, upstream: upstream)
    }
}
