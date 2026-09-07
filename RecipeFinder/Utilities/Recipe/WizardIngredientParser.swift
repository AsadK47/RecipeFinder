import Foundation

/// Splits a free-text ingredient line (e.g. "2 cups flour") into quantity, unit,
/// and name for the manual wizard's editable fields. A thin adapter over the
/// shared `IngredientLineParser` (the single source of truth) so manual entry and
/// import parse identically — it just surfaces the quantity as text for the
/// editable field.
enum WizardIngredientParser {

    struct Parsed: Equatable {
        var quantity: String
        var unit: String
        var name: String
    }

    static func parse(_ fullIngredient: String) -> Parsed {
        let parsed = IngredientLineParser.parse(fullIngredient)
        return Parsed(quantity: parsed.quantityText, unit: parsed.unit, name: parsed.name)
    }
}
