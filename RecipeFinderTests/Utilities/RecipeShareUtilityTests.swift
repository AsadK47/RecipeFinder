//
//  RecipeShareUtilityTests.swift
//  RecipeFinderTests
//
//  Small, focused tests for RecipeShareUtility

import XCTest
@testable import RecipeFinder

final class RecipeShareUtilityTests: XCTestCase {
    
    var testRecipe: RecipeModel!
    
    override func setUp() {
        super.setUp()
        testRecipe = RecipeModel(
            name: "Test Recipe",
            category: "Main",
            difficulty: "Easy",
            prepTime: "10 min",
            cookingTime: "20 min",
            baseServings: 4,
            currentServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 1.0, unit: "cup", name: "water"),
                Ingredient(baseQuantity: 2.0, unit: "tbsp", name: "salt")
            ],
            prePrepInstructions: ["Prep step 1"],
            instructions: ["Step 1", "Step 2"],
            notes: "Test notes",
            imageName: nil
        )
    }
    
    override func tearDown() {
        testRecipe = nil
        super.tearDown()
    }
    
    func testGenerateTextFormatReturnsNonEmptyString() {
        // Given & When
        let text = RecipeShareUtility.generateTextFormat(recipe: testRecipe)
        
        // Then
        XCTAssertFalse(text.isEmpty)
    }
}
