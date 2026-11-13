import Testing
import CoreData
import Foundation
@testable import RecipeFinder

/// Kitchen fake: arrays, with switches to make reads or writes fail like a broken store.
@MainActor
final class InMemoryKitchenStore: KitchenStoring {
    var items: [KitchenItem]
    var inventory: [KitchenInventoryModel]
    var failWrites = false
    var failReads = false
    private(set) var writeCount = 0

    init(_ items: [KitchenItem] = [], inventory: [KitchenInventoryModel] = []) {
        self.items = items
        self.inventory = inventory
    }

    func fetchItems() throws -> [KitchenItem] {
        if failReads { throw KitchenStoreError.storeUnavailable }
        return items
    }

    func replaceItems(with replacement: [KitchenItem]) throws {
        if failWrites { throw KitchenStoreError.storeUnavailable }
        writeCount += 1
        items = replacement
    }

    func fetchInventory() throws -> [KitchenInventoryModel] {
        if failReads { throw KitchenStoreError.storeUnavailable }
        return inventory
    }

    func replaceInventory(with replacement: [KitchenInventoryModel]) throws {
        if failWrites { throw KitchenStoreError.storeUnavailable }
        writeCount += 1
        inventory = replacement
    }
}

/// Moving the kitchen items and inventory blobs out of `LocalStore` into `KitchenItemEntity` / `InventoryItemEntity`
/// (Data safety 1/4, slice 3e). The shared copy/fallback rules are covered in depth by `CollectionMigrationTests`
/// (same `MirroredSnapshot`); these pin the kitchen wiring and the Core Data mapping.
@MainActor
@Suite struct KitchenMigrationTests {
    private let itemsKey = KitchenInventoryManager.itemsBlobKey
    private let inventoryKey = KitchenInventoryManager.inventoryBlobKey
    private let storage = LocalStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
    private let flour = KitchenItem(
        name: "Flour", category: "Baking Supplies", quantity: 2, unit: "bags",
        dateAdded: Date(timeIntervalSinceReferenceDate: 815_000_000.25)
    )
    private let eggs = KitchenItem(
        name: "Eggs", category: "Dairy & Eggs", dateAdded: Date(timeIntervalSinceReferenceDate: 815_100_000)
    )
    private let milk = KitchenInventoryModel(
        name: "Milk", category: .dairy, quantity: 1.5, unit: "L", storageLocation: .fridge,
        purchaseDate: Date(timeIntervalSinceReferenceDate: 815_000_000.5),
        expiryDate: Date(timeIntervalSinceReferenceDate: 815_500_000), notes: "Oat, for coffee",
        isLowStock: true, minimumQuantity: 0.5
    )
    private let rice = KitchenInventoryModel(
        name: "Rice", category: .grains, quantity: 5, unit: "kg",
        purchaseDate: Date(timeIntervalSinceReferenceDate: 815_200_000)
    )

    private func writeBlobs(_ items: [KitchenItem], inventory: [KitchenInventoryModel]) {
        storage.setEncodable(items, forKey: itemsKey)
        storage.setEncodable(inventory, forKey: inventoryKey)
    }

    private func keptItems() -> [KitchenItem]? {
        storage.decodable([KitchenItem].self, forKey: itemsKey)
    }

    private func keptInventory() -> [KitchenInventoryModel]? {
        storage.decodable([KitchenInventoryModel].self, forKey: inventoryKey)
    }

    private func migrated(_ key: String) -> Bool {
        storage.bool(forKey: MirroredSnapshot<KitchenItem>.flagKey(for: key))
    }

    private func manager(_ store: any KitchenStoring) -> KitchenInventoryManager {
        KitchenInventoryManager(storage: storage, kitchenStore: store)
    }

    // MARK: - iCloud sync (Data safety 2/4)

