//
//  RecipeImporterTests.swift
//  RecipeFinderTests
//
//  Simplified unit tests for RecipeImporter

import XCTest
@testable import RecipeFinder

final class RecipeImporterTests: XCTestCase {
    
    // MARK: - Time Parsing Tests
    
    func testISO8601BasicTime() throws {
        XCTAssertEqual(RecipeImporter.parseISO8601Duration("PT15M"), "15 minutes")
        XCTAssertEqual(RecipeImporter.parseISO8601Duration("PT1H"), "1 hour")
    }
    
    func testInvalidTimeFormat() throws {
        let result = RecipeImporter.parseISO8601Duration("invalid")
        XCTAssertEqual(result, "0 minutes")
    }
}
