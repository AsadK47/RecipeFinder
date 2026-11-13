import Testing
import CoreData
import Foundation
@testable import RecipeFinder

/// Shopping list fake: arrays, with switches to make reads or writes fail like a broken store.
@MainActor
final class InMemoryShoppingListStore: ShoppingListStoring {
    var items: [ShoppingListModel]
    var stores: [String]
    var failWrites = false
    var failReads = false
    private(set) var writeCount = 0

    init(_ items: [ShoppingListModel] = [], stores: [String] = []) {
        self.items = items
        self.stores = stores
    }

    func fetchItems() throws -> [ShoppingListModel] {
        if failReads { throw ShoppingListStoreError.storeUnavailable }
        return items
    }

    func replaceItems(with replacement: [ShoppingListModel]) throws {
        if failWrites { throw ShoppingListStoreError.storeUnavailable }
        writeCount += 1
        items = replacement
    }

    func fetchStores() throws -> [String] {
        if failReads { throw ShoppingListStoreError.storeUnavailable }
        return stores
    }

    func replaceStores(with replacement: [String]) throws {
        if failWrites { throw ShoppingListStoreError.storeUnavailable }
        writeCount += 1
        stores = replacement
    }
}

/// Moving the shopping list and grocery stores blobs out of `LocalStore` into `ShoppingItemEntity` /
/// `ShoppingStoreEntity` (Data safety 1/4, slice 3d). The shared copy/fallback rules are covered in depth by
/// `CollectionMigrationTests` (same `MirroredSnapshot`); these pin the shopping wiring and the Core Data mapping.
@MainActor
@Suite struct ShoppingListMigrationTests {
    private let itemsKey = ShoppingListManager.itemsBlobKey
    private let storesKey = ShoppingListManager.storesBlobKey
    private let storage = LocalStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
    private let pasta: ShoppingListModel = {
        var item = ShoppingListModel(
            name: "Penne", isChecked: true, quantity: 2, unit: "bags", category: "Grains & Pasta",
            dateAdded: Date(timeIntervalSinceReferenceDate: 815_000_000), stores: ["Tesco", "Lidl"], isRecurring: true
        )
        item.isCompleted = false   // older builds could leave this out of step with isChecked; keep what was saved
        return item
    }()
    private let peas = ShoppingListModel(
        name: "Peas", quantity: 1, category: "Frozen", dateAdded: Date(timeIntervalSinceReferenceDate: 815_100_000)
    )
    private var both: [ShoppingListModel] { [pasta, peas] }

    private func writeBlobs(_ items: [ShoppingListModel], stores: [String]? = ["Tesco", "Lidl"]) {
        storage.setEncodable(items, forKey: itemsKey)
        if let stores { storage.setEncodable(stores, forKey: storesKey) }
    }

    private func keptItems() -> [ShoppingListModel]? {
        storage.decodable([ShoppingListModel].self, forKey: itemsKey)
    }

    private func keptStores() -> [String]? {
        storage.decodable([String].self, forKey: storesKey)
    }

    private func migrated(_ key: String) -> Bool {
        storage.bool(forKey: MirroredSnapshot<ShoppingListModel>.flagKey(for: key))
    }

    private func manager(_ store: any ShoppingListStoring) -> ShoppingListManager {
        ShoppingListManager(storage: storage, shoppingListStore: store, badgeManager: BadgeManager(storage: storage))
    }

    // MARK: - Migration

    @Test func everyBlobItemAndStoreBecomesARowInOrderAndBothKeysAreMarked() {
        writeBlobs(both, stores: ["Tesco", "Lidl", "Aldi"])
        let store = InMemoryShoppingListStore()
        let sut = manager(store)
        #expect(store.items == both)
        #expect(store.stores == ["Tesco", "Lidl", "Aldi"])
        #expect(sut.items == both)
        #expect(sut.stores == ["Tesco", "Lidl", "Aldi"])
        #expect(migrated(itemsKey) && migrated(storesKey))
        #expect(keptItems() == both)
    }

    @Test func aFailedWriteLeavesTheKeysUnmarkedAndTheCookKeepsTheirList() {
        writeBlobs(both)
        let store = InMemoryShoppingListStore()
        store.failWrites = true
        let sut = manager(store)
        #expect(!migrated(itemsKey) && !migrated(storesKey))
        #expect(sut.items == both)
        #expect(sut.stores == ["Tesco", "Lidl"])
    }

