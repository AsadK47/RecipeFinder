import XCTest
import SwiftUI
@testable import RecipeFinder

@MainActor
final class SettingsComponentsTests: XCTestCase {

    // MARK: - SettingsRow defaults

    func testRowDefaultsToChevronAccessory() {
        let sut = SettingsRow(icon: "gear", iconColor: .gray, title: "Title")
        XCTAssertEqual(sut.accessory, .chevron)
    }

    func testRowDefaultsToNoSubtitleAndNoValue() {
        let sut = SettingsRow(icon: "gear", iconColor: .gray, title: "Title")
        XCTAssertNil(sut.subtitle)
        XCTAssertNil(sut.value)
    }

    // MARK: - SettingsSection.Item

    func testNavigationItemHasDestinationAndNoAction() {
        let item = SettingsSection.Item(
            row: SettingsRow(icon: "gear", iconColor: .gray, title: "Title"),
            destination: Text("Destination")
        )
        XCTAssertNotNil(item.destination)
        XCTAssertNil(item.action)
    }

    func testActionItemHasActionAndNoDestination() {
        let item = SettingsSection.Item(
            row: SettingsRow(icon: "gear", iconColor: .gray, title: "Title"),
            action: {}
        )
        XCTAssertNil(item.destination)
        XCTAssertNotNil(item.action)
    }

    func testItemsHaveUniqueIdentities() {
        let row = SettingsRow(icon: "gear", iconColor: .gray, title: "Title")
        let first = SettingsSection.Item(row: row, action: {})
        let second = SettingsSection.Item(row: row, action: {})
        XCTAssertNotEqual(first.id, second.id)
    }
}
