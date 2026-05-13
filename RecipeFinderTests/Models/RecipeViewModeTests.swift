import XCTest
@testable import RecipeFinder

final class RecipeViewModeTests: XCTestCase {

    // MARK: - columns

    func testListMode_columns_isOne() {
        XCTAssertEqual(RecipeViewMode.list.columns, 1)
    }

    func testGridMode_columns_isTwo() {
        XCTAssertEqual(RecipeViewMode.grid.columns, 2)
    }

    // MARK: - icon

    func testListMode_icon() {
        XCTAssertEqual(RecipeViewMode.list.icon, "list.bullet")
    }

    func testGridMode_icon() {
        XCTAssertEqual(RecipeViewMode.grid.icon, "square.grid.2x2")
    }

    func testAllModes_iconNonEmpty() {
        for mode in RecipeViewMode.allCases {
            XCTAssertFalse(mode.icon.isEmpty, "\(mode) has no icon")
        }
    }

    // MARK: - rawValue

    func testListMode_rawValue() {
        XCTAssertEqual(RecipeViewMode.list.rawValue, "List")
    }

    func testGridMode_rawValue() {
        XCTAssertEqual(RecipeViewMode.grid.rawValue, "Grid")
    }

    // MARK: - allCases

    func testAllCases_countIsTwo() {
        XCTAssertEqual(RecipeViewMode.allCases.count, 2)
    }

    func testAllCases_containsBothModes() {
        XCTAssertTrue(RecipeViewMode.allCases.contains(.list))
        XCTAssertTrue(RecipeViewMode.allCases.contains(.grid))
    }

    func testAllModes_columnsAreDistinct() {
        let cols = RecipeViewMode.allCases.map(\.columns)
        XCTAssertEqual(cols.count, Set(cols).count)
    }
}
