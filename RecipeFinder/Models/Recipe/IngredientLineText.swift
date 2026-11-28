import Foundation

/// The one home for an ingredient's "amount name" text ("200 g Butter, melted"), so the recipe screen, cook mode,
/// share, print, import preview and editor never drift apart. An amount is (quantity, unit), either part nil when absent.
enum IngredientLineText {
    typealias Amount = (quantity: String?, unit: String?)

    /// The amount column exactly as the recipe screen shows it: scaled, converted, snapped to cook-friendly fractions.
    static func amount(for ingredient: Ingredient, scaleFactor: Double, system: MeasurementSystem) -> Amount {
        let converted = UnitConversion.convert(
            value: ingredient.scaledQuantity(for: scaleFactor),
            unit: ingredient.unit,
            to: system,
            ingredientName: ingredient.name
        )
        let quantity = converted.quantity > 0 ? FractionFormatter.format(prettyQuantity(converted.quantity)) : nil
        let unit = converted.unit.isEmpty ? nil : displayUnit(converted.unit, quantity: converted.quantity)
        return (quantity, unit)
    }

    /// "200 g", "2", "pinch" — or "" when the line has no amount at all.
    static func text(_ amount: Amount) -> String {
        [amount.quantity, amount.unit].compactMap { $0 }.joined(separator: " ")
    }

    /// The amount, then the name: "200 g Butter", or just "Butter" when there's no amount.
    static func line(_ amount: Amount, name: String) -> String {
        let qty = text(amount)
        return qty.isEmpty ? name : "\(qty) \(name)"
    }

    /// The line as the recipe screen reads it (cook mode, shop sheet).
    static func line(for ingredient: Ingredient, scaleFactor: Double, system: MeasurementSystem) -> String {
        line(amount(for: ingredient, scaleFactor: scaleFactor, system: system), name: ingredient.displayName)
    }

    // Snaps converted quantities to cooking-sensible precision so conversions don't surface ugly values like "14.79 ml".
    /// Nearest of the fractions cooks use — eighths/quarters OR thirds, whichever is closer (⅓ used to become ⅜).
    static func prettyQuantity(_ q: Double) -> Double {
        guard q > 0 else { return q }
        if q >= 100 { return (q / 5).rounded() * 5 }
        if q >= 10 { return q.rounded() }
        let binary = q >= 1 ? (q * 4).rounded() / 4 : (q * 8).rounded() / 8
        let thirds = (q * 3).rounded() / 3
        return abs(thirds - q) < abs(binary - q) ? thirds : binary
    }

    /// "L" (not "l", which reads as "I") and plural cups ("2 cups", not "2 cup").
    static func displayUnit(_ unit: String, quantity: Double) -> String {
        let lower = unit.lowercased()
        if lower == "l" { return "L" }
        if lower == "cup", quantity > 1 { return "cups" }
        return lower
    }
}
