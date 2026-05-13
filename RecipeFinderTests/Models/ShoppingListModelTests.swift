import XCTest
@testable import RecipeFinder

final class ShoppingListModelTests: XCTestCase {

    // MARK: - Default init values

    func testInit_defaultQuantity_isOne() {
        let item = ShoppingListModel(name: "Milk")
        XCTAssertEqual(item.quantity, 1)
    }

    func testInit_defaultUnit_isEmpty() {
        let item = ShoppingListModel(name: "Milk")
        XCTAssertEqual(item.unit, "")
    }

    func testInit_defaultCategory_isOther() {
        let item = ShoppingListModel(name: "Milk")
        XCTAssertEqual(item.category, "Other")
    }

    func testInit_defaultIsChecked_isFalse() {
        let item = ShoppingListModel(name: "Milk")
        XCTAssertFalse(item.isChecked)
    }

    func testInit_defaultIsCompleted_isFalse() {
        let item = ShoppingListModel(name: "Milk")
        XCTAssertFalse(item.isCompleted)
    }

    func testInit_defaultPreferredStore_isNil() {
        let item = ShoppingListModel(name: "Milk")
        XCTAssertNil(item.preferredStore)
    }

    // MARK: - isChecked / isCompleted sync on init

    func testInit_isCheckedTrue_setsIsCompletedTrue() {
        let item = ShoppingListModel(name: "Eggs", isChecked: true)
        XCTAssertTrue(item.isChecked)
        XCTAssertTrue(item.isCompleted)
    }

    func testInit_isCheckedFalse_keepsIsCompletedFalse() {
        let item = ShoppingListModel(name: "Eggs", isChecked: false)
        XCTAssertFalse(item.isChecked)
        XCTAssertFalse(item.isCompleted)
    }

    // MARK: - Custom init values

    func testInit_customCategory_storedCorrectly() {
        let item = ShoppingListModel(name: "Salmon", category: "Seafood")
        XCTAssertEqual(item.category, "Seafood")
    }

    func testInit_customQuantityAndUnit() {
        let item = ShoppingListModel(name: "Flour", quantity: 3, unit: "cups")
        XCTAssertEqual(item.quantity, 3)
        XCTAssertEqual(item.unit, "cups")
    }

    func testInit_customPreferredStore() {
        let item = ShoppingListModel(name: "Butter", preferredStore: "Whole Foods")
        XCTAssertEqual(item.preferredStore, "Whole Foods")
    }

    // MARK: - Identifiable / Hashable

    func testTwoItemsWithSameId_areEqual() {
        let id = UUID()
        let a = ShoppingListModel(id: id, name: "Bread")
        let b = ShoppingListModel(id: id, name: "Bread")
        XCTAssertEqual(a, b)
    }

    func testTwoItemsWithDifferentIds_areNotEqual() {
        let a = ShoppingListModel(name: "Bread")
        let b = ShoppingListModel(name: "Bread")
        XCTAssertNotEqual(a, b)
    }
}
