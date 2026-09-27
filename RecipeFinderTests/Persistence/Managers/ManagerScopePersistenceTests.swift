import Testing
import Foundation
@testable import RecipeFinder

/// JSON-backed stores' per-account scoping across a simulated restart, with `ShoppingListManager` standing in for the shared `UserScopedStorage` pattern: data survives a fresh manager and stays invisible to a different account.
@MainActor
@Suite struct ManagerScopePersistenceTests {

    private func freshStorage() -> UserScopedStorage {
        UserScopedStorage(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
    }

    @Test func itemsSurviveRestartUnderSameUser() {
        let storage = freshStorage()
        storage.currentUserId = "userA"
        ShoppingListManager(storage: storage).addItem(name: "Milk")

        // Fresh manager over the same storage = an app relaunch.
        let relaunched = ShoppingListManager(storage: storage)
        #expect(relaunched.items.map(\.name) == ["Milk"])
    }

    @Test func itemsAreIsolatedPerUserAcrossRestart() {
        let storage = freshStorage()

        storage.currentUserId = "userA"
        ShoppingListManager(storage: storage).addItem(name: "Milk")

        // Switch account: a fresh manager sees none of A's items.
        storage.currentUserId = "userB"
        let asB = ShoppingListManager(storage: storage)
        #expect(asB.items.isEmpty)
        asB.addItem(name: "Eggs")

        // Back to A: A's items are intact and B's are not visible.
        storage.currentUserId = "userA"
        let asA = ShoppingListManager(storage: storage)
        #expect(asA.items.map(\.name) == ["Milk"])
    }
}
