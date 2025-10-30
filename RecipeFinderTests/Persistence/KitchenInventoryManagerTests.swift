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
    
    func testAddSingleIngredient() {
        // Given
        let ingredient = "Tomatoes"
        
        // When
        sut.addItem(name: ingredient)
        
        // Then
        XCTAssertTrue(sut.hasItem(ingredient))
        XCTAssertEqual(sut.items.count, 1)
    }
}
