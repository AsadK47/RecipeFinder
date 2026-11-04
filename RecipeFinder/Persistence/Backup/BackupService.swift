import Foundation

/// Recipe-store surface `BackupService` needs; a protocol so tests can use an in-memory fake instead of the disk-backed Core Data singleton.
@MainActor
protocol RecipeBackupStore {
    func fetchRecipes() -> [RecipeModel]
    func mergeRecipes(_ incoming: [RecipeModel])
}

extension PersistenceController: RecipeBackupStore {}

/// Assembles a `BackupArchive` from every store and restores one via each store's `merge(_:)` seam; restore is non-destructive (unions by identity, never overwrites/deletes).
@MainActor
struct BackupService {
    private let recipeStore: RecipeBackupStore
    private let shopping: ShoppingListManager
    private let kitchen: KitchenInventoryManager
    private let mealPlans: MealPlanningManager
    private let badges: BadgeManager
    private let collections: CollectionManager

    init(
        recipeStore: RecipeBackupStore = PersistenceController.shared,
        shopping: ShoppingListManager = .shared,
        kitchen: KitchenInventoryManager = .shared,
        mealPlans: MealPlanningManager = .shared,
        badges: BadgeManager = .shared,
        collections: CollectionManager = .shared
    ) {
        self.recipeStore = recipeStore
        self.shopping = shopping
        self.kitchen = kitchen
        self.mealPlans = mealPlans
        self.badges = badges
        self.collections = collections
    }

    /// A complete snapshot of the library.
    func makeArchive() -> BackupArchive {
        BackupArchive(
            recipes: recipeStore.fetchRecipes(),
            shoppingList: shopping.items,
            kitchenItems: kitchen.items,
            kitchenInventory: kitchen.inventoryItems,
            mealPlans: mealPlans.mealPlans,
            badges: badges.unlockedBadges,
            collections: collections.collections
        )
    }

    /// Merge an archive into the current library, non-destructively.
    func restore(_ archive: BackupArchive) {
        recipeStore.mergeRecipes(archive.recipes)
        shopping.merge(archive.shoppingList)
        kitchen.merge(items: archive.kitchenItems, inventory: archive.kitchenInventory)
        mealPlans.merge(archive.mealPlans)
        badges.merge(archive.badges)
        collections.merge(archive.collections)
    }

    // MARK: - File-facing convenience

    /// Encodes the current library to backup-file bytes.
    func exportData() throws -> Data {
        try BackupCodec.encode(makeArchive())
    }

    /// Decodes backup-file bytes (enforcing the schema-version guard) and restores them.
    func importData(_ data: Data) throws {
        restore(try BackupCodec.decode(data))
    }
}
