//
//  CategoryClassifierTests.swift
//  RecipeFinderTests
//
//  Simplified unit tests for CategoryClassifier

import XCTest
@testable import RecipeFinder

final class CategoryClassifierTests: XCTestCase {
    
    // MARK: - Basic Category Tests
    
    func testProduceCategoryDetection() throws {
        XCTAssertEqual(CategoryClassifier.suggestCategory(for: "tomato"), "Produce")
        XCTAssertEqual(CategoryClassifier.suggestCategory(for: "apple"), "Produce")
    }
    
    func testMeatCategoryDetection() throws {
        XCTAssertEqual(CategoryClassifier.suggestCategory(for: "chicken"), "Meat & Seafood")
        XCTAssertEqual(CategoryClassifier.suggestCategory(for: "salmon"), "Meat & Seafood")
    }
    
    func testDairyCategoryDetection() throws {
        XCTAssertEqual(CategoryClassifier.suggestCategory(for: "milk"), "Dairy & Eggs")
        XCTAssertEqual(CategoryClassifier.suggestCategory(for: "cheese"), "Dairy & Eggs")
    }
    
    func testPantryCategoryDetection() throws {
        XCTAssertEqual(CategoryClassifier.suggestCategory(for: "flour"), "Pantry")
        XCTAssertEqual(CategoryClassifier.suggestCategory(for: "rice"), "Pantry")
    }
    
    func testCaseInsensitive() throws {
        XCTAssertEqual(CategoryClassifier.suggestCategory(for: "MILK"), "Dairy & Eggs")
    }
    
    func testCategoryIconExists() throws {
        let icon = CategoryClassifier.categoryIcon(for: "Produce")
        XCTAssertFalse(icon.isEmpty)
    }
}
