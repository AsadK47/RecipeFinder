//
//  TimeExtractorTests.swift
//  RecipeFinderTests
//
//  Small, focused tests for TimeExtractor utility

import XCTest
@testable import RecipeFinder

final class TimeExtractorTests: XCTestCase {
    
    func testExtractSimpleMinutes() {
        // Given
        let timeString = "30 minutes"
        
        // When
        let result = TimeExtractor.extractMinutes(from: timeString)
        
        // Then
        XCTAssertEqual(result, 30)
    }
}
