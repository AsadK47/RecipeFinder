import Foundation
import Testing
@testable import RecipeFinder

@MainActor
@Suite("Grocery stores")
struct GroceryStoresTests {

    private func makeStorage() throws -> LocalStore {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        return LocalStore(userDefaults: defaults)
    }

    // MARK: - Filtering

    @Test("Untagged items show under every store")
    func untaggedItemShowsEverywhere() {
        let item = ShoppingListModel(name: "Milk")
        #expect(item.isAvailable(at: "Lidl"))
        #expect(item.isAvailable(at: nil))
    }

    @Test("Tagged items show only under their stores or All")
    func taggedItemShowsOnlyAtItsStores() {
        let item = ShoppingListModel(name: "Halloumi", stores: ["Lidl", "Tesco"])
        #expect(item.isAvailable(at: "Lidl"))
        #expect(item.isAvailable(at: "Tesco"))
        #expect(!item.isAvailable(at: "Aldi"))
        #expect(item.isAvailable(at: nil))
    }

    // MARK: - Names

    @Test("Store names are trimmed; blanks and case-insensitive duplicates are rejected",
          arguments: [("  Lidl ", "Lidl"), ("   ", nil), ("tesco", nil), ("Aldi", "Aldi")] as [(String, String?)])
    func validatesNames(raw: String, expected: String?) {
        #expect(GroceryStoreNames.validated(raw, existing: ["Tesco"]) == expected)
    }

    // MARK: - Migration

    @Test("A single legacy store tag decodes into the stores list")
    func legacyPreferredStoreMigrates() throws {
        let json = """
        [{"id":"\(UUID().uuidString)","name":"Butter","quantity":1,"unit":"","isChecked":false,
          "category":"Dairy & Eggs","dateAdded":0,"preferredStore":"Waitrose"}]
        """
        let items = try JSONDecoder().decode([ShoppingListModel].self, from: Data(json.utf8))
        #expect(items.first?.stores == ["Waitrose"])
    }

    @Test("Existing tags seed the store list on first load")
    func storeListSeededFromExistingTags() throws {
        let storage = try makeStorage()
        let tagged = [
            ShoppingListModel(name: "Milk", stores: ["Tesco"]),
            ShoppingListModel(name: "Bread", stores: ["Lidl", "Tesco"])
        ]
        storage.setEncodable(tagged, forKey: Constants.UserDefaultsKeys.shoppingListItems)

        let sut = ShoppingListManager(storage: storage, shoppingListStore: InMemoryShoppingListStore())
        #expect(sut.stores == ["Tesco", "Lidl"])
    }

    // MARK: - Managing stores

    @Test("Added stores persist across relaunch")
    func addedStoresPersist() throws {
        let storage = try makeStorage()
        let shoppingListStore = InMemoryShoppingListStore()
        let sut = ShoppingListManager(storage: storage, shoppingListStore: shoppingListStore)
        #expect(sut.addStore("Lidl"))
        #expect(!sut.addStore("lidl"))

        #expect(ShoppingListManager(storage: storage, shoppingListStore: shoppingListStore).stores == ["Lidl"])
    }

    @Test("Renaming a store retags its items")
    func renameRetagsItems() throws {
        let sut = ShoppingListManager(storage: try makeStorage(), shoppingListStore: InMemoryShoppingListStore())
        sut.addStore("Sainsburys")
        sut.addItem(name: "Eggs")
        let id = try #require(sut.items.first?.id)
        sut.setStore("Sainsburys", assigned: true, forItemIDs: [id])

        #expect(sut.renameStore("Sainsburys", to: "Sainsbury's"))
        #expect(sut.stores == ["Sainsbury's"])
        #expect(sut.items.first?.stores == ["Sainsbury's"])
    }

    @Test("Deleting a store untags its items but keeps them")
    func deleteUntagsItems() throws {
        let sut = ShoppingListManager(storage: try makeStorage(), shoppingListStore: InMemoryShoppingListStore())
        sut.addStore("Aldi")
        sut.addItem(name: "Rice")
        let id = try #require(sut.items.first?.id)
        sut.setStore("Aldi", assigned: true, forItemIDs: [id])

        sut.deleteStore("Aldi")
        #expect(sut.stores.isEmpty)
        #expect(sut.items.count == 1)
        #expect(sut.items.first?.stores.isEmpty == true)
    }

    @Test("Assigning tags only the chosen items, and unassigning removes the tag")
    func bulkAssignAndUnassign() throws {
        let sut = ShoppingListManager(storage: try makeStorage(), shoppingListStore: InMemoryShoppingListStore())
        sut.addStore("Lidl")
        sut.addItem(name: "Apples")
        sut.addItem(name: "Pasta")
        sut.addItem(name: "Soap")
        let ids = Set(sut.items.prefix(2).map(\.id))

        sut.setStore("Lidl", assigned: true, forItemIDs: ids)
        #expect(sut.items.filter { $0.stores == ["Lidl"] }.count == 2)
        #expect(sut.items.last?.stores.isEmpty == true)

        sut.setStore("Lidl", assigned: false, forItemIDs: ids)
        #expect(sut.items.allSatisfy { $0.stores.isEmpty })
    }
}
