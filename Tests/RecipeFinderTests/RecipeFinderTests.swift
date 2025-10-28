//
//  RecipeFinderTests.swift
//  RecipeFinderTests
//
//  Created by asad.e.khan on 10/12/2024.
//

import XCTest
@testable import RecipeFinder

// MARK: - Basic Model Tests
final class RecipeModelTests: XCTestCase {
    
    // Test 1: Recipe can be created with basic properties
    func testRecipeCreation() throws {
        let recipe = RecipeModel(
            name: "Test Recipe",
            category: "Main",
            difficulty: "Easy",
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
        
        XCTAssertEqual(recipe.name, "Test Recipe")
        XCTAssertEqual(recipe.category, "Main")
        XCTAssertEqual(recipe.difficulty, "Easy")
        XCTAssertEqual(recipe.baseServings, 4)
    }
    
    // Test 2: Recipe can have ingredients
    func testRecipeWithIngredients() throws {
        let ingredient = Ingredient(baseQuantity: 2.0, unit: "cups", name: "flour")
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
        
        XCTAssertEqual(recipe.ingredients.count, 1)
        XCTAssertEqual(recipe.ingredients.first?.name, "flour")
    }
    
    // Test 3: Recipe can be favorited
    func testRecipeFavorite() throws {
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
            instructions: ["Make it"],
            notes: "",
            imageName: nil
        )
        
        XCTAssertFalse(recipe.isFavorite)
        recipe.isFavorite = true
        XCTAssertTrue(recipe.isFavorite)
    }
}

// MARK: - Ingredient Tests
final class IngredientTests: XCTestCase {
    
    // Test 4: Ingredient can be created
    func testIngredientCreation() throws {
        let ingredient = Ingredient(baseQuantity: 1.5, unit: "kg", name: "chicken")
        
        XCTAssertEqual(ingredient.baseQuantity, 1.5)
        XCTAssertEqual(ingredient.unit, "kg")
        XCTAssertEqual(ingredient.name, "chicken")
    }
    
    // Test 5: Ingredient can format with unit
    func testIngredientFormatting() throws {
        let ingredient = Ingredient(baseQuantity: 2.0, unit: "cups", name: "sugar")
        let formatted = ingredient.formattedWithUnit(for: 1.0, system: .metric)
        
        XCTAssertNotNil(formatted)
        XCTAssertTrue(formatted.contains("2"))
    }
    
    // Test 6: Ingredient scales with serving multiplier
    func testIngredientScaling() throws {
        let ingredient = Ingredient(baseQuantity: 1.0, unit: "cup", name: "milk")
        let doubled = ingredient.formattedWithUnit(for: 2.0, system: .metric)
        
        XCTAssertNotNil(doubled)
        // Should scale to 2 cups
        XCTAssertTrue(doubled.contains("2"))
    }
}

// MARK: - Shopping List Tests
final class ShoppingListTests: XCTestCase {
    
    var manager: ShoppingListManager!
    
    override func setUp() {
        super.setUp()
        manager = ShoppingListManager()
        manager.clearAll() // Start fresh
    }
    
    // Test 7: Can add item to shopping list
    func testAddItem() throws {
        manager.addItem(name: "Milk")
        
        XCTAssertEqual(manager.items.count, 1)
        XCTAssertEqual(manager.items.first?.name, "Milk")
    }
    
    // Test 8: Can check off item
    func testCheckItem() throws {
        manager.addItem(name: "Eggs")
        
        guard let item = manager.items.first else {
            XCTFail("Item not added")
            return
        }
        
        XCTAssertFalse(item.isChecked)
        manager.toggleChecked(item)
        
        let updated = manager.items.first
        XCTAssertTrue(updated?.isChecked ?? false)
    }
    
    // Test 9: Can delete item
    func testDeleteItem() throws {
        manager.addItem(name: "Bread")
        XCTAssertEqual(manager.items.count, 1)
        
        if let item = manager.items.first {
            manager.deleteItem(item)
        }
        
        XCTAssertEqual(manager.items.count, 0)
    }
    
    // Test 10: Can clear all items
    func testClearAll() throws {
        manager.addItem(name: "Item 1")
        manager.addItem(name: "Item 2")
        manager.addItem(name: "Item 3")
        
        XCTAssertEqual(manager.items.count, 3)
        
        manager.clearAll()
        XCTAssertEqual(manager.items.count, 0)
    }
    
    // Test 11: Checked count is accurate
    func testCheckedCount() throws {
        manager.addItem(name: "Item 1")
        manager.addItem(name: "Item 2")
        
        XCTAssertEqual(manager.checkedCount, 0)
        
        if let item = manager.items.first {
            manager.toggleChecked(item)
        }
        
        XCTAssertEqual(manager.checkedCount, 1)
    }
}

// MARK: - Kitchen Inventory Tests
final class KitchenInventoryTests: XCTestCase {
    
    var manager: KitchenInventoryManager!
    
