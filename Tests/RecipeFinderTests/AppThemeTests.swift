//
//  AppThemeTests.swift
//  RecipeFinderTests
//
//  Unit tests for AppTheme

import XCTest
@testable import RecipeFinder

final class AppThemeTests: XCTestCase {
    
    // MARK: - Golden Ratio Tests
    
    func testGoldenRatioConstant() throws {
        XCTAssertEqual(AppTheme.goldenRatio, 1.618, accuracy: 0.001)
        XCTAssertEqual(AppTheme.goldenRatioInverse, 0.618, accuracy: 0.001)
    }
    
    func testGoldenRatioRelationship() throws {
        // 1/φ should equal φ - 1
        let inverseCalculated = 1.0 / AppTheme.goldenRatio
        XCTAssertEqual(inverseCalculated, AppTheme.goldenRatioInverse, accuracy: 0.001)
    }
    
    func testCardProportionsUseGoldenRatio() throws {
        // Vertical spacing should be horizontal padding * golden ratio inverse
        let expectedSpacing = AppTheme.cardHorizontalPadding * AppTheme.goldenRatioInverse
        XCTAssertEqual(AppTheme.cardVerticalSpacing, expectedSpacing, accuracy: 1.0)
    }
    
    // MARK: - Theme Tests
    
    func testThemeTypeCount() throws {
        XCTAssertEqual(AppTheme.ThemeType.allCases.count, 8)
    }
    
    func testThemeRawValues() throws {
        XCTAssertEqual(AppTheme.ThemeType.teal.rawValue, "Teal")
        XCTAssertEqual(AppTheme.ThemeType.purple.rawValue, "Purple")
        XCTAssertEqual(AppTheme.ThemeType.red.rawValue, "Red")
        XCTAssertEqual(AppTheme.ThemeType.orange.rawValue, "Orange")
        XCTAssertEqual(AppTheme.ThemeType.yellow.rawValue, "Yellow")
        XCTAssertEqual(AppTheme.ThemeType.green.rawValue, "Green")
        XCTAssertEqual(AppTheme.ThemeType.pink.rawValue, "Pink")
        XCTAssertEqual(AppTheme.ThemeType.gold.rawValue, "Gold")
    }
    
    func testAccentColorsExist() throws {
        for theme in AppTheme.ThemeType.allCases {
            let color = AppTheme.accentColor(for: theme)
            XCTAssertNotNil(color)
        }
    }
    
    func testBackgroundGradientsExist() throws {
        for theme in AppTheme.ThemeType.allCases {
            let gradient = AppTheme.backgroundGradient(for: theme, colorScheme: .light)
            XCTAssertNotNil(gradient)
        }
    }
    
    func testDefaultThemeIsTeal() throws {
        // Default accent should be teal
        let defaultAccent = AppTheme.accentColor
        let tealAccent = AppTheme.accentColor(for: .teal)
        XCTAssertEqual(defaultAccent, tealAccent)
    }
}
