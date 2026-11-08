import Foundation

/// Maps a recipe `Ingredient` onto a shopping-list line, so the "add to groceries" paths carry the
/// quantity and unit instead of dropping them to a bare "flour 1". Pure + static so it's unit-testable.
enum RecipeShoppingList {
    /// Cupboard measures: you buy a jar or bottle, not "⅛ tsp". Grocery quantities are whole numbers, so these
    /// used to round up to "1 tsp" and then sum across recipes into nonsense like "Salt 2 tsp".
    private static let cupboardUnits: Set<String> = [
        "tsp", "teaspoon", "teaspoons", "tbsp", "tablespoon", "tablespoons",
        "pinch", "pinches", "dash", "dashes", "splash", "drizzle", "sprinkle", "to taste",
    ]

    /// Bulk units whose fractional amounts are better expressed as a whole smaller unit (0.5 kg → 500 g).
    private static let smallerUnit: [String: (unit: String, factor: Double)] = [
        "kg": ("g", 1000), "kilogram": ("g", 1000), "kilograms": ("g", 1000),
        "l": ("ml", 1000), "litre": ("ml", 1000), "litres": ("ml", 1000), "liter": ("ml", 1000), "liters": ("ml", 1000),
        "lb": ("oz", 16), "lbs": ("oz", 16), "pound": ("oz", 16), "pounds": ("oz", 16),
    ]

    /// A grocery line: normalized buy-name, whole-number quantity (min 1) and unit, for the recipe scaled by
    /// `scaleFactor` (current servings ÷ base). Returns nil when the ingredient has no usable name.
    static func item(from ingredient: Ingredient, scaleFactor: Double = 1) -> (name: String, quantity: Int, unit: String)? {
        let name = IngredientNormalizer.normalize(ingredient.mainIngredientName)
        guard !name.isEmpty else { return nil }

        let unitKey = ingredient.unit.trimmingCharacters(in: .whitespaces.union(.init(charactersIn: "."))).lowercased()
        if cupboardUnits.contains(unitKey) {
            return (name: name, quantity: 1, unit: "")
        }

        let amount = max(0, ingredient.baseQuantity * scaleFactor)
        if amount != amount.rounded(), let smaller = smallerUnit[unitKey] {
            return (name: name, quantity: max(1, Int((amount * smaller.factor).rounded())), unit: smaller.unit)
        }
        // Round anything else to the nearest whole (1.5 cups → 2), never below 1.
        return (name: name, quantity: max(1, Int(amount.rounded())), unit: ingredient.unit)
    }
}
