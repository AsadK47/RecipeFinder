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
    }

    /// A single editable ingredient row in the wizard's ingredients step.
    struct IngredientItem: Identifiable {
        let id = UUID()
        var quantity: String = ""
        var unit: String = ""
        var name: String = ""
    }
}

extension RecipeWizardView.PrefilledRecipeData {
    /// Seeds the wizard from an on-device-interpreted recipe for user review; category/difficulty left nil (unreliable in free text), summary becomes the notes seed.
    init(interpreted recipe: InterpretedRecipe) {
        let summary = recipe.summary?.trimmingCharacters(in: .whitespacesAndNewlines)
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
    }
}
