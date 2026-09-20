import Testing
import Foundation
@testable import RecipeFinder

/// Integration for the JSON-backed stores' per-account scoping across a
/// simulated app restart. Every manager scopes through the same mechanism
/// (`UserScopedStorage`'s per-user key prefix), so `ShoppingListManager` stands
/// in for the pattern: data written under one account survives a fresh manager
/// (a relaunch) and stays invisible to a different account.
@MainActor
@Suite struct ManagerScopePersistenceTests {

    private func freshStorage() -> UserScopedStorage {
        UserScopedStorage(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
    }

    @Test func itemsSurviveRestartUnderSameUser() async throws {
        let storage = freshStorage()
        storage.currentUserId = "userA"
        ShoppingListManager(storage: storage).addItem(name: "Milk")

        // saveItems uses Task.detached — yield to let it write before reloading
        try await Task.sleep(for: .milliseconds(100))

        // Fresh manager over the same storage = an app relaunch.
        let relaunched = ShoppingListManager(storage: storage)
        #expect(relaunched.items.map(\.name) == ["Milk"])
    }

    @Test func itemsAreIsolatedPerUserAcrossRestart() async throws {
        let storage = freshStorage()

        storage.currentUserId = "userA"
        ShoppingListManager(storage: storage).addItem(name: "Milk")

        // saveItems uses Task.detached — yield to let each write land before reloading
        try await Task.sleep(for: .milliseconds(100))

        // Switch account: a fresh manager sees none of A's items.
        storage.currentUserId = "userB"
        let asB = ShoppingListManager(storage: storage)
        #expect(asB.items.isEmpty)
        asB.addItem(name: "Eggs")

        try await Task.sleep(for: .milliseconds(100))

        // Back to A: A's items are intact and B's are not visible.
        storage.currentUserId = "userA"
        let asA = ShoppingListManager(storage: storage)
        #expect(asA.items.map(\.name) == ["Milk"])
    }
}
