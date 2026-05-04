import XCTest
import SwiftUI
@testable import RecipeFinder

@MainActor
final class CardViewTests: XCTestCase {

    // MARK: - frostedShadowOpacity

    func testFrostedShadowOpacityIsDarkInDarkMode() {
        let sut = CardView { EmptyView() }
        XCTAssertEqual(sut.frostedShadowOpacity(for: .dark), 0.3)
    }

    func testFrostedShadowOpacityIsLightInLightMode() {
        let sut = CardView { EmptyView() }
        XCTAssertEqual(sut.frostedShadowOpacity(for: .light), 0.15)
    }

    func testFrostedShadowOpacityDarkIsGreaterThanLight() {
        let sut = CardView { EmptyView() }
        XCTAssertGreaterThan(
            sut.frostedShadowOpacity(for: .dark),
            sut.frostedShadowOpacity(for: .light)
        )
    }
}
