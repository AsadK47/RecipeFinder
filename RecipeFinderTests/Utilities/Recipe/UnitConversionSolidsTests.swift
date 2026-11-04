import Testing
@testable import RecipeFinder

/// Regression coverage for the substring-conflation bug in the solid-density path:
/// "salted butter" must not borrow salt's density just because it contains "salt".
@Suite("UnitConversion solids")
struct UnitConversionSolidsTests {

    @Test("Salt by the cup still uses its measured density (1 cup ≈ 288 g); spoons stay spoons")
    func saltUsesDensity() {
        let cup = UnitConversion.convert(value: 1, unit: "cup", to: .metric, ingredientName: "salt")
        #expect(cup.unit == "g")
        #expect(cup.quantity == 288)
        // Spoons are deliberately never converted (see UnitConversion.convert) — consistent and readable.
        let spoon = UnitConversion.convert(value: 1, unit: "tbsp", to: .metric, ingredientName: "salt")
        #expect(spoon.unit == "tbsp")
    }

    @Test("Solids without a known density keep their cups instead of a generic gram guess")
    func unknownSolidKeepsCups() {
        let herbs = UnitConversion.convert(value: 0.25, unit: "cup", to: .metric, ingredientName: "chopped flat leaf parsley")
        #expect(herbs.unit == "cup")
    }

    @Test("Salted butter is not treated as salt")
    func saltedButterIsNotSalt() {
        let butter = UnitConversion.convert(value: 1, unit: "tbsp", to: .metric, ingredientName: "salted butter")
        // The bug produced (18, "g") — salt's density. Any other result is correct here.
        #expect(!(butter.unit == "g" && butter.quantity == 18))
    }

    @Test("Cups of butter weigh in grams; cups of liquid round to tidy millilitres")
    func butterAndTidyMillilitres() {
        let butter = UnitConversion.convert(value: 0.5, unit: "cup", to: .metric, ingredientName: "unsalted butter")
        #expect(butter.unit == "g")
        #expect(abs(butter.quantity - 113.5) < 0.01)
        let water = UnitConversion.convert(value: 0.25, unit: "cup", to: .metric, ingredientName: "water")
        #expect(water.unit == "ml")
        #expect(water.quantity == 60)
    }

    @Test("Cups of solids we can't weigh honestly stay cups (was 175 ml chana dal, 22 g fresh coriander)", arguments: [
        "chana dal, rinsed and drained", "green or napa cabbage, chopped", "fresh coriander, chopped",
        "sui mi ya cai (pickled vegetables)",
    ])
    func unweighableSolidsKeepCups(name: String) {
        let converted = UnitConversion.convert(value: 0.75, unit: "cup", to: .metric, ingredientName: name)
        #expect(converted.unit == "cup")
        #expect(converted.quantity == 0.75)
    }

    @Test("Converted amounts are rounded to what people measure")
    func tidyRounding() {
        let water = UnitConversion.convert(value: 4, unit: "cup", to: .metric, ingredientName: "water")
        #expect(water == (950, "ml"))
        let butter = UnitConversion.convert(value: 25, unit: "g", to: .imperial, ingredientName: "butter")
        #expect(butter == (1, "oz"))
        let chicken = UnitConversion.convert(value: 454, unit: "g", to: .imperial, ingredientName: "chicken thighs")
        #expect(chicken == (1, "lb"))
    }

    @Test("450 g reads as 1 lb in Imperial, not 16 oz")
    func almostAPoundIsAPound() {
        #expect(UnitConversion.convert(value: 450, unit: "g", to: .imperial, ingredientName: "chicken thighs") == (1, "lb"))
    }
}
