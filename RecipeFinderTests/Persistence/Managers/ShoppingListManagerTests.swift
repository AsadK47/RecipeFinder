import XCTest
@testable import RecipeFinder

@MainActor
final class ShoppingListManagerTests: XCTestCase {

    private var storage: UserScopedStorage!
    private var sut: ShoppingListManager!

    override func setUp() async throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        storage = UserScopedStorage(userDefaults: defaults)
        sut = ShoppingListManager(storage: storage)
    }

    override func tearDown() async throws {
        sut = nil
        storage = nil
    }

    // MARK: - Initial state

    func testInitialState_isEmpty() {
        XCTAssertTrue(sut.items.isEmpty)
        XCTAssertEqual(sut.uncheckedCount(), 0)
        XCTAssertEqual(sut.checkedCount(), 0)
    }

    // MARK: - addItem

    func testAddItem_addsNewItem() {
        sut.addItem(name: "Milk")
        XCTAssertEqual(sut.items.count, 1)
        XCTAssertEqual(sut.items[0].name, "Milk")
    }

    func testAddItem_trimsWhitespace() {
        sut.addItem(name: "  Eggs  ")
        XCTAssertEqual(sut.items[0].name, "Eggs")
    }

    func testAddItem_emptyName_ignored() {
        sut.addItem(name: "   ")
        XCTAssertTrue(sut.items.isEmpty)
    }

    func testAddItem_quantityZero_rejected() {
        sut.addItem(name: "Butter", quantity: 0)
        XCTAssertTrue(sut.items.isEmpty)
    }

    func testAddItem_quantityNegative_rejected() {
        sut.addItem(name: "Butter", quantity: -1)
        XCTAssertTrue(sut.items.isEmpty)
    }

    func testAddItem_quantityExceeds999_rejected() {
        sut.addItem(name: "Butter", quantity: 1000)
        XCTAssertTrue(sut.items.isEmpty)
    }

    func testAddItem_quantity999_accepted() {
        sut.addItem(name: "Butter", quantity: 999)
        XCTAssertEqual(sut.items[0].quantity, 999)
    }

    func testAddItem_usesProvidedCategory() {
        sut.addItem(name: "Apple", quantity: 1, category: "Snacks")
        XCTAssertEqual(sut.items[0].category, "Snacks")
    }

    func testAddItem_detectsCategoryWhenNil() {
        sut.addItem(name: "Milk", quantity: 1, category: nil)
        // CategoryClassifier assigns a category; just verify it's non-empty
        XCTAssertFalse(sut.items[0].category.isEmpty)
    }

    // MARK: - Deduplication

    func testAddItem_existingName_mergesQuantity() {
        sut.addItem(name: "Flour", quantity: 2)
        sut.addItem(name: "Flour", quantity: 3)
        XCTAssertEqual(sut.items.count, 1)
        XCTAssertEqual(sut.items[0].quantity, 5)
    }

    func testAddItem_existingNameCaseInsensitive_merges() {
        sut.addItem(name: "sugar", quantity: 1)
        sut.addItem(name: "Sugar", quantity: 1)
        XCTAssertEqual(sut.items.count, 1)
        XCTAssertEqual(sut.items[0].quantity, 2)
    }

    func testAddItem_mergedQuantityCappedAt999() {
        sut.addItem(name: "Salt", quantity: 998)
        sut.addItem(name: "Salt", quantity: 5)
        XCTAssertEqual(sut.items[0].quantity, 999)
    }

    // MARK: - toggleItem

    func testToggleItem_checksItem() {
        sut.addItem(name: "Bread")
        sut.toggleItem(at: 0)
        XCTAssertTrue(sut.items[0].isChecked)
    }

    func testToggleItem_unchecksItem() {
        sut.addItem(name: "Bread")
        sut.toggleItem(at: 0)
        sut.toggleItem(at: 0)
        XCTAssertFalse(sut.items[0].isChecked)
    }

    func testToggleItem_outOfBounds_doesNothing() {
        sut.addItem(name: "A")
        sut.toggleItem(at: 5)
        XCTAssertEqual(sut.items.count, 1)
    }

    // MARK: - updateQuantity

    func testUpdateQuantity_updatesValue() {
        sut.addItem(name: "Pasta")
        sut.updateQuantity(at: 0, quantity: 4)
        XCTAssertEqual(sut.items[0].quantity, 4)
    }

    func testUpdateQuantity_zeroQuantity_rejected() {
        sut.addItem(name: "Pasta", quantity: 2)
        sut.updateQuantity(at: 0, quantity: 0)
        XCTAssertEqual(sut.items[0].quantity, 2)
    }

    func testUpdateQuantity_over999_rejected() {
        sut.addItem(name: "Pasta", quantity: 2)
        sut.updateQuantity(at: 0, quantity: 1000)
        XCTAssertEqual(sut.items[0].quantity, 2)
    }

    // MARK: - deleteItem

    func testDeleteItem_removesItem() {
        sut.addItem(name: "Oil")
        sut.deleteItem(at: 0)
        XCTAssertTrue(sut.items.isEmpty)
    }

    func testDeleteItem_outOfBounds_doesNothing() {
        sut.addItem(name: "Oil")
        sut.deleteItem(at: 10)
        XCTAssertEqual(sut.items.count, 1)
    }

    // MARK: - clearCheckedItems

    func testClearCheckedItems_removesOnlyChecked() {
        sut.addItem(name: "Checked")
        sut.addItem(name: "Unchecked")
        sut.toggleItem(at: 0)
        sut.clearCheckedItems()
        XCTAssertEqual(sut.items.count, 1)
        XCTAssertFalse(sut.items[0].isChecked)
    }

    // MARK: - clearAllItems

    func testClearAllItems_removesEverything() {
        sut.addItem(name: "A")
        sut.addItem(name: "B")
        sut.clearAllItems()
        XCTAssertTrue(sut.items.isEmpty)
    }

    // MARK: - groupedItems

    func testGroupedItems_groupsByCategory() {
        sut.addItem(name: "Apples", category: "Produce")
        sut.addItem(name: "Bananas", category: "Produce")
        sut.addItem(name: "Milk", category: "Dairy")
        let groups = sut.groupedItems()
        XCTAssertEqual(groups.count, 2)
        let dairyGroup = groups.first { $0.category == "Dairy" }
        XCTAssertEqual(dairyGroup?.items.count, 1)
    }

    // MARK: - uncheckedCount / checkedCount

    func testUncheckedCount_countsUncheckItems() {
        sut.addItem(name: "A")
        sut.addItem(name: "B")
        sut.toggleItem(at: 0)
        XCTAssertEqual(sut.uncheckedCount(), 1)
        XCTAssertEqual(sut.checkedCount(), 1)
    }

    // MARK: - Recurring / staple items

    func testToggleRecurring_flipsFlag() {
        sut.addItem(name: "Eggs")
        XCTAssertFalse(sut.items[0].isRecurring)
        sut.toggleRecurring(at: 0)
        XCTAssertTrue(sut.items[0].isRecurring)
        sut.toggleRecurring(at: 0)
        XCTAssertFalse(sut.items[0].isRecurring)
    }

    func testToggleRecurring_outOfBounds_doesNotCrash() {
        sut.addItem(name: "A")
        sut.toggleRecurring(at: 5)
        XCTAssertEqual(sut.items.count, 1)
    }

    func testClearChecked_recurringCheckedItem_isUncheckedNotRemoved() {
        sut.addItem(name: "Eggs")
        sut.toggleRecurring(at: 0)
        sut.toggleItem(at: 0)
        sut.clearCheckedItems()
        XCTAssertEqual(sut.items.count, 1)
        XCTAssertFalse(sut.items[0].isChecked)
        XCTAssertTrue(sut.items[0].isRecurring)
    }

    func testClearChecked_nonRecurringCheckedItem_isRemoved() {
        sut.addItem(name: "Butter")
        sut.toggleItem(at: 0)
        sut.clearCheckedItems()
        XCTAssertTrue(sut.items.isEmpty)
    }

    func testClearAll_recurringItem_survivesAsUnchecked() {
        sut.addItem(name: "Eggs")
        sut.toggleRecurring(at: 0)
        sut.toggleItem(at: 0)
        sut.clearAllItems()
        XCTAssertEqual(sut.items.count, 1)
        XCTAssertFalse(sut.items[0].isChecked)
        XCTAssertTrue(sut.items[0].isRecurring)
    }

    func testClearAll_nonRecurringItem_isRemoved() {
        sut.addItem(name: "Butter")
        sut.clearAllItems()
        XCTAssertTrue(sut.items.isEmpty)
    }

    func testClearAll_mixedItems_onlyRecurringSurvive() {
        sut.addItem(name: "Eggs")      // recurring
        sut.addItem(name: "Butter")   // one-time
        sut.toggleRecurring(at: 0)
        sut.clearAllItems()
        XCTAssertEqual(sut.items.count, 1)
        XCTAssertEqual(sut.items[0].name, "Eggs")
    }

    // MARK: - Persistence

    func testPersistence_acrossReload() {
        sut.addItem(name: "Tomatoes", quantity: 3, category: "Produce")
        let sut2 = ShoppingListManager(storage: storage)
        XCTAssertEqual(sut2.items.count, 1)
        XCTAssertEqual(sut2.items[0].name, "Tomatoes")
    }
}
