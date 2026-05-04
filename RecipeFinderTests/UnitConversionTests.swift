import XCTest
@testable import RecipeFinder

class UnitNormalizationTests: XCTestCase {

    func testCaseInsensitiveConversion() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 1000, from: "G", to: "KG"), 1.0)
    }

    func testUppercaseInput() {
        XCTAssertEqual(UnitConversion.getUnitType("GRAMS"), UnitType.weight)
    }

    func testWhitespaceTrimming() {
        XCTAssertEqual(UnitConversion.getUnitType(" kg "), UnitType.weight)
    }
}

class UnitTypeTests: XCTestCase {

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

    func testUnknown() {
        XCTAssertEqual(UnitConversion.getUnitType("xyz"), UnitType.none)
    }
}

class VolumeConversionTests: XCTestCase {

    func testCupsToMilliliters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 1, from: "cup", to: "ml"), 236.5882365, accuracy: 0.001)
    }

    func testFluidOuncesToMilliliters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 1, from: "fl oz", to: "ml"), 29.5735295625, accuracy: 0.0001)
    }

    func testGallonsToMilliliters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 1, from: "gal", to: "ml"), 3785.411784, accuracy: 0.001)
    }

    func testLiterAlias() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 1, from: "liter", to: "milliliter"), 1000.0)
    }

    func testLitersToMilliliters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 1, from: "l", to: "ml"), 1000.0)
    }

    func testMillilitersToCentiliters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 10, from: "ml", to: "cl"), 1.0)
    }

    func testMillilitersToCups() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 236.5882365, from: "ml", to: "cup"), 1.0, accuracy: 0.0001)
    }

    func testMillilitersToDeciliters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 100, from: "ml", to: "dl"), 1.0)
    }

    func testMillilitersToFluidOunces() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 29.5735295625, from: "ml", to: "fl oz"), 1.0, accuracy: 0.0001)
    }

    func testMillilitersToLiters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 1000, from: "ml", to: "l"), 1.0)
    }

    func testMillilitersToTablespoons() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 14.78676478125, from: "ml", to: "tbsp"), 1.0, accuracy: 0.0001)
    }

    func testMillilitersToTeaspoons() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 4.92892159375, from: "ml", to: "tsp"), 1.0, accuracy: 0.0001)
    }

    func testPintsToMilliliters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 1, from: "pt", to: "ml"), 473.176473, accuracy: 0.001)
    }

    func testQuartsToMilliliters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 1, from: "qt", to: "ml"), 946.352946, accuracy: 0.001)
    }

    func testSameUnit() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 5, from: "ml", to: "ml"), 5.0)
    }

    func testTablespoonAlias() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 1, from: "tablespoon", to: "teaspoon"), 3.0, accuracy: 0.0001)
    }

    func testTablespoonsToMilliliters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 1, from: "tbsp", to: "ml"), 14.78676478125, accuracy: 0.0001)
    }

    func testTeaspoonsToMilliliters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 1, from: "tsp", to: "ml"), 4.92892159375, accuracy: 0.0001)
    }

    func testUnknownUnitPassthrough() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 3, from: "xyz", to: "ml"), 3.0)
    }
}

class WeightConversionTests: XCTestCase {

    func testGramAlias() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 1000, from: "gram", to: "kilogram"), 1.0)
    }

    func testGramsToKilograms() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 1000, from: "g", to: "kg"), 1.0)
    }

    func testGramsToOunces() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 28.349523125, from: "g", to: "oz"), 1.0, accuracy: 0.0001)
    }

    func testGramsToPounds() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 453.59237, from: "g", to: "lbs"), 1.0, accuracy: 0.0001)
    }

    func testKilogramsToGrams() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 1, from: "kg", to: "g"), 1000.0)
    }

    func testKilogramsToOunces() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 1, from: "kg", to: "oz"), 35.27396, accuracy: 0.0001)
    }

    func testKilogramsToPounds() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 1, from: "kg", to: "lbs"), 2.20462, accuracy: 0.0001)
    }

    func testOuncesToGrams() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 1, from: "oz", to: "g"), 28.349523125, accuracy: 0.0001)
    }

    func testOuncesToKilograms() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 1, from: "oz", to: "kg"), 0.0283495, accuracy: 0.0001)
    }

    func testOuncesToPounds() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 16, from: "oz", to: "lbs"), 1.0, accuracy: 0.0001)
    }

    func testPoundAlias() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 1, from: "pound", to: "ounce"), 16.0, accuracy: 0.0001)
    }

    func testPoundsToGrams() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 1, from: "lbs", to: "g"), 453.59237, accuracy: 0.01)
    }

    func testPoundsToKilograms() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 1, from: "lbs", to: "kg"), 0.45359237, accuracy: 0.0001)
    }

    func testPoundsToOunces() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 1, from: "lbs", to: "oz"), 16.0, accuracy: 0.0001)
    }

    func testSameUnit() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 5, from: "g", to: "g"), 5.0)
    }

    func testUnknownUnitPassthrough() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 7, from: "xyz", to: "g"), 7.0)
    }
}