    @Test func withSyncOnAnItemAndAnInventoryItemAnotherDeviceAddedAreKept() {
        writeBlobs([flour], inventory: [milk])
        let store = InMemoryKitchenStore()
        _ = manager(store)
        store.items.append(eggs)   // arrived from another device
        store.inventory.append(rice)
        storage.set(true, forKey: SyncPreference.key)
        let sut = manager(store)
        #expect(sut.items == [flour, eggs])
        #expect(sut.inventoryItems == [milk, rice])
        #expect(keptItems() == [flour, eggs])
        #expect(keptInventory() == [milk, rice])
    }

    // MARK: - Migration

    @Test func everyBlobItemAndInventoryItemBecomesARowInOrderAndBothKeysAreMarked() {
        writeBlobs([flour, eggs], inventory: [milk, rice])
        let store = InMemoryKitchenStore()
        let sut = manager(store)
        #expect(store.items == [flour, eggs])
        #expect(store.inventory == [milk, rice])
        #expect(sut.items == [flour, eggs])
        #expect(sut.inventoryItems == [milk, rice])
        #expect(migrated(itemsKey) && migrated(inventoryKey))
        #expect(keptItems() == [flour, eggs])
        #expect(keptInventory() == [milk, rice])
    }

    @Test func aFailedWriteLeavesTheKeysUnmarkedAndTheCookKeepsTheirKitchen() {
        writeBlobs([flour], inventory: [milk])
        let store = InMemoryKitchenStore()
        store.failWrites = true
        let sut = manager(store)
        #expect(!migrated(itemsKey) && !migrated(inventoryKey))
        #expect(sut.items == [flour])
        #expect(sut.inventoryItems == [milk])
    }

    @Test func aCorruptBlobIsKeptAsideAndTheStoreIsLeftAlone() {
        storage.set(Data("not json".utf8), forKey: itemsKey)
        storage.set(Data("not json".utf8), forKey: inventoryKey)
        let store = InMemoryKitchenStore([eggs], inventory: [rice])
        let sut = manager(store)
        #expect(sut.items == [eggs])
        #expect(sut.inventoryItems == [rice])
        #expect(store.items == [eggs])
        #expect(store.inventory == [rice])
    }

    @Test func anUnreadableStoreFallsBackToTheKeptCopy() {
        writeBlobs([flour], inventory: [milk])
        let store = InMemoryKitchenStore()
        store.failReads = true
        let sut = manager(store)
        #expect(sut.items == [flour])
        #expect(sut.inventoryItems == [milk])
        #expect(!migrated(itemsKey) && !migrated(inventoryKey))
    }

    @Test func anItemAddedWhileTheStoreFailsIsKeptNextLaunch() {
        let store = InMemoryKitchenStore()
        let sut = manager(store)
        store.failWrites = true
        sut.addItem(name: "Salt")
        sut.merge(items: [], inventory: [rice])

        store.failWrites = false
        let nextLaunch = manager(store)
        #expect(nextLaunch.items.map(\.name) == ["Salt"])
        #expect(nextLaunch.inventoryItems == [rice])
        #expect(store.items.map(\.name) == ["Salt"])
        #expect(store.inventory == [rice])
    }

    @Test func aRenamedLegacyCategoryIsSavedToTheStore() {
        var old = eggs
        old.category = "Frozen Foods"
        writeBlobs([old], inventory: [])
        let store = InMemoryKitchenStore()
        let sut = manager(store)
        #expect(sut.items.map(\.category) == ["Frozen"])
        #expect(store.items.map(\.category) == ["Frozen"])
        #expect(keptItems()?.map(\.category) == ["Frozen"])
    }

    // MARK: - Manager on entities

