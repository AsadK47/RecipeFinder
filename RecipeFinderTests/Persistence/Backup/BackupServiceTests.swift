import Testing
import Foundation
@testable import RecipeFinder

/// End-to-end tests for `BackupService`: that `makeArchive()` gathers every store
/// and that `restore()` merges an archive back non-destructively. The recipe store
/// is faked in-memory; the other stores are real managers on isolated storage.
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
        let notes: NotesManager
        let shopping: ShoppingListManager
        let kitchen: KitchenInventoryManager
        let mealPlans: MealPlanningManager
        let badges: BadgeManager
        let cookingTips: CookingTipsManager
    }

    private static func makeHarness(recipes: [RecipeModel] = []) -> Harness {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let storage = UserScopedStorage(userDefaults: defaults)
        storage.currentUserId = "backup-test-user"

        let recipeStore = InMemoryRecipeStore(recipes)
        let notes = NotesManager(storage: storage)
        let shopping = ShoppingListManager(storage: storage)
        let kitchen = KitchenInventoryManager(storage: storage)
        let mealPlans = MealPlanningManager(storage: storage)
        let badges = BadgeManager(storage: storage)
        let cookingTips = CookingTipsManager(storage: storage)

        let service = BackupService(
            recipeStore: recipeStore, notes: notes, shopping: shopping,
            kitchen: kitchen, mealPlans: mealPlans, badges: badges, cookingTips: cookingTips
        )
        return Harness(service: service, recipeStore: recipeStore, notes: notes,
                       shopping: shopping, kitchen: kitchen, mealPlans: mealPlans,
                       badges: badges, cookingTips: cookingTips)
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
        h.notes.addNote(NoteModel(title: "Note A"))
        h.shopping.addItem(name: "Milk")
        h.kitchen.addItem(name: "Flour")
        h.kitchen.addInventoryItem(KitchenInventoryModel(name: "Rice", category: .grains, quantity: 1, unit: "kg"))
        h.mealPlans.addMealPlan(MealPlanModel(recipeId: UUID(), recipeName: "Soup", date: Date(), mealTime: .dinner))
        h.badges.merge(["explorer": badge("explorer")])
        h.cookingTips.addTip(CookingTipModel(title: "Salt early", content: "", category: .basics))
    }

    // MARK: - makeArchive

    @Test func makeArchive_gathersEveryStore() {
        let h = Self.makeHarness()
        Self.seed(h)

        let archive = h.service.makeArchive()

        #expect(archive.recipes.contains { $0.name == "Soup" })
        #expect(archive.notes.contains { $0.title == "Note A" })
        #expect(archive.shoppingList.contains { $0.name == "Milk" })
        #expect(archive.kitchenItems.contains { $0.name == "Flour" })
        #expect(archive.kitchenInventory.contains { $0.name == "Rice" })
        #expect(archive.mealPlans.contains { $0.recipeName == "Soup" })
        #expect(archive.badges["explorer"] != nil)
        #expect(archive.cookingTips.contains { $0.title == "Salt early" })
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
        #expect(dest.notes.notes.contains { $0.title == "Note A" })
        #expect(dest.shopping.items.contains { $0.name == "Milk" })
        #expect(dest.kitchen.items.contains { $0.name == "Flour" })
        #expect(dest.kitchen.inventoryItems.contains { $0.name == "Rice" })
        #expect(dest.mealPlans.mealPlans.contains { $0.recipeName == "Soup" })
        #expect(dest.badges.unlockedBadges["explorer"] != nil)
        #expect(dest.cookingTips.tips.contains { $0.title == "Salt early" })
    }

    @Test func restore_isNonDestructive_keepsExistingWork() {
        let source = Self.makeHarness()
        source.notes.addNote(NoteModel(title: "From Backup"))
        let archive = source.service.makeArchive()

        let dest = Self.makeHarness()
        dest.notes.addNote(NoteModel(title: "Local Work"))
        dest.service.restore(archive)

        #expect(dest.notes.notes.contains { $0.title == "Local Work" })
        #expect(dest.notes.notes.contains { $0.title == "From Backup" })
    }

    @Test func restore_preservesNoteDates() {
        let source = Self.makeHarness()
        let created = Date(timeIntervalSince1970: 1_000)
        let modified = Date(timeIntervalSince1970: 2_000)
        source.notes.merge([NoteModel(title: "Dated", createdDate: created, modifiedDate: modified)])
        let archive = source.service.makeArchive()

        let dest = Self.makeHarness()
        dest.service.restore(archive)

        let restored = dest.notes.notes.first { $0.title == "Dated" }
        #expect(restored?.createdDate == created)
        #expect(restored?.modifiedDate == modified)
    }

    // MARK: - Data round-trip

    @Test func exportImport_dataRoundTrip() throws {
        let source = Self.makeHarness()
        Self.seed(source)
        let data = try source.service.exportData()

        let dest = Self.makeHarness()
        try dest.service.importData(data)

        #expect(dest.recipeStore.recipes.contains { $0.name == "Soup" })
        #expect(dest.notes.notes.contains { $0.title == "Note A" })
        #expect(dest.shopping.items.contains { $0.name == "Milk" })
        #expect(dest.mealPlans.mealPlans.contains { $0.recipeName == "Soup" })
    }

    @Test func importData_rejectsGarbage() {
        let dest = Self.makeHarness()
        #expect(throws: BackupError.corruptedData) {
            try dest.service.importData(Data("not a backup".utf8))
        }
    }
}
