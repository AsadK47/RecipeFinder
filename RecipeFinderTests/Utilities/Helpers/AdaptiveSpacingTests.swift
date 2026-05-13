import XCTest
@testable import RecipeFinder

final class AdaptiveSpacingTests: XCTestCase {

    // MARK: - Helpers

    /// Large screen (iPad-ish): formula values exceed minimums for most properties
    private let large = AdaptiveSpacing(width: 1024, height: 1366)
    /// Standard iPhone 14 Pro
    private let standard = AdaptiveSpacing(width: 393, height: 852)
    /// Small screen (iPhone SE): most spacing values will hit their minimums
    private let small = AdaptiveSpacing(width: 375, height: 667)
    /// Extreme small: all values should clamp to their declared minimums
    private let tiny = AdaptiveSpacing(width: 100, height: 100)

    // MARK: - Minimum clamping on tiny screen

    func testXxs_tiny_returnsMinimum() {
        XCTAssertEqual(tiny.xxs, 4, accuracy: 0.01)
    }

    func testXs_tiny_returnsMinimum() {
        XCTAssertEqual(tiny.xs, 6, accuracy: 0.01)
    }

    func testSm_tiny_returnsMinimum() {
        XCTAssertEqual(tiny.sm, 8, accuracy: 0.01)
    }

    func testMd_tiny_returnsMinimum() {
        XCTAssertEqual(tiny.md, 12, accuracy: 0.01)
    }

    func testLg_tiny_returnsMinimum() {
        XCTAssertEqual(tiny.lg, 16, accuracy: 0.01)
    }

    func testXl_tiny_returnsMinimum() {
        XCTAssertEqual(tiny.xl, 20, accuracy: 0.01)
    }

    func testXxl_tiny_returnsMinimum() {
        XCTAssertEqual(tiny.xxl, 24, accuracy: 0.01)
    }

    func testButtonHeight_tiny_returnsMinimum() {
        XCTAssertEqual(tiny.buttonHeight, 44, accuracy: 0.01)
    }

    func testButtonHeightLarge_tiny_returnsMinimum() {
        XCTAssertEqual(tiny.buttonHeightLarge, 56, accuracy: 0.01)
    }

    func testScreenEdge_tiny_returnsMinimum() {
        XCTAssertEqual(tiny.screenEdge, 16, accuracy: 0.01)
    }

    func testCardPadding_tiny_returnsMinimum() {
        XCTAssertEqual(tiny.cardPadding, 12, accuracy: 0.01)
    }

    func testIconSmall_tiny_returnsMinimum() {
        XCTAssertEqual(tiny.iconSmall, 20, accuracy: 0.01)
    }

    func testIconMedium_tiny_returnsMinimum() {
        XCTAssertEqual(tiny.iconMedium, 24, accuracy: 0.01)
    }

    func testIconLarge_tiny_returnsMinimum() {
        XCTAssertEqual(tiny.iconLarge, 32, accuracy: 0.01)
    }

    func testTouchTarget_tiny_returnsMinimum() {
        XCTAssertEqual(tiny.touchTarget, 44, accuracy: 0.01)
    }

    func testTouchTargetSmall_tiny_returnsMinimum() {
        XCTAssertEqual(tiny.touchTargetSmall, 32, accuracy: 0.01)
    }

    // MARK: - Ordering: values increase with semantic size

    func testSpacingOrder_standardScreen() {
        XCTAssertLessThan(standard.xxs, standard.xs)
        XCTAssertLessThan(standard.xs, standard.sm)
        XCTAssertLessThan(standard.sm, standard.md)
        XCTAssertLessThan(standard.md, standard.lg)
        XCTAssertLessThan(standard.lg, standard.xl)
        XCTAssertLessThan(standard.xl, standard.xxl)
    }

    func testIconOrder_standardScreen() {
        XCTAssertLessThanOrEqual(standard.iconSmall, standard.iconMedium)
        XCTAssertLessThanOrEqual(standard.iconMedium, standard.iconLarge)
    }

    func testImageOrder_standardScreen() {
        XCTAssertLessThan(standard.imageSmall, standard.imageMedium)
        XCTAssertLessThan(standard.imageMedium, standard.imageLarge)
        XCTAssertLessThan(standard.imageLarge, standard.imageXLarge)
        XCTAssertLessThan(standard.imageXLarge, standard.imageHero)
    }

    func testButtonHeightLarge_greaterThan_buttonHeight() {
        XCTAssertGreaterThan(standard.buttonHeightLarge, standard.buttonHeight)
    }

    // MARK: - Larger screen produces larger (or equal) spacing

    func testXxl_largeScreen_greaterOrEqual_smallScreen() {
        XCTAssertGreaterThanOrEqual(large.xxl, small.xxl)
    }

    func testButtonHeight_largeScreen_greaterOrEqual_smallScreen() {
        XCTAssertGreaterThanOrEqual(large.buttonHeight, small.buttonHeight)
    }

    func testImageHero_largeScreen_greaterOrEqual_smallScreen() {
        XCTAssertGreaterThanOrEqual(large.imageHero, small.imageHero)
    }

    // MARK: - Formula values on large screen (exceed minimums)

    func testXxs_largeScreen_usesFormula() {
        // height * 0.005 = 1366 * 0.005 = 6.83, which exceeds minimum of 4
        XCTAssertGreaterThan(large.xxs, 4)
    }

    func testButtonHeight_largeScreen_usesFormula() {
        // height * 0.055 = 1366 * 0.055 = 75.13, which exceeds minimum of 44
        XCTAssertGreaterThan(large.buttonHeight, 44)
    }

    func testScreenEdge_largeScreen_usesFormula() {
        // width * 0.04 = 1024 * 0.04 = 40.96, which exceeds minimum of 16
        XCTAssertGreaterThan(large.screenEdge, 16)
    }
}