    @Test func editsGoToTheStoreAndTheKeptCopy() throws {
        let store = InMemoryKitchenStore()
        let sut = manager(store)
        sut.addItem(name: "Butter")
        sut.addItem(name: "Garlic")
        let butter = try #require(sut.items.first)
        sut.updateQuantity(for: butter, delta: 2)
        sut.updateCategory(for: butter, category: "Baking")
        sut.addInventoryItem(rice)
        var moreRice = rice
        moreRice.quantity = 8
        sut.updateInventoryItem(moreRice)
        #expect(store.items == sut.items)
        #expect(keptItems() == sut.items)
        #expect(store.inventory == [moreRice])
        #expect(keptInventory() == [moreRice])

        sut.toggleItem("Garlic")
        sut.removeInventoryItem(moreRice)
        #expect(store.items.map(\.name) == ["Butter"])
        #expect(store.inventory.isEmpty)
    }

    @Test func clearAllEmptiesTheStoreToo() {
        let store = InMemoryKitchenStore()
        let sut = manager(store)
        sut.addItem(name: "Butter")
        sut.clearAll()
        #expect(store.items.isEmpty)
        #expect(manager(store).items.isEmpty)
    }

    @Test func anItemAddedNowIsNotRewrittenOnRelaunch() {
        // Sub-second dates must survive the kept copy's JSON, or every launch would see "differs" and rewrite rows.
        let store = InMemoryKitchenStore()
        let sut = manager(store)
        sut.addItem(name: "Bread")
        sut.addInventoryItem(KitchenInventoryModel(name: "Oats", category: .grains, quantity: 1, unit: "kg"))
        let writes = store.writeCount
        _ = manager(store)
        #expect(store.writeCount == writes)
    }

    @Test func anOldItemSavedWithoutADateIsNotRewrittenOnRelaunch() {
        struct Old: Encodable { let id = UUID(); let name = "Salt"; let category = "Dried Spices & Seasonings" }
        storage.setEncodable([Old()], forKey: itemsKey)
        let store = InMemoryKitchenStore()
        _ = manager(store)
        let writes = store.writeCount
        _ = manager(store)
        #expect(store.writeCount == writes)
    }

    @Test func removeAllKitchenDataEmptiesTheStore() {
        writeBlobs([flour, eggs], inventory: [milk, rice])
        let store = InMemoryKitchenStore()
        let sut = manager(store)
        sut.removeAllKitchenData()
        #expect(sut.items.isEmpty)
        #expect(sut.inventoryItems.isEmpty)
        #expect(store.items.isEmpty)
        #expect(store.inventory.isEmpty)
        #expect(manager(store).items.isEmpty)
    }

    @Test func resetAsSettingsRunsItClearsTheKitchen() {
        // DataManagementSettingsView: LocalStore.clearAll() (drops blobs + flags), then removeAllKitchenData().
        writeBlobs([flour], inventory: [milk])
        let store = InMemoryKitchenStore()
        let sut = manager(store)
        storage.clearAll()
        sut.removeAllKitchenData()
        #expect(sut.items.isEmpty)
        let nextLaunch = manager(store)
        #expect(nextLaunch.items.isEmpty)
        #expect(nextLaunch.inventoryItems.isEmpty)
    }

    @Test func aResetWhoseDeleteFailsIsFinishedNextLaunch() {
        let store = InMemoryKitchenStore([flour], inventory: [milk])
        let sut = manager(store)
        store.failWrites = true
        sut.removeAllKitchenData()
        #expect(sut.items.isEmpty)
        #expect(sut.inventoryItems.isEmpty)

        store.failWrites = false
        let nextLaunch = manager(store)
        #expect(nextLaunch.items.isEmpty)
        #expect(nextLaunch.inventoryItems.isEmpty)
        #expect(store.items.isEmpty)
        #expect(store.inventory.isEmpty)
    }

    // MARK: - Core Data store (framework exemption: in-memory SQLite, like CoreDataStorePersistenceTests)

    @Test func coreDataStoreRoundTripsEveryItemFieldInOrder() throws {
        let sut = CoreDataKitchenStore(persistence: PersistenceController(inMemory: true))
        try sut.replaceItems(with: [eggs, flour])
        #expect(try sut.fetchItems() == [eggs, flour])
        try sut.replaceItems(with: [flour, eggs])
        #expect(try sut.fetchItems() == [flour, eggs])
    }

