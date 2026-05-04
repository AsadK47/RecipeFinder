import XCTest
@testable import RecipeFinder

class UnitConversionTests: XCTestCase {

    func testConvertWeightGramsToKilograms() {
        let result = UnitConversion.convertWeight(value: 1000, from: "g", to: "kg")
        XCTAssertEqual(result, 1.0)
    }

    func testConvertWeightPoundsToGrams() {
        let result = UnitConversion.convertWeight(value: 1, from: "lbs", to: "g")
        XCTAssertEqual(result, 453.59237, accuracy: 0.01)
    }

    func testConvertVolumeMillilitersToLiters() {
        let result = UnitConversion.convertVolume(value: 1000, from: "ml", to: "l")
        XCTAssertEqual(result, 1.0)
    }

    func testGetUnitTypeForWeight() {
        let result = UnitConversion.getUnitType("grams")
        XCTAssertEqual(result, UnitType.weight)
    }

    func testGetUnitTypeForVolume() {
        let result = UnitConversion.getUnitType("cup")
        XCTAssertEqual(result, UnitType.volume)
    }
}
