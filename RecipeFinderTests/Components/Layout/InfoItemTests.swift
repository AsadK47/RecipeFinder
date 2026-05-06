import XCTest
import SwiftUI
@testable import RecipeFinder

final class InfoItemTests: XCTestCase {

    // MARK: - iconColor

    func testClockIconIsOrange() {
        let sut = InfoItem(icon: "clock", label: "", value: "")
        XCTAssertEqual(sut.iconColor, .orange)
    }

    func testFlameIconIsRed() {
        let sut = InfoItem(icon: "flame", label: "", value: "")
        XCTAssertEqual(sut.iconColor, .red)
    }

    func testChartBarIconIsBlue() {
        let sut = InfoItem(icon: "chart.bar", label: "", value: "")
        XCTAssertEqual(sut.iconColor, .blue)
    }

    func testForkKnifeIconIsGreen() {
        let sut = InfoItem(icon: "fork.knife", label: "", value: "")
        XCTAssertEqual(sut.iconColor, .green)
    }

    func testUnknownIconIsWhite() {
        let sut = InfoItem(icon: "questionmark", label: "", value: "")
        XCTAssertEqual(sut.iconColor, .white)
    }

    func testEmptyIconIsWhite() {
        let sut = InfoItem(icon: "", label: "", value: "")
        XCTAssertEqual(sut.iconColor, .white)
    }
}
