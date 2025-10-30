//
//  HapticManagerTests.swift
//  RecipeFinderTests
//
//  Simplified unit tests for HapticManager

import XCTest
@testable import RecipeFinder

final class HapticManagerTests: XCTestCase {
    
    func testSharedInstanceExists() {
        // When & Then
        XCTAssertNotNil(HapticManager.shared)
    }
}
