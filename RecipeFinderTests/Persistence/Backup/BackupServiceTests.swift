import Testing
import Foundation
@testable import RecipeFinder

/// End-to-end `BackupService`: `makeArchive()` gathers every store, `restore()` merges back non-destructively (recipe store faked in-memory, others real managers on isolated storage).
@MainActor
@Suite struct BackupServiceTests {

    /// In-memory stand-in for the Core Data recipe store.
    final class InMemoryRecipeStore: RecipeBackupStore {
        var recipes: [RecipeModel]
        init(_ recipes: [RecipeModel] = []) { self.recipes = recipes }
        func fetchRecipes() -> [RecipeModel] { recipes }
        func mergeRecipes(_ incoming: [RecipeModel]) {
            recipes = BackupMerge.mergedRecipes(existing: recipes, incoming: incoming)
        }
    }

    struct Harness {
        let service: BackupService
        let recipeStore: InMemoryRecipeStore
        let shopping: ShoppingListManager
        let kitchen: KitchenInventoryManager
        let mealPlans: MealPlanningManager
        let badges: BadgeManager
        let collections: CollectionManager
    }

    private static func makeHarness(recipes: [RecipeModel] = []) -> Harness {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let storage = LocalStore(userDefaults: defaults)

        let recipeStore = InMemoryRecipeStore(recipes)
        let shopping = ShoppingListManager(storage: storage)
        let kitchen = KitchenInventoryManager(storage: storage)
        let mealPlans = MealPlanningManager(storage: storage)
        let badges = BadgeManager(storage: storage)
        let collections = CollectionManager(storage: storage)

        let service = BackupService(
            recipeStore: recipeStore, shopping: shopping,
            kitchen: kitchen, mealPlans: mealPlans, badges: badges,
            collections: collections
        )
        return Harness(service: service, recipeStore: recipeStore,
                       shopping: shopping, kitchen: kitchen, mealPlans: mealPlans,
                       badges: badges, collections: collections)
    }

    private static func recipe(_ name: String) -> RecipeModel {
        RecipeModel(name: name, category: "Main", difficulty: "Basic", prepTime: "5 min",
                    cookingTime: "10 min", baseServings: 2, ingredients: [],
                    prePrepInstructions: [], instructions: ["step"], notes: "")
    }

    private static func badge(_ id: String) -> Badge {
        Badge(id: id, title: id, description: "", icon: "", color: "green",
              dateEarned: Date(), isUnlocked: true, howToEarn: "")
    }

    /// Populates a harness's stores with one item of each kind.
    private static func seed(_ h: Harness) {
        h.recipeStore.recipes = [recipe("Soup")]
        h.shopping.addItem(name: "Milk")
        h.kitchen.addItem(name: "Flour")
        h.kitchen.addInventoryItem(KitchenInventoryModel(name: "Rice", category: .grains, quantity: 1, unit: "kg"))
        h.mealPlans.addMealPlan(MealPlanModel(recipeId: UUID(), recipeName: "Soup", date: Date(), mealTime: .dinner))
        h.badges.merge(["explorer": badge("explorer")])
        h.collections.createCollection(name: "Weeknight Dinners", color: .teal)
    }

    // MARK: - makeArchive

    @Test func makeArchive_gathersEveryStore() {
        let h = Self.makeHarness()
        Self.seed(h)

        let archive = h.service.makeArchive()

        #expect(archive.recipes.contains { $0.name == "Soup" })
        #expect(archive.shoppingList.contains { $0.name == "Milk" })
        #expect(archive.kitchenItems.contains { $0.name == "Flour" })
        #expect(archive.kitchenInventory.contains { $0.name == "Rice" })
        #expect(archive.mealPlans.contains { $0.recipeName == "Soup" })
        #expect(archive.badges["explorer"] != nil)
        #expect(archive.collections.contains { $0.name == "Weeknight Dinners" })
        #expect(archive.schemaVersion == BackupArchive.currentSchemaVersion)
    }

    // MARK: - restore round-trip

    @Test func restore_intoEmptyLibrary_bringsEverythingBack() {
        let source = Self.makeHarness()
        Self.seed(source)
        let archive = source.service.makeArchive()

        let dest = Self.makeHarness()
        dest.service.restore(archive)

        #expect(dest.recipeStore.recipes.contains { $0.name == "Soup" })
        #expect(dest.shopping.items.contains { $0.name == "Milk" })
        #expect(dest.kitchen.items.contains { $0.name == "Flour" })
        #expect(dest.kitchen.inventoryItems.contains { $0.name == "Rice" })
        #expect(dest.mealPlans.mealPlans.contains { $0.recipeName == "Soup" })
        #expect(dest.badges.unlockedBadges["explorer"] != nil)
        #expect(dest.collections.collections.contains { $0.name == "Weeknight Dinners" })
    }

    @Test func restore_collections_nonDestructive_keepsExistingAndAddsNew() {
        let source = Self.makeHarness()
        source.collections.createCollection(name: "From Backup")
        let archive = source.service.makeArchive()

        let dest = Self.makeHarness()
        dest.collections.createCollection(name: "Local Collection")
        dest.service.restore(archive)

        #expect(dest.collections.collections.contains { $0.name == "Local Collection" })
        #expect(dest.collections.collections.contains { $0.name == "From Backup" })
    }

    @Test func restore_collections_preservesRecipeMembership() {
        let recipeID = UUID()
        let source = Self.makeHarness()
        source.collections.createCollection(name: "Pasta Night")
        source.collections.add(recipeID: recipeID, to: source.collections.collections[0])
        let archive = source.service.makeArchive()

        let dest = Self.makeHarness()
        dest.service.restore(archive)

        let restored = dest.collections.collections.first { $0.name == "Pasta Night" }
        #expect(restored != nil)
        #expect(restored?.contains(recipeID) == true)
    }

    @Test func restore_isNonDestructive_keepsExistingWork() {
        let source = Self.makeHarness()
        source.shopping.addItem(name: "From Backup")
        let archive = source.service.makeArchive()

        let dest = Self.makeHarness()
        dest.shopping.addItem(name: "Local Work")
        dest.service.restore(archive)

        #expect(dest.shopping.items.contains { $0.name == "Local Work" })
        #expect(dest.shopping.items.contains { $0.name == "From Backup" })
    }

    // MARK: - Data round-trip

    @Test func exportImport_dataRoundTrip() throws {
        let source = Self.makeHarness()
        Self.seed(source)
        let data = try source.service.exportData()

        let dest = Self.makeHarness()
        try dest.service.importData(data)

        #expect(dest.recipeStore.recipes.contains { $0.name == "Soup" })
        #expect(dest.shopping.items.contains { $0.name == "Milk" })
        #expect(dest.mealPlans.mealPlans.contains { $0.recipeName == "Soup" })
        #expect(dest.collections.collections.contains { $0.name == "Weeknight Dinners" })
    }

    @Test func importData_rejectsGarbage() {
        let dest = Self.makeHarness()
        #expect(throws: BackupError.corruptedData) {
            try dest.service.importData(Data("not a backup".utf8))
        }
    }
}
