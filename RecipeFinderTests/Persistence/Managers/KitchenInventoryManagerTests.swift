import XCTest
@testable import RecipeFinder

@MainActor
final class KitchenInventoryManagerTests: XCTestCase {

    private var storage: LocalStore!
    private var sut: KitchenInventoryManager!

    override func setUp() async throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        storage = LocalStore(userDefaults: defaults)
        sut = KitchenInventoryManager(storage: storage)
    }

    override func tearDown() async throws {
        sut = nil
        storage = nil
    }

    // MARK: - Initial state

    func testLoad_migratesLegacyCategoryNames_andPersistsThem() throws {
        struct Legacy: Encodable { let id = UUID(); let name: String; let category: String; let quantity = 1.0; let unit = "item"; let dateAdded = Date() }
        storage.setEncodable([Legacy(name: "Basil", category: "Herbs & Spices"), Legacy(name: "Bread", category: "Grains & Bread")],
                             forKey: Constants.UserDefaultsKeys.kitchenItems)

        let reloaded = KitchenInventoryManager(storage: storage)
        let categories = Set(reloaded.items.map(\.category))
        XCTAssertTrue(categories.isSubset(of: CategoryClassifier.knownCategories), "\(categories)")
        XCTAssertFalse(categories.contains("Herbs & Spices"))

        let again = KitchenInventoryManager(storage: storage)   // migration was saved, not just applied in memory
        XCTAssertEqual(Set(again.items.map(\.category)), categories)
    }


    func testInitialState_isEmpty() {
        XCTAssertTrue(sut.inventoryItems.isEmpty)
    }

    // MARK: - addInventoryItem

    func testAddInventoryItem_addsItem() {
        sut.addInventoryItem(makeItem(name: "Onion"))
        XCTAssertEqual(sut.inventoryItems.count, 1)
        XCTAssertEqual(sut.inventoryItems[0].name, "Onion")
    }

    func testAddInventoryItem_duplicateNameExact_rejected() {
        sut.addInventoryItem(makeItem(name: "Garlic"))
        sut.addInventoryItem(makeItem(name: "Garlic"))
        XCTAssertEqual(sut.inventoryItems.count, 1)
    }

    func testAddInventoryItem_duplicateNameCaseInsensitive_rejected() {
        sut.addInventoryItem(makeItem(name: "garlic"))
        sut.addInventoryItem(makeItem(name: "GARLIC"))
        XCTAssertEqual(sut.inventoryItems.count, 1)
    }

    func testAddInventoryItem_pastExpiryDate_rejected() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        sut.addInventoryItem(makeItem(name: "Milk", expiryDate: yesterday))
        XCTAssertTrue(sut.inventoryItems.isEmpty)
    }

    func testAddInventoryItem_todayExpiryDate_accepted() {
        let today = Calendar.current.startOfDay(for: Date())
        sut.addInventoryItem(makeItem(name: "Milk", expiryDate: today))
        XCTAssertEqual(sut.inventoryItems.count, 1)
    }

    func testAddInventoryItem_futureExpiryDate_accepted() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        sut.addInventoryItem(makeItem(name: "Cheese", expiryDate: tomorrow))
        XCTAssertEqual(sut.inventoryItems.count, 1)
    }

    func testAddInventoryItem_zeroQuantity_rejected() {
        sut.addInventoryItem(makeItem(name: "Salt", quantity: 0))
        XCTAssertTrue(sut.inventoryItems.isEmpty)
    }

    func testAddInventoryItem_negativeQuantity_rejected() {
        sut.addInventoryItem(makeItem(name: "Salt", quantity: -1))
        XCTAssertTrue(sut.inventoryItems.isEmpty)
    }

    func testAddInventoryItem_noExpiryDate_accepted() {
        sut.addInventoryItem(makeItem(name: "Rice", expiryDate: nil))
        XCTAssertEqual(sut.inventoryItems.count, 1)
    }

    // MARK: - removeInventoryItem

    func testRemoveInventoryItem_removesById() {
        sut.addInventoryItem(makeItem(name: "Pepper"))
        let item = sut.inventoryItems[0]
        sut.removeInventoryItem(item)
        XCTAssertTrue(sut.inventoryItems.isEmpty)
    }

    func testRemoveInventoryItem_unknownId_doesNothing() {
        sut.addInventoryItem(makeItem(name: "Pepper"))
        sut.removeInventoryItem(makeItem(name: "Ghost"))
        XCTAssertEqual(sut.inventoryItems.count, 1)
    }

    // MARK: - hasInventoryItem

    func testHasInventoryItem_returnsTrue_whenPresent() {
        sut.addInventoryItem(makeItem(name: "Tomato"))
        XCTAssertTrue(sut.hasInventoryItem("Tomato"))
    }

    func testHasInventoryItem_caseInsensitive() {
        sut.addInventoryItem(makeItem(name: "Tomato"))
        XCTAssertTrue(sut.hasInventoryItem("TOMATO"))
        XCTAssertTrue(sut.hasInventoryItem("tomato"))
    }

    func testHasInventoryItem_returnsFalse_whenAbsent() {
        XCTAssertFalse(sut.hasInventoryItem("Carrot"))
    }

    // MARK: - expiredItems

    func testExpiredItems_returnsOnlyExpired() {
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date())!

        // Add via storage directly since manager rejects past-expiry items
        let expired = makeItem(name: "OldMilk", expiryDate: twoDaysAgo)
        let fresh = makeItem(name: "FreshJuice", expiryDate: nextWeek)
        saveDirectly([expired, fresh])

        XCTAssertEqual(sut.inventoryItems.count, 2)
        let expired_ = sut.expiredItems()
        XCTAssertEqual(expired_.count, 1)
        XCTAssertEqual(expired_[0].name, "OldMilk")
    }

    // MARK: - expiringSoonItems

    func testExpiringSoonItems_returnsItemsExpiringInThreeDaysOrLess() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let nextMonth = Calendar.current.date(byAdding: .day, value: 30, to: Date())!

        let soon = makeItem(name: "YogurtSoon", expiryDate: tomorrow)
        let later = makeItem(name: "YogurtLater", expiryDate: nextMonth)
        saveDirectly([soon, later])

        let results = sut.expiringSoonItems()
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].name, "YogurtSoon")
    }

    // MARK: - lowStockItems

    func testLowStockItems_returnsItemsThatNeedRestock() {
        let lowItem = makeItem(name: "Salt", quantity: 1, isLowStock: true)
        let okItem = makeItem(name: "Pepper", quantity: 5, isLowStock: false)
        saveDirectly([lowItem, okItem])

        let results = sut.lowStockItems()
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].name, "Salt")
    }

    func testLowStockItems_usesMinimumQuantityWhenSet() {
        let belowMin = makeItem(name: "Flour", quantity: 2, minimumQuantity: 5)
        let aboveMin = makeItem(name: "Sugar", quantity: 10, minimumQuantity: 5)
        saveDirectly([belowMin, aboveMin])

        let results = sut.lowStockItems()
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].name, "Flour")
    }

    // MARK: - Persistence

    func testPersistence_acrossReload() {
        sut.addInventoryItem(makeItem(name: "Carrot"))
        let sut2 = KitchenInventoryManager(storage: storage)
        XCTAssertEqual(sut2.inventoryItems.count, 1)
        XCTAssertEqual(sut2.inventoryItems[0].name, "Carrot")
    }

    // MARK: - Helpers

    private func makeItem(
        name: String,
        quantity: Double = 1.0,
        expiryDate: Date? = nil,
        isLowStock: Bool = false,
        minimumQuantity: Double? = nil
    ) -> KitchenInventoryModel {
        KitchenInventoryModel(
            name: name,
            category: .produce,
            quantity: quantity,
            unit: "units",
            expiryDate: expiryDate,
            isLowStock: isLowStock,
            minimumQuantity: minimumQuantity
        )
    }

    /// Bypasses manager validation to seed items directly into storage for query tests.
    private func saveDirectly(_ items: [KitchenInventoryModel]) {
        if let data = try? JSONEncoder().encode(items) {
            storage.set(data, forKey: "kitchenInventoryItems")
        }
        sut.reload()
    }
}
