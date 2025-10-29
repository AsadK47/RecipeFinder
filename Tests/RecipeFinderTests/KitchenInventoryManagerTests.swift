//
//  KitchenInventoryManagerTests.swift
//  RecipeFinderTests
//
//  Small, focused tests for KitchenInventoryManager

import XCTest
@testable import RecipeFinder

final class KitchenInventoryManagerTests: XCTestCase {
    
    var sut: KitchenInventoryManager!
    
    override func setUp() {
        super.setUp()
        sut = KitchenInventoryManager()
        sut.clearAll()
    }
    
    override func tearDown() {
        sut.clearAll()
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Add Item Tests
    
    func testAddSingleIngredient() {
        // Given
        let ingredient = "Tomatoes"
        
        // When
        sut.addItem(ingredient)
        
        // Then
        XCTAssertTrue(sut.hasItem(ingredient))
        XCTAssertEqual(sut.items.count, 1)
    }
    
    func testAddMultipleIngredients() {
        // Given & When
        sut.addItem("Tomatoes")
        sut.addItem("Onions")
        sut.addItem("Garlic")
        
        // Then
        XCTAssertEqual(sut.items.count, 3)
    }
    
    // MARK: - Remove Item Tests
    
    func testRemoveSingleIngredient() {
        // Given
        let ingredient = "Onions"
        sut.addItem(ingredient)
        XCTAssertTrue(sut.hasItem(ingredient))
        
        // When
        sut.removeItem(ingredient)
        
        // Then
        XCTAssertFalse(sut.hasItem(ingredient))
    }
    
    func testRemoveNonExistentIngredient() {
        // Given
        sut.addItem("Tomatoes")
        
        // When
        sut.removeItem("Onions")
        
        // Then
        XCTAssertEqual(sut.items.count, 1)
        XCTAssertTrue(sut.hasItem("Tomatoes"))
    }
    
    // MARK: - Toggle Item Tests
    
    func testToggleAddsNewIngredient() {
        // Given
        let ingredient = "Garlic"
        XCTAssertFalse(sut.hasItem(ingredient))
        
        // When
        sut.toggleItem(ingredient)
        
        // Then
        XCTAssertTrue(sut.hasItem(ingredient))
    }
    
    func testToggleRemovesExistingIngredient() {
        // Given
        let ingredient = "Garlic"
        sut.toggleItem(ingredient)
        XCTAssertTrue(sut.hasItem(ingredient))
        
        // When
        sut.toggleItem(ingredient)
        
        // Then
        XCTAssertFalse(sut.hasItem(ingredient))
    }
    
    func testToggleTwiceReturnsToOriginalState() {
        // Given
        let ingredient = "Pepper"
        let initialState = sut.hasItem(ingredient)
        
        // When
        sut.toggleItem(ingredient)
        sut.toggleItem(ingredient)
        
        // Then
        XCTAssertEqual(sut.hasItem(ingredient), initialState)
    }
    
    // MARK: - Has Item Tests
    
    func testHasItemReturnsFalseForNewManager() {
        // Given & When & Then
        XCTAssertFalse(sut.hasItem("Anything"))
    }
    
    func testHasItemReturnsTrueForAddedIngredient() {
        // Given
        let ingredient = "Salt"
        sut.addItem(ingredient)
        
        // When & Then
        XCTAssertTrue(sut.hasItem(ingredient))
    }
    
    func testHasItemReturnsFalseForRemovedIngredient() {
        // Given
        let ingredient = "Pepper"
        sut.addItem(ingredient)
        sut.removeItem(ingredient)
        
        // When & Then
        XCTAssertFalse(sut.hasItem(ingredient))
    }
    
    // MARK: - Clear All Tests
    
    func testClearAllRemovesAllIngredients() {
        // Given
        sut.addItem("Salt")
        sut.addItem("Pepper")
        sut.addItem("Oil")
        XCTAssertEqual(sut.items.count, 3)
        
        // When
        sut.clearAll()
        
        // Then
        XCTAssertEqual(sut.items.count, 0)
    }
    
    func testClearAllOnEmptyInventory() {
        // Given
        XCTAssertEqual(sut.items.count, 0)
        
        // When
        sut.clearAll()
        
        // Then
        XCTAssertEqual(sut.items.count, 0)
    }
    
    // MARK: - Items Array Tests
    
    func testItemsArrayReflectsAddedIngredients() {
        // Given & When
        sut.addItem("Ingredient 1")
        sut.addItem("Ingredient 2")
        
        // Then
        XCTAssertEqual(sut.items.count, 2)
        XCTAssertTrue(sut.items.contains("Ingredient 1"))
        XCTAssertTrue(sut.items.contains("Ingredient 2"))
    }
}
