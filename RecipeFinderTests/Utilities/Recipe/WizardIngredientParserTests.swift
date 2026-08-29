import Testing
import Foundation
@testable import RecipeFinder

@Suite("WizardIngredientParser")
struct WizardIngredientParserTests {

    // MARK: - parse

    @Test(
        "Splits an ingredient line into quantity, unit, and name",
        arguments: [
            // (input, quantity, unit, name)
            ("2 cups flour", "2", "cups", "flour"),
            ("1 tbsp olive oil", "1", "tbsp", "olive oil"),
            ("1/2 tsp salt", "1/2", "tsp", "salt"),
            ("3 oz butter", "3", "oz", "butter"),
            ("1 clove garlic", "1", "clove", "garlic"),
            ("2 large eggs, beaten", "2", "", "large eggs"),
            ("Salt", "", "", "Salt")
        ]
    )
    func parsesComponents(
        input: String, quantity: String, unit: String, name: String
    ) {
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

    // MARK: - normaliseUnicodeFractions

    @Test(
        "Each unicode fraction maps to its ASCII form followed by a space",
        arguments: [
            ("½", "1/2 "),
            ("¼", "1/4 "),
            ("¾", "3/4 "),
            ("⅓", "1/3 "),
            ("⅔", "2/3 ")
        ]
    )
    func mapsUnicodeFractions(input: String, expected: String) {
        #expect(WizardIngredientParser.normaliseUnicodeFractions(input) == expected)
    }

    @Test("Strings without unicode fractions are returned unchanged")
    func leavesPlainStringsUnchanged() {
        #expect(WizardIngredientParser.normaliseUnicodeFractions("2 cups flour") == "2 cups flour")
    }
}
