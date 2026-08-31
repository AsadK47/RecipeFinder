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
    }

    /// A single editable ingredient row in the wizard's ingredients step.
    struct IngredientItem: Identifiable {
        let id = UUID()
        var quantity: String = ""
        var unit: String = ""
        var name: String = ""
    }
}