    @Test func aCorruptBlobIsKeptAsideAndTheStoreIsLeftAlone() {
        storage.set(Data("not json".utf8), forKey: itemsKey)
        storage.set(Data("not json".utf8), forKey: storesKey)
        let store = InMemoryShoppingListStore([peas], stores: ["Aldi"])
        let sut = manager(store)
        #expect(sut.items == [peas])
        #expect(sut.stores == ["Aldi"])
        #expect(store.items == [peas])
    }

    @Test func anItemAddedWhileTheStoreFailsIsKeptNextLaunch() {
        let store = InMemoryShoppingListStore()
        let sut = manager(store)
        store.failWrites = true
        sut.addItem(name: "Milk")
        sut.addStore("Co-op")

        store.failWrites = false
        let nextLaunch = manager(store)
        #expect(nextLaunch.items.map(\.name) == ["Milk"])
        #expect(store.items.map(\.name) == ["Milk"])
        #expect(store.stores == ["Co-op"])
    }

    @Test func storesFromBeforeUserDefinedStoresAreSeededIntoTheStore() {
        writeBlobs(both, stores: nil)
        let store = InMemoryShoppingListStore()
        let sut = manager(store)
        #expect(sut.stores == ["Tesco", "Lidl"])
        #expect(store.stores == ["Tesco", "Lidl"])
    }

    @Test func anEmptyStoreListTheCookSavedIsNotReseeded() {
        writeBlobs(both, stores: [])
        let store = InMemoryShoppingListStore()
        #expect(manager(store).stores.isEmpty)
        #expect(manager(store).stores.isEmpty)
    }

    @Test func aRenamedLegacyCategoryIsSavedToTheStore() {
        var old = peas
        old.category = "Frozen Foods"
        writeBlobs([old])
        let store = InMemoryShoppingListStore()
        let sut = manager(store)
        #expect(sut.items.map(\.category) == ["Frozen"])
        #expect(store.items.map(\.category) == ["Frozen"])
        #expect(keptItems()?.map(\.category) == ["Frozen"])
    }

    // MARK: - Manager on entities

    @Test func editsGoToTheStoreAndTheKeptCopy() throws {
        let store = InMemoryShoppingListStore()
        let sut = manager(store)
        sut.addStore("Lidl")
        sut.addItem(name: "Eggs")
        sut.addItem(name: "Rice")
        sut.toggleItem(at: 0)
        sut.toggleRecurring(at: 1)
        let rice = try #require(sut.items.last?.id)
        sut.setStore("Lidl", assigned: true, forItemIDs: [rice])
        sut.renameStore("Lidl", to: "Lidl Plus")
        #expect(store.items == sut.items)
        #expect(keptItems() == sut.items)
        #expect(store.stores == ["Lidl Plus"])
        #expect(store.items.last?.stores == ["Lidl Plus"])
        sut.deleteItem(at: 0)
        #expect(store.items.map(\.name) == ["Rice"])
    }

    @Test func removeAllShoppingDataEmptiesTheStore() {
        let store = InMemoryShoppingListStore(both, stores: ["Tesco", "Lidl"])
        writeBlobs(both)
        let sut = manager(store)
        sut.removeAllShoppingData()
        #expect(sut.items.isEmpty)
        #expect(sut.stores.isEmpty)
        #expect(store.items.isEmpty)
        #expect(store.stores.isEmpty)
        #expect(manager(store).items.isEmpty)
    }

    @Test func anItemAddedNowIsNotRewrittenOnRelaunch() {
        // Sub-second dates must survive the kept copy's JSON, or every launch would see "differs" and rewrite rows.
        let store = InMemoryShoppingListStore()
        manager(store).addItem(name: "Bread")
        let writes = store.writeCount
        _ = manager(store)
        #expect(store.writeCount == writes)
    }

    @Test func resetAsSettingsRunsItClearsTheList() {
        // DataManagementSettingsView: LocalStore.clearAll() (drops blobs + flags), then removeAllShoppingData().
        writeBlobs(both)
        let store = InMemoryShoppingListStore()
        let sut = manager(store)
        storage.clearAll()
        sut.removeAllShoppingData()
        #expect(sut.items.isEmpty)
        let nextLaunch = manager(store)
        #expect(nextLaunch.items.isEmpty)
        #expect(nextLaunch.stores.isEmpty)
    }

