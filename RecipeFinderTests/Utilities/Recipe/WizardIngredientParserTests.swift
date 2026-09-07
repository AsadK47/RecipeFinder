import Testing
import Foundation
@testable import RecipeFinder

/// Thin adapter over `IngredientLineParser` (see `IngredientLineParserTests` for
/// the exhaustive cases). These assert the wizard surface: quantity as text, and
/// that manual entry now benefits from the shared fixes (canonical units,
/// mixed/glued numbers, prep-note retention).
@Suite("WizardIngredientParser")
struct WizardIngredientParserTests {

    @Test(
        "Splits an ingredient line into quantity, unit, and name",
        arguments: [
            // (input, quantity, unit, name)
            ("2 cups flour", "2", "cup", "flour"),
            ("1 tbsp olive oil", "1", "tbsp", "olive oil"),
            ("1/2 tsp salt", "1/2", "tsp", "salt"),
            ("3 oz butter", "3", "oz", "butter"),
            ("1 clove garlic", "1", "clove", "garlic"),
            ("1 1/2 cups sugar", "1 1/2", "cup", "sugar"),        // mixed number now handled
            ("200g flour", "200", "g", "flour"),                   // glued unit now handled
            ("2 large eggs, beaten", "2", "", "large eggs, beaten"), // prep note retained
            ("Salt", "", "", "Salt")
        ]
    )
    func parsesComponents(input: String, quantity: String, unit: String, name: String) {
        let parsed = WizardIngredientParser.parse(input)
        #expect(parsed.quantity == quantity)
        #expect(parsed.unit == unit)
        #expect(parsed.name == name)
    }

    @Test("Unicode fractions are normalised before parsing")
    func normalisesUnicodeFractionInQuantity() {
        let parsed = WizardIngredientParser.parse("¾ cup sugar")
        #expect(parsed.quantity == "3/4")
        #expect(parsed.unit == "cup")
        #expect(parsed.name == "sugar")
    }

    @Test("A bare name with no quantity or unit is preserved as the name")
    func bareNameFallsBackToName() {
        let parsed = WizardIngredientParser.parse("freshly ground pepper")
        #expect(parsed.quantity == "")
        #expect(parsed.name == "freshly ground pepper")
    }
}