    @Test func coreDataStoreRoundTripsEveryInventoryFieldInOrder() throws {
        let sut = CoreDataKitchenStore(persistence: PersistenceController(inMemory: true))
        try sut.replaceInventory(with: [rice, milk])
        #expect(try sut.fetchInventory() == [rice, milk])
        try sut.replaceInventory(with: [milk, rice])
        #expect(try sut.fetchInventory() == [milk, rice])
    }

    @Test func coreDataStoreClearsOptionalInventoryFields() throws {
        let sut = CoreDataKitchenStore(persistence: PersistenceController(inMemory: true))
        try sut.replaceInventory(with: [milk])
        var plain = milk
        plain.expiryDate = nil
        plain.notes = nil
        plain.minimumQuantity = nil
        try sut.replaceInventory(with: [plain])
        #expect(try sut.fetchInventory() == [plain])
    }

    @Test func coreDataStoreKeepsTodaysExactTimes() throws {
        let item = KitchenItem(name: "Bread", category: "Bakery", dateAdded: Date())
        let stocked = KitchenInventoryModel(
            name: "Cheese", category: .dairy, quantity: 1, unit: "block", purchaseDate: Date(), expiryDate: Date()
        )
        let sut = CoreDataKitchenStore(persistence: PersistenceController(inMemory: true))
        try sut.replaceItems(with: [item])
        try sut.replaceInventory(with: [stocked])
        #expect(try sut.fetchItems() == [item])
        #expect(try sut.fetchInventory() == [stocked])
    }

    @Test func coreDataStoreUpdatesExistingRowsInsteadOfReinserting() throws {
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        let sut = CoreDataKitchenStore(persistence: persistence)
        try sut.replaceInventory(with: [milk, rice])
        let request = NSFetchRequest<NSManagedObject>(entityName: CoreDataKitchenStore.inventoryEntityName)
        let idsBefore = Set(try context.fetch(request).map(\.objectID))

        var lessRice = rice
        lessRice.quantity = 1
        try sut.replaceInventory(with: [lessRice, milk])
        #expect(Set(try context.fetch(request).map(\.objectID)) == idsBefore)
        #expect(try sut.fetchInventory() == [lessRice, milk])

        try sut.replaceInventory(with: [milk])
        #expect(try context.count(for: request) == 1)
    }

    @Test func coreDataStoreSkipsARowWithoutANameAndCleansUpDuplicates() throws {
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        let sut = CoreDataKitchenStore(persistence: persistence)
        try sut.replaceItems(with: [eggs])
        let entity = try #require(NSEntityDescription.entity(
            forEntityName: CoreDataKitchenStore.itemEntityName, in: context
        ))
        NSManagedObject(entity: entity, insertInto: context).setValue(eggs.id, forKey: "id")   // a sync duplicate
        try context.save()
        #expect(try sut.fetchItems() == [eggs])

        try sut.replaceItems(with: [eggs])
        let request = NSFetchRequest<NSManagedObject>(entityName: CoreDataKitchenStore.itemEntityName)
        #expect(try context.count(for: request) == 1)
    }

    @Test func coreDataStoreReadsAnUnknownCategoryAndLocationAsDefaults() throws {
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        let sut = CoreDataKitchenStore(persistence: persistence)
        try sut.replaceInventory(with: [milk])
        let request = NSFetchRequest<NSManagedObject>(entityName: CoreDataKitchenStore.inventoryEntityName)
        let row = try #require(try context.fetch(request).first)
        row.setValue("Mystery", forKey: "category")
        row.setValue("Shed", forKey: "storageLocation")
        try context.save()
        let read = try #require(try sut.fetchInventory().first)
        #expect(read.category == .other)
        #expect(read.storageLocation == .pantry)
    }
}