    @Test func aResetWhoseDeleteFailsIsFinishedNextLaunch() {
        let store = InMemoryShoppingListStore(both, stores: ["Tesco"])
        let sut = manager(store)
        store.failWrites = true
        sut.removeAllShoppingData()
        #expect(sut.items.isEmpty)

        store.failWrites = false
        let nextLaunch = manager(store)
        #expect(nextLaunch.items.isEmpty)
        #expect(store.items.isEmpty)
        #expect(store.stores.isEmpty)
    }

    // MARK: - Core Data store (framework exemption: in-memory SQLite, like CoreDataStorePersistenceTests)

    @Test func coreDataStoreRoundTripsEveryFieldInOrder() throws {
        let sut = CoreDataShoppingListStore(persistence: PersistenceController(inMemory: true))
        try sut.replaceItems(with: [peas, pasta])
        #expect(try sut.fetchItems() == [peas, pasta])
        try sut.replaceItems(with: [pasta, peas])
        #expect(try sut.fetchItems() == [pasta, peas])
    }

    @Test func coreDataStoreKeepsTodaysExactTimes() throws {
        let now = ShoppingListModel(name: "Bread", dateAdded: Date())
        let sut = CoreDataShoppingListStore(persistence: PersistenceController(inMemory: true))
        try sut.replaceItems(with: [now])
        #expect(try sut.fetchItems() == [now])
    }

    @Test func coreDataStoreUpdatesExistingRowsInsteadOfReinserting() throws {
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        let sut = CoreDataShoppingListStore(persistence: persistence)
        try sut.replaceItems(with: both)
        let request = NSFetchRequest<NSManagedObject>(entityName: CoreDataShoppingListStore.itemEntityName)
        let idsBefore = Set(try context.fetch(request).map(\.objectID))

        var untagged = pasta
        untagged.stores = []
        untagged.quantity = 5
        try sut.replaceItems(with: [peas, untagged])
        #expect(Set(try context.fetch(request).map(\.objectID)) == idsBefore)
        #expect(try sut.fetchItems() == [peas, untagged])

        try sut.replaceItems(with: [peas])
        #expect(try context.count(for: request) == 1)
    }

    @Test func coreDataStoreSkipsARowWithoutANameAndCleansUpDuplicates() throws {
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        let sut = CoreDataShoppingListStore(persistence: persistence)
        try sut.replaceItems(with: [peas])
        let entity = try #require(NSEntityDescription.entity(
            forEntityName: CoreDataShoppingListStore.itemEntityName, in: context
        ))
        NSManagedObject(entity: entity, insertInto: context).setValue(peas.id, forKey: "id")   // a sync duplicate
        try context.save()
        #expect(try sut.fetchItems() == [peas])

        try sut.replaceItems(with: [peas])
        let request = NSFetchRequest<NSManagedObject>(entityName: CoreDataShoppingListStore.itemEntityName)
        #expect(try context.count(for: request) == 1)
    }

    @Test func coreDataStoreKeepsGroceryStoresInOrderAndKeepsUnchangedRows() throws {
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        let sut = CoreDataShoppingListStore(persistence: persistence)
        try sut.replaceStores(with: ["Tesco", "Lidl", "Aldi"])
        #expect(try sut.fetchStores() == ["Tesco", "Lidl", "Aldi"])

        let request = NSFetchRequest<NSManagedObject>(entityName: CoreDataShoppingListStore.storeEntityName)
        request.predicate = NSPredicate(format: "name == %@", "Tesco")
        let tescoID = try #require(try context.fetch(request).first?.value(forKey: "id") as? UUID)

        try sut.replaceStores(with: ["Aldi", "Tesco", "Co-op"])
        #expect(try sut.fetchStores() == ["Aldi", "Tesco", "Co-op"])
        #expect(try context.fetch(request).first?.value(forKey: "id") as? UUID == tescoID)
        #expect(try context.count(for: NSFetchRequest<NSManagedObject>(
            entityName: CoreDataShoppingListStore.storeEntityName
        )) == 3)
    }
}
