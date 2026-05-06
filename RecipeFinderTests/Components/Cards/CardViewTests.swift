import XCTest
import SwiftUI
@testable import RecipeFinder

@MainActor
final class CardViewTests: XCTestCase {

    // MARK: - frostedShadowOpacity

    func testFrostedShadowOpacityIsDarkInDarkMode() {
        let sut = CardView { EmptyView() }
        XCTAssertEqual(sut.frostedShadowOpacity(for: .dark), CardViewLayout.shadowOpacityFrostedDark)
    }

    func testFrostedShadowOpacityIsLightInLightMode() {
        let sut = CardView { EmptyView() }
        XCTAssertEqual(sut.frostedShadowOpacity(for: .light), CardViewLayout.shadowOpacityFrostedLight)
    }

    func testFrostedShadowOpacityDarkIsGreaterThanLight() {
        let sut = CardView { EmptyView() }
        XCTAssertGreaterThan(
            sut.frostedShadowOpacity(for: .dark),
            sut.frostedShadowOpacity(for: .light)
        )
    }
}
