import Foundation

extension RecipeWizardView {
    /// Data to pre-populate the wizard (import/share/edit); every field optional so partial data seeds the form.
    /// Identifiable (fresh `id` per instance) so callers present it via `.sheet(item:)` — rebuilding content from
    /// the value avoids the stale-first-render race of `.sheet(isPresented:)` + a separately-set prefill.
    struct PrefilledRecipeData: Identifiable {
        let id = UUID()
        let name: String?
        let description: String?
        let ingredients: [String]?
        let instructions: [String]?
        var prePrepInstructions: [String]? = nil
        let prepTime: Int?
        let cookTime: Int?
        let servings: Int?
        let difficulty: String?
        let notes: String?
        let category: String?
        let isFavorite: Bool?
        let imageURL: String?
        var tags: [String]? = nil
        var cuisine: String? = nil
        var galleryImageURLs: [String]? = nil
        /// The text this came from (paste, OCR, share, page text), saved on the recipe for "Re-import from original".
        var sourceText: String? = nil
        /// How sure the import was (URL parser confidence; 1.0 for an on-device AI read); nil = judge from content.
        var sourceConfidence: Double? = nil
    }

    /// A single editable ingredient row in the wizard's ingredients step.
    struct IngredientItem: Identifiable {
        let id = UUID()
        var quantity: String = ""
        var unit: String = ""
        var name: String = ""
        /// Ingredient group ("For the sauce"); empty = ungrouped.
        var section: String = ""
    }
}

extension RecipeWizardView.PrefilledRecipeData {
    /// Seeds the wizard from an on-device-interpreted recipe for user review; category/difficulty left nil (unreliable in free text), summary becomes the notes seed.
    init(interpreted recipe: InterpretedRecipe) {
        let summary = recipe.summary?.trimmed
        self.init(
            name: recipe.name,
            description: nil,
            ingredients: recipe.ingredients.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty },
            instructions: recipe.steps.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty },
            prepTime: recipe.prepMinutes,
            cookTime: recipe.cookMinutes,
            servings: recipe.servings,
            difficulty: nil,
            notes: (summary?.isEmpty == false) ? summary : nil,
            category: nil,
            isFavorite: nil,
            imageURL: nil
        )
        sourceConfidence = 1.0
    }
}

extension RecipeWizardView.PrefilledRecipeData {
    static let maxUnparsedNameLength = 80

    /// "Start from this text" after an import found no recipe: first line as the name, the whole text as notes and
    /// source, rows left empty — the cook keeps what they pasted instead of retyping it.
    init(unparsedText text: String) {
        let firstLine = text.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty }
        let notes = text.trimmed
        self.init(
            name: firstLine.map { String($0.prefix(Self.maxUnparsedNameLength)) },
            description: nil,
            ingredients: nil,
            instructions: nil,
            prepTime: nil,
            cookTime: nil,
            servings: nil,
            difficulty: nil,
            notes: notes.isEmpty ? nil : text,
            category: nil,
            isFavorite: nil,
            imageURL: nil,
            sourceText: RecipeImportPipeline.storedSourceText(text)
        )
    }
}

extension RecipeWizardView.PrefilledRecipeData {
    /// Editor prefill for a saved or just-imported recipe — one mapping shared by "Edit" and URL-import review.
    init(recipe: RecipeModel) {
        self.init(
            name: recipe.name,
            description: nil,
            // FractionFormatter shows ⅓ rather than "0.333333"; the editor's save path parses fractions back.
            ingredients: IngredientSections.lines(recipe.ingredients, section: \.section) {
                "\(FractionFormatter.format($0.baseQuantity)) \($0.unit) \($0.name)"
            },
            instructions: recipe.instructions,
            prePrepInstructions: recipe.prePrepInstructions,
            prepTime: TimeExtractor.extractMinutes(from: recipe.prepTime),
            cookTime: TimeExtractor.extractMinutes(from: recipe.cookingTime),
            servings: recipe.baseServings,
            difficulty: recipe.difficulty,
            notes: recipe.notes.isEmpty ? nil : recipe.notes,
            category: recipe.category,
            isFavorite: recipe.isFavorite,
            imageURL: recipe.imageName,
            tags: recipe.tags.isEmpty ? nil : recipe.tags,
            cuisine: recipe.cuisine,
            galleryImageURLs: recipe.photoNames.isEmpty ? nil : recipe.photoNames,
            sourceText: recipe.sourceText
        )
    }
}
