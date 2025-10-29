//
//  RecipeModelTests.swift
//  RecipeFinderTests
//
//  Small, focused tests for RecipeModel

import XCTest
@testable import RecipeFinder

final class RecipeModelTests: XCTestCase {
    
    // MARK: - Creation Tests
    
    func testRecipeCreationWithBasicProperties() {
        // Given
        let name = "Test Recipe"
        let category = "Main"
        let difficulty = "Easy"
        
        // When
        let recipe = RecipeModel(
            name: name,
            category: category,
            difficulty: difficulty,
            prepTime: "10 minutes",
            cookingTime: "20 minutes",
            baseServings: 4,
            currentServings: 4,
            ingredients: [],
            prePrepInstructions: [],
            instructions: ["Step 1"],
            notes: "Test notes",
            imageName: nil
        )
        
        // Then
        XCTAssertEqual(recipe.name, name)
        XCTAssertEqual(recipe.category, category)
        XCTAssertEqual(recipe.difficulty, difficulty)
    }
    
    func testRecipeCreationWithServings() {
        // Given & When
        let recipe = RecipeModel(
            name: "Test",
            category: "Main",
            difficulty: "Easy",
            prepTime: "10 min",
            cookingTime: "20 min",
            baseServings: 4,
            currentServings: 4,
            ingredients: [],
            prePrepInstructions: [],
            instructions: [],
            notes: "",
            imageName: nil
        )
        
        // Then
        XCTAssertEqual(recipe.baseServings, 4)
        XCTAssertEqual(recipe.currentServings, 4)
    }
    
    // MARK: - Ingredient Tests
    
    func testRecipeWithIngredients() {
        // Given
        let ingredient = Ingredient(baseQuantity: 2.0, unit: "cups", name: "flour")
        
        // When
        let recipe = RecipeModel(
            name: "Bread",
            category: "Bakery",
            difficulty: "Medium",
            prepTime: "15 min",
            cookingTime: "30 min",
            baseServings: 1,
            currentServings: 1,
            ingredients: [ingredient],
            prePrepInstructions: [],
            instructions: ["Mix", "Bake"],
            notes: "",
            imageName: nil
        )
        
        // Then
        XCTAssertEqual(recipe.ingredients.count, 1)
        XCTAssertEqual(recipe.ingredients.first?.name, "flour")
        XCTAssertEqual(recipe.ingredients.first?.baseQuantity, 2.0)
    }
    
    func testRecipeWithMultipleIngredients() {
        // Given
        let ingredients = [
            Ingredient(baseQuantity: 1.0, unit: "cup", name: "flour"),
            Ingredient(baseQuantity: 2.0, unit: "tbsp", name: "sugar"),
            Ingredient(baseQuantity: 0.5, unit: "tsp", name: "salt")
        ]
        
        // When
        let recipe = RecipeModel(
            name: "Cake",
            category: "Dessert",
            difficulty: "Medium",
            prepTime: "20 min",
            cookingTime: "30 min",
            baseServings: 8,
            currentServings: 8,
            ingredients: ingredients,
            prePrepInstructions: [],
            instructions: ["Mix", "Bake"],
            notes: "",
            imageName: nil
        )
        
        // Then
        XCTAssertEqual(recipe.ingredients.count, 3)
    }
    
    // MARK: - Favorite Tests
    
    func testRecipeDefaultsToNotFavorite() {
        // Given & When
        let recipe = RecipeModel(
            name: "Test",
            category: "Main",
            difficulty: "Easy",
            prepTime: "5 min",
            cookingTime: "10 min",
            baseServings: 2,
            currentServings: 2,
            ingredients: [],
            prePrepInstructions: [],
            instructions: [],
            notes: "",
            imageName: nil
        )
        
        // Then
        XCTAssertFalse(recipe.isFavorite)
    }
    
    func testRecipeCanBeFavorited() {
        // Given
        var recipe = RecipeModel(
            name: "Favorite Recipe",
            category: "Dessert",
            difficulty: "Easy",
            prepTime: "5 min",
            cookingTime: "10 min",
            baseServings: 2,
            currentServings: 2,
            ingredients: [],
            prePrepInstructions: [],
            instructions: [],
            notes: "",
            imageName: nil
        )
        
        // When
        recipe.isFavorite = true
        
        // Then
        XCTAssertTrue(recipe.isFavorite)
    }
    
    func testRecipeCanBeUnfavorited() {
        // Given
        var recipe = RecipeModel(
            name: "Test",
            category: "Main",
            difficulty: "Easy",
            prepTime: "5 min",
            cookingTime: "10 min",
            baseServings: 2,
            currentServings: 2,
            ingredients: [],
            prePrepInstructions: [],
            instructions: [],
            notes: "",
            imageName: nil
        )
        recipe.isFavorite = true
        
        // When
        recipe.isFavorite = false
        
        // Then
        XCTAssertFalse(recipe.isFavorite)
    }
    
    // MARK: - Instructions Tests
    
    func testRecipeWithInstructions() {
        // Given
        let instructions = ["Step 1", "Step 2", "Step 3"]
        
        // When
        let recipe = RecipeModel(
            name: "Test",
            category: "Main",
            difficulty: "Easy",
            prepTime: "10 min",
            cookingTime: "20 min",
            baseServings: 4,
            currentServings: 4,
            ingredients: [],
            prePrepInstructions: [],
            instructions: instructions,
            notes: "",
            imageName: nil
        )
        
        // Then
        XCTAssertEqual(recipe.instructions.count, 3)
        XCTAssertEqual(recipe.instructions, instructions)
    }
    
    func testRecipeWithPrePrepInstructions() {
        // Given
        let prePrepInstructions = ["Prep step 1", "Prep step 2"]
        
        // When
        let recipe = RecipeModel(
            name: "Test",
            category: "Main",
            difficulty: "Expert",
            prepTime: "30 min",
            cookingTime: "1 hour",
            baseServings: 6,
            currentServings: 6,
            ingredients: [],
            prePrepInstructions: prePrepInstructions,
            instructions: ["Cook"],
            notes: "",
            imageName: nil
        )
        
        // Then
        XCTAssertEqual(recipe.prePrepInstructions.count, 2)
        XCTAssertEqual(recipe.prePrepInstructions, prePrepInstructions)
    }
}
