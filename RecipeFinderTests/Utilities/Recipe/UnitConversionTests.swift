import Testing
import XCTest
@testable import RecipeFinder

private typealias Weight       = UnitConversion.Weight
private typealias Volume       = UnitConversion.Volume
private typealias SolidDensity = UnitConversion.SolidDensity

final class UnitConversionTests: XCTestCase {

    // MARK: - Input normalisation

    func testCaseInsensitiveConversion() {
        XCTAssertEqual(UnitConversion.convertWeight(value: Weight.gramsPerKg, from: "G", to: "KG"), 1.0)
    }

    func testUppercaseInput() {
        XCTAssertEqual(UnitConversion.getUnitType("GRAMS"), UnitType.weight)
    }

    func testWhitespaceTrimming() {
        XCTAssertEqual(UnitConversion.getUnitType(" kg "), UnitType.weight)
    }

    // MARK: - Unit type detection

    func testCup() {
        XCTAssertEqual(UnitConversion.getUnitType("cup"), UnitType.volume)
    }

    func testFluidOunce() {
        XCTAssertEqual(UnitConversion.getUnitType("fl oz"), UnitType.volume)
    }

    func testGrams() {
        XCTAssertEqual(UnitConversion.getUnitType("grams"), UnitType.weight)
    }

    func testKilograms() {
        XCTAssertEqual(UnitConversion.getUnitType("kg"), UnitType.weight)
    }

    func testLiters() {
        XCTAssertEqual(UnitConversion.getUnitType("l"), UnitType.volume)
    }

    func testMilliliters() {
        XCTAssertEqual(UnitConversion.getUnitType("ml"), UnitType.volume)
    }

    func testOunces() {
        XCTAssertEqual(UnitConversion.getUnitType("oz"), UnitType.weight)
    }

    func testPounds() {
        XCTAssertEqual(UnitConversion.getUnitType("lbs"), UnitType.weight)
    }

    func testTablespoon() {
        XCTAssertEqual(UnitConversion.getUnitType("tbsp"), UnitType.volume)
    }

    func testTeaspoon() {
        XCTAssertEqual(UnitConversion.getUnitType("tsp"), UnitType.volume)
    }

    func testUnknownUnitType() {
        XCTAssertEqual(UnitConversion.getUnitType("xyz"), UnitType.none)
    }

    // MARK: - Volume conversions

    func testCupsToMilliliters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 1, from: "cup", to: "ml"), Volume.mlPerCup, accuracy: 0.001)
    }

    func testFluidOuncesToMilliliters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 1, from: "fl oz", to: "ml"), Volume.mlPerFlOz, accuracy: 0.0001)
    }

    func testGallonsToMilliliters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 1, from: "gal", to: "ml"), Volume.mlPerGallon, accuracy: 0.001)
    }

    func testLiterAlias() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 1, from: "liter", to: "milliliter"), Volume.mlPerL)
    }

    func testLitersToMilliliters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 1, from: "l", to: "ml"), Volume.mlPerL)
    }

    func testMillilitersToCentiliters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: Volume.mlPerCL, from: "ml", to: "cl"), 1.0)
    }

    func testMillilitersToCups() {
        XCTAssertEqual(UnitConversion.convertVolume(value: Volume.mlPerCup, from: "ml", to: "cup"), 1.0, accuracy: 0.0001)
    }

    func testMillilitersToDeciliters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: Volume.mlPerDL, from: "ml", to: "dl"), 1.0)
    }

    func testMillilitersToFluidOunces() {
        XCTAssertEqual(UnitConversion.convertVolume(value: Volume.mlPerFlOz, from: "ml", to: "fl oz"), 1.0, accuracy: 0.0001)
    }

    func testMillilitersToLiters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: Volume.mlPerL, from: "ml", to: "l"), 1.0)
    }

    func testMillilitersToTablespoons() {
        XCTAssertEqual(UnitConversion.convertVolume(value: Volume.mlPerTbsp, from: "ml", to: "tbsp"), 1.0, accuracy: 0.0001)
    }

    func testMillilitersToTeaspoons() {
        XCTAssertEqual(UnitConversion.convertVolume(value: Volume.mlPerTsp, from: "ml", to: "tsp"), 1.0, accuracy: 0.0001)
    }

    func testPintsToMilliliters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 1, from: "pt", to: "ml"), Volume.mlPerPint, accuracy: 0.001)
    }

    func testQuartsToMilliliters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 1, from: "qt", to: "ml"), Volume.mlPerQuart, accuracy: 0.001)
    }

    func testVolumeSameUnit() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 5, from: "ml", to: "ml"), 5.0)
    }

    func testTablespoonAlias() {
        XCTAssertEqual(
            UnitConversion.convertVolume(value: 1, from: "tablespoon", to: "teaspoon"),
            Volume.mlPerTbsp / Volume.mlPerTsp,
            accuracy: 0.0001
        )
    }

    func testTablespoonsToMilliliters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 1, from: "tbsp", to: "ml"), Volume.mlPerTbsp, accuracy: 0.0001)
    }

    func testTeaspoonsToMilliliters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 1, from: "tsp", to: "ml"), Volume.mlPerTsp, accuracy: 0.0001)
    }

    func testUnknownVolumeUnitPassthrough() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 3, from: "xyz", to: "ml"), 3.0)
    }

    // MARK: - Weight conversions

    func testGramAlias() {
        XCTAssertEqual(UnitConversion.convertWeight(value: Weight.gramsPerKg, from: "gram", to: "kilogram"), 1.0)
    }

    func testGramsToKilograms() {
        XCTAssertEqual(UnitConversion.convertWeight(value: Weight.gramsPerKg, from: "g", to: "kg"), 1.0)
    }

    func testGramsToOunces() {
        XCTAssertEqual(UnitConversion.convertWeight(value: Weight.gramsPerOunce, from: "g", to: "oz"), 1.0, accuracy: 0.0001)
    }

    func testGramsToPounds() {
        XCTAssertEqual(UnitConversion.convertWeight(value: Weight.gramsPerPound, from: "g", to: "lbs"), 1.0, accuracy: 0.0001)
    }

    func testKilogramsToGrams() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 1, from: "kg", to: "g"), Weight.gramsPerKg)
    }

    func testKilogramsToOunces() {
        XCTAssertEqual(
            UnitConversion.convertWeight(value: 1, from: "kg", to: "oz"),
            Weight.gramsPerKg / Weight.gramsPerOunce,
            accuracy: 0.0001
        )
    }

    func testKilogramsToPounds() {
        XCTAssertEqual(
            UnitConversion.convertWeight(value: 1, from: "kg", to: "lbs"),
            Weight.gramsPerKg / Weight.gramsPerPound,
            accuracy: 0.0001
        )
    }

    func testOuncesToGrams() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 1, from: "oz", to: "g"), Weight.gramsPerOunce, accuracy: 0.0001)
    }

    func testOuncesToKilograms() {
        XCTAssertEqual(
            UnitConversion.convertWeight(value: 1, from: "oz", to: "kg"),
            Weight.gramsPerOunce / Weight.gramsPerKg,
            accuracy: 0.0001
        )
    }

    func testOuncesToPounds() {
        XCTAssertEqual(UnitConversion.convertWeight(value: Weight.ouncesPerPound, from: "oz", to: "lbs"), 1.0, accuracy: 0.0001)
    }

    func testPoundAlias() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 1, from: "pound", to: "ounce"), Weight.ouncesPerPound, accuracy: 0.0001)
    }

    func testPoundsToGrams() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 1, from: "lbs", to: "g"), Weight.gramsPerPound, accuracy: 0.01)
    }

    func testPoundsToKilograms() {
        XCTAssertEqual(
            UnitConversion.convertWeight(value: 1, from: "lbs", to: "kg"),
            Weight.gramsPerPound / Weight.gramsPerKg,
            accuracy: 0.0001
        )
    }

    func testPoundsToOunces() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 1, from: "lbs", to: "oz"), Weight.ouncesPerPound, accuracy: 0.0001)
    }

    func testWeightSameUnit() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 5, from: "g", to: "g"), 5.0)
    }

    func testUnknownWeightUnitPassthrough() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 7, from: "xyz", to: "g"), 7.0)
    }
}

