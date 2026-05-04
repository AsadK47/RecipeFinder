import XCTest
@testable import RecipeFinder

class UnitConversionTests: XCTestCase {

    // MARK: - convertWeight

    func testConvertWeightGramsToKilograms() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 1000, from: "g", to: "kg"), 1.0)
    }

    func testConvertWeightKilogramsToGrams() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 1, from: "kg", to: "g"), 1000.0)
    }

    func testConvertWeightGramsToPounds() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 453.59237, from: "g", to: "lbs"), 1.0, accuracy: 0.0001)
    }

    func testConvertWeightPoundsToGrams() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 1, from: "lbs", to: "g"), 453.59237, accuracy: 0.01)
    }

    func testConvertWeightGramsToOunces() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 28.349523125, from: "g", to: "oz"), 1.0, accuracy: 0.0001)
    }

    func testConvertWeightOuncesToGrams() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 1, from: "oz", to: "g"), 28.349523125, accuracy: 0.0001)
    }

    func testConvertWeightPoundsToKilograms() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 1, from: "lbs", to: "kg"), 0.45359237, accuracy: 0.0001)
    }

    func testConvertWeightKilogramsToPounds() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 1, from: "kg", to: "lbs"), 2.20462, accuracy: 0.0001)
    }

    func testConvertWeightPoundsToOunces() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 1, from: "lbs", to: "oz"), 16.0, accuracy: 0.0001)
    }

    func testConvertWeightOuncesToPounds() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 16, from: "oz", to: "lbs"), 1.0, accuracy: 0.0001)
    }

    func testConvertWeightOuncesToKilograms() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 1, from: "oz", to: "kg"), 0.0283495, accuracy: 0.0001)
    }

    func testConvertWeightKilogramsToOunces() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 1, from: "kg", to: "oz"), 35.27396, accuracy: 0.0001)
    }

    func testConvertWeightSameUnit() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 5, from: "g", to: "g"), 5.0)
    }

    func testConvertWeightUnknownUnitPassthrough() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 7, from: "xyz", to: "g"), 7.0)
    }

    func testConvertWeightGramAlias() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 1000, from: "gram", to: "kilogram"), 1.0)
    }

    func testConvertWeightPoundAlias() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 1, from: "pound", to: "ounce"), 16.0, accuracy: 0.0001)
    }

    // MARK: - convertVolume

    func testConvertVolumeMillilitersToLiters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 1000, from: "ml", to: "l"), 1.0)
    }

    func testConvertVolumeLitersToMilliliters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 1, from: "l", to: "ml"), 1000.0)
    }

    func testConvertVolumeMillilitersToCentiliters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 10, from: "ml", to: "cl"), 1.0)
    }

    func testConvertVolumeMillilitersToDeciliters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 100, from: "ml", to: "dl"), 1.0)
    }

    func testConvertVolumeCupsToMilliliters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 1, from: "cup", to: "ml"), 236.5882365, accuracy: 0.001)
    }

    func testConvertVolumeMillilitersToCups() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 236.5882365, from: "ml", to: "cup"), 1.0, accuracy: 0.0001)
    }

    func testConvertVolumeTablespoonsToMilliliters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 1, from: "tbsp", to: "ml"), 14.78676478125, accuracy: 0.0001)
    }

    func testConvertVolumeMillilitersToTablespoons() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 14.78676478125, from: "ml", to: "tbsp"), 1.0, accuracy: 0.0001)
    }

    func testConvertVolumeTeaspoonsToMilliliters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 1, from: "tsp", to: "ml"), 4.92892159375, accuracy: 0.0001)
    }

    func testConvertVolumeMillilitersToTeaspoons() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 4.92892159375, from: "ml", to: "tsp"), 1.0, accuracy: 0.0001)
    }

    func testConvertVolumeFluidOuncesToMilliliters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 1, from: "fl oz", to: "ml"), 29.5735295625, accuracy: 0.0001)
    }

    func testConvertVolumeMillilitersToFluidOunces() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 29.5735295625, from: "ml", to: "fl oz"), 1.0, accuracy: 0.0001)
    }

    func testConvertVolumePintsToMilliliters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 1, from: "pt", to: "ml"), 473.176473, accuracy: 0.001)
    }

    func testConvertVolumeQuartsToMilliliters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 1, from: "qt", to: "ml"), 946.352946, accuracy: 0.001)
    }

    func testConvertVolumeGallonsToMilliliters() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 1, from: "gal", to: "ml"), 3785.411784, accuracy: 0.001)
    }

    func testConvertVolumeSameUnit() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 5, from: "ml", to: "ml"), 5.0)
    }

    func testConvertVolumeUnknownUnitPassthrough() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 3, from: "xyz", to: "ml"), 3.0)
    }

    func testConvertVolumeLiterAlias() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 1, from: "liter", to: "milliliter"), 1000.0)
    }

    func testConvertVolumeTablespoonAlias() {
        XCTAssertEqual(UnitConversion.convertVolume(value: 1, from: "tablespoon", to: "teaspoon"), 3.0, accuracy: 0.0001)
    }

    // MARK: - getUnitType

    func testGetUnitTypeForGrams() {
        XCTAssertEqual(UnitConversion.getUnitType("grams"), UnitType.weight)
    }

    func testGetUnitTypeForKilograms() {
        XCTAssertEqual(UnitConversion.getUnitType("kg"), UnitType.weight)
    }

    func testGetUnitTypeForPounds() {
        XCTAssertEqual(UnitConversion.getUnitType("lbs"), UnitType.weight)
    }

    func testGetUnitTypeForOunces() {
        XCTAssertEqual(UnitConversion.getUnitType("oz"), UnitType.weight)
    }

    func testGetUnitTypeForMilliliters() {
        XCTAssertEqual(UnitConversion.getUnitType("ml"), UnitType.volume)
    }

    func testGetUnitTypeForLiters() {
        XCTAssertEqual(UnitConversion.getUnitType("l"), UnitType.volume)
    }

    func testGetUnitTypeForCup() {
        XCTAssertEqual(UnitConversion.getUnitType("cup"), UnitType.volume)
    }

    func testGetUnitTypeForTeaspoon() {
        XCTAssertEqual(UnitConversion.getUnitType("tsp"), UnitType.volume)
    }

    func testGetUnitTypeForTablespoon() {
        XCTAssertEqual(UnitConversion.getUnitType("tbsp"), UnitType.volume)
    }

    func testGetUnitTypeForFluidOunce() {
        XCTAssertEqual(UnitConversion.getUnitType("fl oz"), UnitType.volume)
    }

    func testGetUnitTypeForUnknown() {
        XCTAssertEqual(UnitConversion.getUnitType("xyz"), UnitType.none)
    }

    // MARK: - Normalization

    func testGetUnitTypeUppercaseNormalization() {
        XCTAssertEqual(UnitConversion.getUnitType("GRAMS"), UnitType.weight)
    }

    func testGetUnitTypeWhitespaceTrimming() {
        XCTAssertEqual(UnitConversion.getUnitType(" kg "), UnitType.weight)
    }

    func testConvertWeightCaseInsensitive() {
        XCTAssertEqual(UnitConversion.convertWeight(value: 1000, from: "G", to: "KG"), 1.0)
    }
}
