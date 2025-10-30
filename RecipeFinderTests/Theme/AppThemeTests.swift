//
//  AppThemeTests.swift
//  RecipeFinderTests
//
//  Unit tests for AppTheme

import XCTest
@testable import RecipeFinder

final class AppThemeTests: XCTestCase {
    
    func testGoldenRatioConstant() {
        // When & Then
        XCTAssertEqual(AppTheme.goldenRatio, 1.618, accuracy: 0.001)
        XCTAssertEqual(AppTheme.goldenRatioInverse, 0.618, accuracy: 0.001)
    }
}