@Suite("Ingredient display")
@MainActor
struct IngredientDisplayTests {
    @Test("Small spoonfuls of spice stay as spoons in both systems (was \"½ g\" of cumin)", arguments: ["tsp", "tbsp", "pinch"])
    func smallSpoonsUnchanged(unit: String) {
        for system in [MeasurementSystem.metric, .imperial] {
            let converted = UnitConversion.convert(value: 0.5, unit: unit, to: system, ingredientName: "ground cumin")
            #expect(converted.quantity == 0.5)
            #expect(converted.unit == unit)
        }
    }

    @Test("Ingredient names display in sentence case as written, not Title Case")
    func sentenceCase() {
        let ingredient = Ingredient(baseQuantity: 25, unit: "g", name: "butter, melted, plus extra for cooking")
        #expect(ingredient.displayName == "Butter, melted, plus extra for cooking")
        #expect(IngredientNameFormatter.formatForDisplay("Kashmiri chilli powder") == "Kashmiri chilli powder")
    }

    @Test("Thirds stay thirds on screen (0.33 cup was shown as ⅜)", arguments: [
        (0.33, "⅓"), (0.67, "⅔"), (1.33, "1⅓"), (0.375, "⅜"), (1.25, "1¼"),
    ])
    func thirdsStayThirds(value: Double, expected: String) {
        #expect(FractionFormatter.format(IngredientRowView.prettyQuantity(value)) == expected)
    }

    @Test("Units read naturally: litres as L, plural cups")
    func displayUnits() {
        #expect(IngredientRowView.displayUnit("l", quantity: 1) == "L")
        #expect(IngredientRowView.displayUnit("cup", quantity: 2) == "cups")
        #expect(IngredientRowView.displayUnit("cup", quantity: 0.5) == "cup")
    }

    @Test("Recipe rows split name and note once, keeping words, order and brackets as written")
    func displayPartsAreFaithful() {
        let kombu = Ingredient(baseQuantity: 2, unit: "", name: "dried kombu (about 5 inches, cut in half), rinsed")
        #expect(kombu.displayParts.name == "Dried kombu (about 5 inches, cut in half)")
        #expect(kombu.displayParts.note == "rinsed")
        let peas = Ingredient(baseQuantity: 100, unit: "g", name: "frozen peas")
        #expect(peas.displayParts.name == "Frozen peas")
        #expect(peas.displayParts.note == nil)
        let noodles = Ingredient(baseQuantity: 400, unit: "g", name: "fresh or dried white noodles, medium thickness")
        #expect(noodles.displayParts.name == "Fresh or dried white noodles")
        #expect(noodles.displayParts.note == "medium thickness")
    }
}