    override func setUp() {
        super.setUp()
        manager = KitchenInventoryManager()
        manager.clearAll()
    }
    
    // Test 12: Can add ingredient to kitchen
    func testAddIngredient() throws {
        manager.addItem("Tomatoes")
        
        XCTAssertTrue(manager.hasItem("Tomatoes"))
        XCTAssertEqual(manager.items.count, 1)
    }
    
    // Test 13: Can remove ingredient from kitchen
    func testRemoveIngredient() throws {
        manager.addItem("Onions")
        XCTAssertTrue(manager.hasItem("Onions"))
        
        manager.removeItem("Onions")
        XCTAssertFalse(manager.hasItem("Onions"))
    }
    
    // Test 14: Can toggle ingredient
    func testToggleIngredient() throws {
        manager.toggleItem("Garlic")
        XCTAssertTrue(manager.hasItem("Garlic"))
        
        manager.toggleItem("Garlic")
        XCTAssertFalse(manager.hasItem("Garlic"))
    }
    
    // Test 15: Can clear all kitchen items
    func testClearKitchen() throws {
        manager.addItem("Salt")
        manager.addItem("Pepper")
        manager.addItem("Oil")
        
        XCTAssertEqual(manager.items.count, 3)
        
        manager.clearAll()
        XCTAssertEqual(manager.items.count, 0)
    }
}

// MARK: - Recipe Share Utility Tests
final class RecipeShareTests: XCTestCase {
    
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
    
    // Test 16: Can generate text format
    func testGenerateTextFormat() throws {
        let text = RecipeShareUtility.generateTextFormat(recipe: testRecipe)
        
        XCTAssertFalse(text.isEmpty)
        XCTAssertTrue(text.contains("Test Recipe"))
        XCTAssertTrue(text.contains("INGREDIENTS"))
        XCTAssertTrue(text.contains("INSTRUCTIONS"))
    }
    
    // Test 17: Text format includes all sections
    func testTextFormatCompleteness() throws {
        let text = RecipeShareUtility.generateTextFormat(recipe: testRecipe)
        
        XCTAssertTrue(text.contains("RECIPE INFORMATION"))
        XCTAssertTrue(text.contains("Category: Main"))
        XCTAssertTrue(text.contains("Difficulty: Easy"))
        XCTAssertTrue(text.contains("water"))
        XCTAssertTrue(text.contains("salt"))
    }
    
    // Test 18: Can generate PDF
    func testGeneratePDF() throws {
        let pdfData = RecipeShareUtility.generatePDF(recipe: testRecipe)
        
        XCTAssertNotNil(pdfData)
        XCTAssertTrue((pdfData?.count ?? 0) > 0)
    }
}

// MARK: - Category Classifier Tests
final class CategoryClassifierTests: XCTestCase {
    
    // Test 19: Can suggest category for common ingredients
    func testSuggestCategory() throws {
        XCTAssertEqual(CategoryClassifier.suggestCategory(for: "tomato"), "Produce")
        XCTAssertEqual(CategoryClassifier.suggestCategory(for: "chicken"), "Meat & Seafood")
        XCTAssertEqual(CategoryClassifier.suggestCategory(for: "milk"), "Dairy & Eggs")
    }
    
    // Test 20: Can get category icon
    func testCategoryIcon() throws {
        let icon = CategoryClassifier.categoryIcon(for: "Produce")
        XCTAssertFalse(icon.isEmpty)
    }
}

// MARK: - Time Extractor Tests
final class TimeExtractorTests: XCTestCase {
    
    // Test 21: Can extract minutes from time string
    func testExtractMinutes() throws {
        XCTAssertEqual(TimeExtractor.extractMinutes(from: "30 minutes"), 30)
        XCTAssertEqual(TimeExtractor.extractMinutes(from: "1 hour"), 60)
        XCTAssertEqual(TimeExtractor.extractMinutes(from: "1 hour 30 minutes"), 90)
    }
    
    // Test 22: Returns 0 for invalid time strings
    func testInvalidTimeString() throws {
        XCTAssertEqual(TimeExtractor.extractMinutes(from: ""), 0)
        XCTAssertEqual(TimeExtractor.extractMinutes(from: "invalid"), 0)
    }
}

// MARK: - Performance Tests (Simple)
final class PerformanceTests: XCTestCase {
    
    // Test 23: Text generation is fast
    func testTextGenerationPerformance() throws {
        let recipe = RecipeModel(
            name: "Performance Test",
            category: "Main",
            difficulty: "Easy",
            prepTime: "10 min",
            cookingTime: "20 min",
            baseServings: 4,
            currentServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 1.0, unit: "cup", name: "ingredient")
            ],
            prePrepInstructions: [],
            instructions: ["Step 1"],
            notes: "",
            imageName: nil
        )
        
        measure {
            _ = RecipeShareUtility.generateTextFormat(recipe: recipe)
        }
    }
}
