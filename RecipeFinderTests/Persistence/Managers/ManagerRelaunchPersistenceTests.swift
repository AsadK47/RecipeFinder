import Testing
import Foundation
@testable import RecipeFinder

/// JSON-backed stores survive a simulated restart, with `ShoppingListManager` standing in for the shared `LocalStore` pattern.
@MainActor
@Suite struct ManagerRelaunchPersistenceTests {

    @Test func itemsSurviveRestart() throws {
        let storage = LocalStore(userDefaults: try #require(UserDefaults(suiteName: UUID().uuidString)))
        let shoppingListStore = InMemoryShoppingListStore()
        ShoppingListManager(storage: storage, shoppingListStore: shoppingListStore).addItem(name: "Milk")

        // Fresh manager over the same storage = an app relaunch.
        let relaunched = ShoppingListManager(storage: storage, shoppingListStore: shoppingListStore)
        #expect(relaunched.items.map(\.name) == ["Milk"])
    }
}
