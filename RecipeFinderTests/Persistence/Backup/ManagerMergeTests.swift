import Testing
import Foundation
@testable import RecipeFinder

/// Tests for the faithful `merge(_:)` restore seam on each store manager.
///
/// The seam must be:
/// - **non-destructive** — everything already present is kept;
/// - **deduping by identity** — re-importing the same item doesn't duplicate it;
/// - **date-faithful** — unlike the normal mutators, restore must NOT re-stamp
///   `createdDate` (that class of bug was the root cause of the old "corrupted on
///   restore" export — see the data-durability notes);
/// - **persisting** — a fresh manager on the same storage sees the merged result.
@MainActor
@Suite struct ManagerMergeTests {

    /// Fresh, isolated per-user storage under a signed-in scope.
    private static func makeStorage() -> UserScopedStorage {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let storage = UserScopedStorage(userDefaults: defaults)
        storage.currentUserId = "merge-test-user"
        return storage
    }

    // MARK: - ShoppingListManager

    @Test func shopping_mergeIsNonDestructiveAndPersists() {
        let storage = Self.makeStorage()
        let sut = ShoppingListManager(storage: storage)
        sut.addItem(name: "Milk")

        sut.merge([ShoppingListModel(name: "Backup Bread")])

        #expect(sut.items.contains { $0.name == "Milk" })
        #expect(sut.items.contains { $0.name == "Backup Bread" })

        let reloaded = ShoppingListManager(storage: storage)
        #expect(reloaded.items.count == 2)
    }

    @Test func shopping_mergeDedupesById() {
        let sut = ShoppingListManager(storage: Self.makeStorage())
        let id = UUID()
        sut.merge([ShoppingListModel(id: id, name: "Eggs")])
        sut.merge([ShoppingListModel(id: id, name: "Eggs-dupe")])
        #expect(sut.items.filter { $0.id == id }.count == 1)
    }

    // MARK: - KitchenInventoryManager (two stores)

    @Test func kitchen_mergeUnionsBothStoresAndPersists() {
        let storage = Self.makeStorage()
        let sut = KitchenInventoryManager(storage: storage)
        sut.addItem(name: "Flour")
        sut.addInventoryItem(KitchenInventoryModel(name: "Rice", category: .grains, quantity: 1, unit: "kg"))

        sut.merge(
            items: [KitchenItem(name: "Sugar", category: "Baking")],
            inventory: [KitchenInventoryModel(name: "Beans", category: .grains, quantity: 2, unit: "cans")]
        )

        #expect(sut.items.contains { $0.name == "Flour" })
        #expect(sut.items.contains { $0.name == "Sugar" })
        #expect(sut.inventoryItems.contains { $0.name == "Rice" })
        #expect(sut.inventoryItems.contains { $0.name == "Beans" })

        let reloaded = KitchenInventoryManager(storage: storage)
        #expect(reloaded.items.count == 2)
        #expect(reloaded.inventoryItems.count == 2)
    }

    @Test func kitchen_mergeDedupesById() {
        let sut = KitchenInventoryManager(storage: Self.makeStorage())
        let itemID = UUID()
        let invID = UUID()
        let item = KitchenItem(id: itemID, name: "Salt", category: "Baking")
        let inv = KitchenInventoryModel(id: invID, name: "Oats", category: .grains, quantity: 1, unit: "kg")
        sut.merge(items: [item], inventory: [inv])
        sut.merge(items: [item], inventory: [inv])
        #expect(sut.items.filter { $0.id == itemID }.count == 1)
        #expect(sut.inventoryItems.filter { $0.id == invID }.count == 1)
    }

    // MARK: - MealPlanningManager

    @Test func mealPlans_mergeIsNonDestructiveAndPersists() {
        let storage = Self.makeStorage()
        let sut = MealPlanningManager(storage: storage)
        let existing = MealPlanModel(recipeId: UUID(), recipeName: "Existing", date: Date(), mealTime: .breakfast)
        sut.addMealPlan(existing)

        let incoming = MealPlanModel(recipeId: UUID(), recipeName: "Imported", date: Date(), mealTime: .dinner)
        sut.merge([incoming])

        #expect(sut.mealPlans.contains { $0.recipeName == "Existing" })
        #expect(sut.mealPlans.contains { $0.recipeName == "Imported" })

        let reloaded = MealPlanningManager(storage: storage)
        #expect(reloaded.mealPlans.count == 2)
    }

    @Test func mealPlans_mergePreservesIncomingDate() {
        let sut = MealPlanningManager(storage: Self.makeStorage())
        let created = Date(timeIntervalSince1970: 5_000)
        let plan = MealPlanModel(recipeId: UUID(), recipeName: "Backup", date: Date(), mealTime: .lunch, createdDate: created)

        sut.merge([plan])

        #expect(sut.mealPlans.first { $0.recipeName == "Backup" }?.createdDate == created)
    }

    // MARK: - BadgeManager

    @Test func badges_mergeUnionsAndExistingWins() {
        let storage = Self.makeStorage()
        let sut = BadgeManager(storage: storage)
        let mine = Date(timeIntervalSince1970: 1_000)
        sut.merge(["first": Badge(id: "first", title: "First", description: "", icon: "", color: "green", dateEarned: mine, isUnlocked: true, howToEarn: "")])

        sut.merge([
            "first": Badge(id: "first", title: "First", description: "", icon: "", color: "green", dateEarned: Date(timeIntervalSince1970: 9_999), isUnlocked: true, howToEarn: ""),
            "second": Badge(id: "second", title: "Second", description: "", icon: "", color: "blue", dateEarned: Date(), isUnlocked: true, howToEarn: "")
        ])

        #expect(Set(sut.unlockedBadges.keys) == ["first", "second"])
        #expect(sut.unlockedBadges["first"]?.dateEarned == mine)

        let reloaded = BadgeManager(storage: storage)
        #expect(Set(reloaded.unlockedBadges.keys) == ["first", "second"])
    }
}
