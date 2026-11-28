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

    /// The amount as the recipe gives it — unscaled, unconverted — for share, print, the import preview and the
    /// amount-estimate prompt, which all describe the recipe as written. A zero amount is nil, never "0".
    static func writtenAmount(for ingredient: Ingredient) -> Amount {
        let unit = ingredient.unit.trimmingCharacters(in: .whitespaces)
        return (ingredient.baseQuantity > 0 ? FractionFormatter.format(ingredient.baseQuantity) : nil,
                unit.isEmpty ? nil : displayUnit(unit, quantity: ingredient.baseQuantity))
    }

    /// "200 g Plain flour", "Salt and pepper, to taste" — the recipe as written.
    static func writtenLine(for ingredient: Ingredient) -> String {
        line(writtenAmount(for: ingredient), name: ingredient.displayName)
    }

    /// One line of the editor's ingredient box, which the editor parses back on save: the stored amount, unit and name
    /// unchanged, so saving an untouched recipe doesn't rewrite it (it used to save "Salt And Pepper, To Taste").
    static func editorLine(for ingredient: Ingredient) -> String {
        let unit = ingredient.unit.trimmingCharacters(in: .whitespaces)
        let quantity = ingredient.baseQuantity > 0 ? FractionFormatter.format(ingredient.baseQuantity) : nil
        let written = line((quantity, unit.isEmpty ? nil : unit), name: ingredient.writtenName)
        guard quantity == nil else { return written }
        // No amount is left out ("salt, to taste") unless the parser would then lift a number in the name as one
        // ("rice, about 200g" → 200 g): there a leading 0 keeps the amount empty, as before.
        return IngredientLineParser.parse(written).quantityText.isEmpty ? written : "0 \(written)"
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
