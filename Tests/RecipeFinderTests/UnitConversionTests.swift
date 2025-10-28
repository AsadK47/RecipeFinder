//
//  UnitConversionTests.swift
//  RecipeFinderTests
//
//  Simplified unit tests for UnitConversion utility

import XCTest
@testable import RecipeFinder

final class UnitConversionTests: XCTestCase {
    
    // MARK: - Basic Weight Conversion Tests
    
    func testKilogramsToGrams() throws {
        let result = UnitConversion.convertWeight(value: 1.0, from: "kg", to: "g")
        XCTAssertEqual(result, 1000.0, accuracy: 0.1)
    }
    
    func testPoundsToKilograms() throws {
        let result = UnitConversion.convertWeight(value: 1.0, from: "lb", to: "kg")
        XCTAssertEqual(result, 0.453592, accuracy: 0.001)
    }
    
    // MARK: - Basic Volume Conversion Tests
    
    func testLitersToMilliliters() throws {
        let result = UnitConversion.convertVolume(value: 1.0, from: "L", to: "ml")
        XCTAssertEqual(result, 1000.0, accuracy: 0.1)
    }
    
    func testCupsToMilliliters() throws {
        let result = UnitConversion.convertVolume(value: 1.0, from: "cup", to: "ml")
        XCTAssertEqual(result, 236.588, accuracy: 0.01)
    }
    
    // MARK: - Unit Type Detection Tests
    
    func testUnitTypeWeight() throws {
        XCTAssertEqual(UnitConversion.getUnitType("kg"), .weight)
        XCTAssertEqual(UnitConversion.getUnitType("lb"), .weight)
    }
    
    func testUnitTypeVolume() throws {
        XCTAssertEqual(UnitConversion.getUnitType("L"), .volume)
        XCTAssertEqual(UnitConversion.getUnitType("cup"), .volume)
    }
}
