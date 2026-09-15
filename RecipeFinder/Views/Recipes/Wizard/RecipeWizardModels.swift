import Foundation

extension RecipeWizardView {
    /// Recipe data used to pre-populate the wizard — from an import, the share
    /// sheet, or an edit. Every field is optional so partial data can seed the
    /// form and the user fills in the rest.
    struct PrefilledRecipeData {
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
    /// Seeds the wizard from an on-device-interpreted recipe so the user reviews
    /// and edits the AI's output before saving. Category/difficulty are left nil
    /// (free text rarely states them reliably) and the one-line summary becomes
    /// the notes seed.
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
