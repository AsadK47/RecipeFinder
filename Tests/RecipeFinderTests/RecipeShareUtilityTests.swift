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
    
    // MARK: - Text Format Generation Tests
    
    func testGenerateTextFormatReturnsNonEmptyString() {
        // Given & When
        let text = RecipeShareUtility.generateTextFormat(recipe: testRecipe)
        
        // Then
        XCTAssertFalse(text.isEmpty)
    }
    
    func testTextFormatContainsRecipeName() {
        // Given & When
        let text = RecipeShareUtility.generateTextFormat(recipe: testRecipe)
        
        // Then
        XCTAssertTrue(text.contains("Test Recipe"))
    }
    
    func testTextFormatContainsIngredientsSection() {
        // Given & When
        let text = RecipeShareUtility.generateTextFormat(recipe: testRecipe)
        
        // Then
        XCTAssertTrue(text.contains("INGREDIENTS"))
    }
    
    func testTextFormatContainsInstructionsSection() {
        // Given & When
        let text = RecipeShareUtility.generateTextFormat(recipe: testRecipe)
        
        // Then
        XCTAssertTrue(text.contains("INSTRUCTIONS"))
    }
    
    func testTextFormatContainsCategory() {
        // Given & When
        let text = RecipeShareUtility.generateTextFormat(recipe: testRecipe)
        
        // Then
        XCTAssertTrue(text.contains("Category: Main"))
    }
    
    func testTextFormatContainsDifficulty() {
        // Given & When
        let text = RecipeShareUtility.generateTextFormat(recipe: testRecipe)
        
        // Then
        XCTAssertTrue(text.contains("Difficulty: Easy"))
    }
    
    func testTextFormatContainsIngredients() {
        // Given & When
        let text = RecipeShareUtility.generateTextFormat(recipe: testRecipe)
        
        // Then
        XCTAssertTrue(text.contains("water"))
        XCTAssertTrue(text.contains("salt"))
    }
    
    func testTextFormatContainsInstructions() {
        // Given & When
        let text = RecipeShareUtility.generateTextFormat(recipe: testRecipe)
        
        // Then
        XCTAssertTrue(text.contains("Step 1"))
        XCTAssertTrue(text.contains("Step 2"))
    }
    
    // MARK: - PDF Generation Tests
    
    func testGeneratePDFReturnsNonNilData() {
        // Given & When
        let pdfData = RecipeShareUtility.generatePDF(recipe: testRecipe)
        
        // Then
        XCTAssertNotNil(pdfData)
    }
    
    func testGeneratePDFReturnsNonEmptyData() {
        // Given & When
        let pdfData = RecipeShareUtility.generatePDF(recipe: testRecipe)
        
        // Then
        XCTAssertTrue((pdfData?.count ?? 0) > 0)
    }
    
    func testGeneratePDFForMinimalRecipe() {
        // Given
        let minimalRecipe = RecipeModel(
            name: "Minimal",
            category: "Main",
            difficulty: "Easy",
            prepTime: "5 min",
            cookingTime: "10 min",
            baseServings: 1,
            currentServings: 1,
            ingredients: [],
            prePrepInstructions: [],
            instructions: ["Cook"],
            notes: "",
            imageName: nil
        )
        
        // When
        let pdfData = RecipeShareUtility.generatePDF(recipe: minimalRecipe)
        
        // Then
        XCTAssertNotNil(pdfData)
    }
    
    // MARK: - Edge Case Tests
    
    func testTextFormatWithEmptyNotes() {
        // Given
        let recipeWithoutNotes = RecipeModel(
            name: "No Notes Recipe",
            category: "Main",
            difficulty: "Easy",
            prepTime: "10 min",
            cookingTime: "20 min",
            baseServings: 2,
            currentServings: 2,
            ingredients: [],
            prePrepInstructions: [],
            instructions: ["Cook"],
            notes: "",
            imageName: nil
        )
        
        // When
        let text = RecipeShareUtility.generateTextFormat(recipe: recipeWithoutNotes)
        
        // Then
        XCTAssertFalse(text.isEmpty)
    }
    
    func testTextFormatWithNoPrePrepInstructions() {
        // Given
        let recipeWithoutPrePrep = RecipeModel(
            name: "Simple Recipe",
            category: "Main",
            difficulty: "Easy",
            prepTime: "5 min",
            cookingTime: "10 min",
            baseServings: 2,
            currentServings: 2,
            ingredients: [],
            prePrepInstructions: [],
            instructions: ["Cook"],
            notes: "",
            imageName: nil
        )
        
        // When
        let text = RecipeShareUtility.generateTextFormat(recipe: recipeWithoutPrePrep)
        
        // Then
        XCTAssertFalse(text.isEmpty)
    }
}
