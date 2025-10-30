//
//  UnitConversionTests.swift
//  RecipeFinderTests
//
//  Simplified unit tests for UnitConversion utility

import XCTest
@testable import RecipeFinder

final class UnitConversionTests: XCTestCase {
    
    func testKilogramsToGrams() {
        // Given
        let value = 1.0
        
        // When
        let result = UnitConversion.convertWeight(value: value, from: "kg", to: "g")
        
        // Then
        XCTAssertEqual(result, 1000.0, accuracy: 0.1)
    }
}
