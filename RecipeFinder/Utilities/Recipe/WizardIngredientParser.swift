import Foundation

/// Thin adapter over the shared `IngredientLineParser` splitting a line into quantity/unit/name for the wizard's editable fields (quantity surfaced as text) so manual and import parse identically.
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
