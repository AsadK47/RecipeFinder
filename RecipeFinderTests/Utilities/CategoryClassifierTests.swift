//
//  CategoryClassifierTests.swift
//  RecipeFinderTests
//
//  Simplified unit tests for CategoryClassifier

import XCTest
@testable import RecipeFinder

final class CategoryClassifierTests: XCTestCase {
    
    func testProduceCategoryDetection() {
        // Given
        let ingredient = "tomato"
        
        // When
        let category = CategoryClassifier.categorize(ingredient)
        
        // Then
        XCTAssertEqual(category, "Produce")
    }
}
