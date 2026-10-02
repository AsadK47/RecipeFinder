import Foundation

/// Maps a recipe `Ingredient` onto a shopping-list line, so the "add to groceries" paths carry the
/// quantity and unit instead of dropping them to a bare "flour 1". Pure + static so it's unit-testable.
enum RecipeShoppingList {
    /// A grocery line: normalized buy-name, whole-unit quantity (min 1), and the ingredient's unit.
    /// Returns nil when the ingredient has no usable name.
    static func item(from ingredient: Ingredient) -> (name: String, quantity: Int, unit: String)? {
        let name = IngredientNormalizer.normalize(ingredient.mainIngredientName)
        guard !name.isEmpty else { return nil }
        let quantity = max(1, Int(round(ingredient.baseQuantity)))
        return (name: name, quantity: quantity, unit: ingredient.unit)
    }
}
