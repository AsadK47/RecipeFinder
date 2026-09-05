import Testing
@testable import RecipeFinder

/// Regression coverage for the substring-conflation bug in the solid-density path:
/// "salted butter" must not borrow salt's density just because it contains "salt".
@Suite("UnitConversion solids")
struct UnitConversionSolidsTests {

    @Test("Salt itself still uses its measured density (1 tbsp ≈ 18 g)")
    func saltUsesDensity() {
        let salt = UnitConversion.convert(value: 1, unit: "tbsp", to: .metric, ingredientName: "salt")
        #expect(salt.unit == "g")
        #expect(salt.quantity == 18)
    }

    @Test("Salted butter is not treated as salt")
    func saltedButterIsNotSalt() {
        let butter = UnitConversion.convert(value: 1, unit: "tbsp", to: .metric, ingredientName: "salted butter")
        // The bug produced (18, "g") — salt's density. Any other result is correct here.
        #expect(!(butter.unit == "g" && butter.quantity == 18))
    }
}
