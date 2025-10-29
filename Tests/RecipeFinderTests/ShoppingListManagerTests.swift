//
//  ShoppingListManagerTests.swift
//  RecipeFinderTests
//
//  Small, focused tests for ShoppingListManager

import XCTest
@testable import RecipeFinder

final class ShoppingListManagerTests: XCTestCase {
    
    var sut: ShoppingListManager!
    
    override func setUp() {
        super.setUp()
        sut = ShoppingListManager()
        sut.clearAll()
    }
    
    override func tearDown() {
        sut.clearAll()
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Add Item Tests
    
    func testAddSingleItem() {
        // Given
        let itemName = "Milk"
        
        // When
        sut.addItem(name: itemName)
        
        // Then
        XCTAssertEqual(sut.items.count, 1)
        XCTAssertEqual(sut.items.first?.name, itemName)
    }
    
    func testAddMultipleItems() {
        // Given & When
        sut.addItem(name: "Milk")
        sut.addItem(name: "Eggs")
        sut.addItem(name: "Bread")
        
        // Then
        XCTAssertEqual(sut.items.count, 3)
    }
    
    func testAddItemDefaultsToUnchecked() {
        // Given & When
        sut.addItem(name: "Butter")
        
        // Then
        XCTAssertFalse(sut.items.first?.isChecked ?? true)
    }
    
    // MARK: - Check/Uncheck Tests
    
    func testToggleItemToChecked() {
        // Given
        sut.addItem(name: "Eggs")
        guard let item = sut.items.first else {
            XCTFail("Item not added")
            return
        }
        
        // When
        sut.toggleChecked(item)
        
        // Then
        let updated = sut.items.first
        XCTAssertTrue(updated?.isChecked ?? false)
    }
    
    func testToggleItemToUnchecked() {
        // Given
        sut.addItem(name: "Eggs")
        guard let item = sut.items.first else {
            XCTFail("Item not added")
            return
        }
        sut.toggleChecked(item) // Check it first
        
        // When
        sut.toggleChecked(item) // Uncheck it
        
        // Then
        let updated = sut.items.first
        XCTAssertFalse(updated?.isChecked ?? true)
    }
    
    // MARK: - Delete Item Tests
    
    func testDeleteSingleItem() {
        // Given
        sut.addItem(name: "Bread")
        guard let item = sut.items.first else {
            XCTFail("Item not added")
            return
        }
        
        // When
        sut.deleteItem(item)
        
        // Then
        XCTAssertEqual(sut.items.count, 0)
    }
    
    func testDeleteSpecificItem() {
        // Given
        sut.addItem(name: "Item 1")
        sut.addItem(name: "Item 2")
        sut.addItem(name: "Item 3")
        
        guard let itemToDelete = sut.items.first(where: { $0.name == "Item 2" }) else {
            XCTFail("Item not found")
            return
        }
        
        // When
        sut.deleteItem(itemToDelete)
        
        // Then
        XCTAssertEqual(sut.items.count, 2)
        XCTAssertNil(sut.items.first(where: { $0.name == "Item 2" }))
    }
    
    // MARK: - Clear All Tests
    
    func testClearAllItems() {
        // Given
        sut.addItem(name: "Item 1")
        sut.addItem(name: "Item 2")
        sut.addItem(name: "Item 3")
        XCTAssertEqual(sut.items.count, 3)
        
        // When
        sut.clearAll()
        
        // Then
        XCTAssertEqual(sut.items.count, 0)
    }
    
    func testClearEmptyList() {
        // Given
        XCTAssertEqual(sut.items.count, 0)
        
        // When
        sut.clearAll()
        
        // Then
        XCTAssertEqual(sut.items.count, 0)
    }
    
    // MARK: - Checked Count Tests
    
    func testCheckedCountWithNoItems() {
        // Given & When & Then
        XCTAssertEqual(sut.checkedCount, 0)
    }
    
    func testCheckedCountWithUncheckedItems() {
        // Given
        sut.addItem(name: "Item 1")
        sut.addItem(name: "Item 2")
        
        // When & Then
        XCTAssertEqual(sut.checkedCount, 0)
    }
    
    func testCheckedCountWithOneCheckedItem() {
        // Given
        sut.addItem(name: "Item 1")
        sut.addItem(name: "Item 2")
        
        if let item = sut.items.first {
            sut.toggleChecked(item)
        }
        
        // When & Then
        XCTAssertEqual(sut.checkedCount, 1)
    }
    
    func testCheckedCountWithAllCheckedItems() {
        // Given
        sut.addItem(name: "Item 1")
        sut.addItem(name: "Item 2")
        
        sut.items.forEach { sut.toggleChecked($0) }
        
        // When & Then
        XCTAssertEqual(sut.checkedCount, 2)
    }
}
