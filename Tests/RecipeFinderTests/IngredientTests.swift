//
//  IngredientTests.swift
//  RecipeFinderTests
//
//  Small, focused tests for Ingredient model

import XCTest
@testable import RecipeFinder

final class IngredientTests: XCTestCase {
    
    // MARK: - Creation Tests
    
    func testIngredientCreationWithAllProperties() {
        // Given
        let quantity = 1.5
        let unit = "kg"
        let name = "chicken"
        
        // When
        let ingredient = Ingredient(baseQuantity: quantity, unit: unit, name: name)
        
        // Then
        XCTAssertEqual(ingredient.baseQuantity, quantity)
        XCTAssertEqual(ingredient.unit, unit)
        XCTAssertEqual(ingredient.name, name)
    }
    
    func testIngredientWithDecimalQuantity() {
        // Given & When
        let ingredient = Ingredient(baseQuantity: 0.5, unit: "cup", name: "sugar")
        
        // Then
        XCTAssertEqual(ingredient.baseQuantity, 0.5)
    }
    
    func testIngredientWithWholeNumberQuantity() {
        // Given & When
        let ingredient = Ingredient(baseQuantity: 3.0, unit: "whole", name: "eggs")
        
        // Then
        XCTAssertEqual(ingredient.baseQuantity, 3.0)
    }
    
    // MARK: - Formatting Tests
    
    func testIngredientFormattingWithUnit() {
        // Given
        let ingredient = Ingredient(baseQuantity: 2.0, unit: "cups", name: "sugar")
        
        // When
        let formatted = ingredient.formattedWithUnit(for: 1.0, system: .metric)
        
        // Then
        XCTAssertNotNil(formatted)
        XCTAssertTrue(formatted.contains("2"))
    }
    
    func testIngredientFormattingContainsQuantity() {
        // Given
        let ingredient = Ingredient(baseQuantity: 1.0, unit: "tbsp", name: "salt")
        
        // When
        let formatted = ingredient.formattedWithUnit(for: 1.0, system: .metric)
        
        // Then
        XCTAssertNotNil(formatted)
        XCTAssertFalse(formatted.isEmpty)
    }
    
    // MARK: - Scaling Tests
    
    func testIngredientScalesDoubled() {
        // Given
        let ingredient = Ingredient(baseQuantity: 1.0, unit: "cup", name: "milk")
        
        // When
        let doubled = ingredient.formattedWithUnit(for: 2.0, system: .metric)
        
        // Then
        XCTAssertNotNil(doubled)
        XCTAssertTrue(doubled.contains("2"))
    }
    
    func testIngredientScalesHalved() {
        // Given
        let ingredient = Ingredient(baseQuantity: 2.0, unit: "cups", name: "flour")
        
        // When
        let halved = ingredient.formattedWithUnit(for: 0.5, system: .metric)
        
        // Then
        XCTAssertNotNil(halved)
        XCTAssertTrue(halved.contains("1"))
    }
    
    func testIngredientScalesTripled() {
        // Given
        let ingredient = Ingredient(baseQuantity: 1.0, unit: "tsp", name: "vanilla")
        
        // When
        let tripled = ingredient.formattedWithUnit(for: 3.0, system: .metric)
        
        // Then
        XCTAssertNotNil(tripled)
        XCTAssertTrue(tripled.contains("3"))
    }
    
    // MARK: - Unit Tests
    
    func testIngredientWithVolumeUnit() {
        // Given & When
        let ingredient = Ingredient(baseQuantity: 1.0, unit: "cup", name: "water")
        
        // Then
        XCTAssertEqual(ingredient.unit, "cup")
    }
    
    func testIngredientWithWeightUnit() {
        // Given & When
        let ingredient = Ingredient(baseQuantity: 500.0, unit: "g", name: "beef")
        
        // Then
        XCTAssertEqual(ingredient.unit, "g")
    }
    
    func testIngredientWithCountUnit() {
        // Given & When
        let ingredient = Ingredient(baseQuantity: 3.0, unit: "whole", name: "apples")
        
        // Then
        XCTAssertEqual(ingredient.unit, "whole")
    }
}
