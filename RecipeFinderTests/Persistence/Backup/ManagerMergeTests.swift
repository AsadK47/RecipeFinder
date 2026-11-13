import Testing
import Foundation
@testable import RecipeFinder

/// Each store manager's `merge(_:)` restore seam must be non-destructive, dedupe by identity, and persist across a fresh manager.
/// Critically it must NOT re-stamp `createdDate` (root cause of the old "corrupted on restore" export — see data-durability notes).
@MainActor
@Suite struct ManagerMergeTests {

    /// Fresh, isolated storage.
    private static func makeStorage() -> LocalStore {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let storage = LocalStore(userDefaults: defaults)
        return storage
    }

    // MARK: - ShoppingListManager

    @Test func shopping_mergeIsNonDestructiveAndPersists() {
        let storage = Self.makeStorage()
        let shoppingListStore = InMemoryShoppingListStore()
        let sut = ShoppingListManager(storage: storage, shoppingListStore: shoppingListStore)
        sut.addItem(name: "Milk")

        sut.merge([ShoppingListModel(name: "Backup Bread")])

        #expect(sut.items.contains { $0.name == "Milk" })
        #expect(sut.items.contains { $0.name == "Backup Bread" })

        let reloaded = ShoppingListManager(storage: storage, shoppingListStore: shoppingListStore)
        #expect(reloaded.items.count == 2)
    }

    @Test func shopping_mergeDedupesById() {
        let sut = ShoppingListManager(storage: Self.makeStorage(), shoppingListStore: InMemoryShoppingListStore())
        let id = UUID()
        sut.merge([ShoppingListModel(id: id, name: "Eggs")])
        sut.merge([ShoppingListModel(id: id, name: "Eggs-dupe")])
        #expect(sut.items.filter { $0.id == id }.count == 1)
    }

    // MARK: - KitchenInventoryManager (two stores)

    @Test func kitchen_mergeUnionsBothStoresAndPersists() {
        let storage = Self.makeStorage()
        let kitchenStore = InMemoryKitchenStore()
        let sut = KitchenInventoryManager(storage: storage, kitchenStore: kitchenStore)
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

        let reloaded = KitchenInventoryManager(storage: storage, kitchenStore: kitchenStore)
        #expect(reloaded.items.count == 2)
        #expect(reloaded.inventoryItems.count == 2)
    }

    @Test func kitchen_mergeDedupesById() {
        let sut = KitchenInventoryManager(storage: Self.makeStorage(), kitchenStore: InMemoryKitchenStore())
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
        let mealPlanStore = InMemoryMealPlanStore()
        let sut = MealPlanningManager(storage: storage, mealPlanStore: mealPlanStore)
        let existing = MealPlanModel(recipeId: UUID(), recipeName: "Existing", date: Date(), mealTime: .breakfast)
        sut.addMealPlan(existing)

        let incoming = MealPlanModel(recipeId: UUID(), recipeName: "Imported", date: Date(), mealTime: .dinner)
        sut.merge([incoming])

        #expect(sut.mealPlans.contains { $0.recipeName == "Existing" })
        #expect(sut.mealPlans.contains { $0.recipeName == "Imported" })

        let reloaded = MealPlanningManager(storage: storage, mealPlanStore: mealPlanStore)
        #expect(reloaded.mealPlans.count == 2)
    }

    @Test func mealPlans_mergePreservesIncomingDate() {
        let sut = MealPlanningManager(storage: Self.makeStorage(), mealPlanStore: InMemoryMealPlanStore())
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

    // MARK: - CollectionManager

    @Test func collections_mergeIsNonDestructiveAndPersists() {
        let storage = Self.makeStorage()
        let store = InMemoryCollectionStore()
        let sut = CollectionManager(storage: storage, collectionStore: store)
        sut.createCollection(name: "Local")

        sut.merge([RecipeCollection(name: "Backup Collection")])

        #expect(sut.collections.contains { $0.name == "Local" })
        #expect(sut.collections.contains { $0.name == "Backup Collection" })

        let reloaded = CollectionManager(storage: storage, collectionStore: store)
        #expect(reloaded.collections.count == 2)
    }

    @Test func collections_mergeDedupesById() {
        let sut = CollectionManager(storage: Self.makeStorage(), collectionStore: InMemoryCollectionStore())
        let existing = RecipeCollection(name: "Pasta Night")
        sut.merge([existing])
        sut.merge([existing])
        #expect(sut.collections.filter { $0.id == existing.id }.count == 1)
    }

    @Test func collections_mergePreservesRecipeMembership() {
        let storage = Self.makeStorage()
        let store = InMemoryCollectionStore()
        let sut = CollectionManager(storage: storage, collectionStore: store)
        let recipeID = UUID()
        let collection = RecipeCollection(name: "Soups", recipeIDs: [recipeID])
        sut.merge([collection])

        let reloaded = CollectionManager(storage: storage, collectionStore: store)
        #expect(reloaded.collections.first?.contains(recipeID) == true)
    }

    @Test func collections_purgeRemovesRecipeFromAllCollections() {
        let sut = CollectionManager(storage: Self.makeStorage(), collectionStore: InMemoryCollectionStore())
        sut.createCollection(name: "A")
        sut.createCollection(name: "B")
        let id = UUID()
        sut.add(recipeID: id, to: sut.collections[0])
        sut.add(recipeID: id, to: sut.collections[1])

        sut.purge(recipeID: id)

        #expect(!sut.collections[0].contains(id))
        #expect(!sut.collections[1].contains(id))
    }
}
