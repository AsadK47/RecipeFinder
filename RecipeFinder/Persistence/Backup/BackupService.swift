import Foundation

/// The recipe-store surface `BackupService` needs. Kept as a protocol so the
/// service can be exercised with an in-memory fake instead of the real Core Data
/// stack (which is a disk-backed singleton). `PersistenceController` conforms.
@MainActor
protocol RecipeBackupStore {
    func fetchRecipes() -> [RecipeModel]
    func mergeRecipes(_ incoming: [RecipeModel])
}

extension PersistenceController: RecipeBackupStore {}

/// Assembles a full `BackupArchive` from every store and restores one back into
/// the current user's library. Reading and restoring both go through the stores'
/// public surface (getters + the faithful `merge(_:)` seam) so encoding/keys stay
/// encapsulated and the UI's `@Published` state refreshes on restore.
///
/// Restore is non-destructive: `merge` unions by identity, so importing a backup
/// never overwrites or deletes the work already on the device.
@MainActor
struct BackupService {
    private let recipeStore: RecipeBackupStore
    private let notes: NotesManager
    private let shopping: ShoppingListManager
    private let kitchen: KitchenInventoryManager
    private let mealPlans: MealPlanningManager
    private let badges: BadgeManager
    private let cookingTips: CookingTipsManager

    init(
        recipeStore: RecipeBackupStore = PersistenceController.shared,
        notes: NotesManager = .shared,
        shopping: ShoppingListManager = .shared,
        kitchen: KitchenInventoryManager = .shared,
        mealPlans: MealPlanningManager = .shared,
        badges: BadgeManager = .shared,
        cookingTips: CookingTipsManager = .shared
    ) {
        self.recipeStore = recipeStore
        self.notes = notes
        self.shopping = shopping
        self.kitchen = kitchen
        self.mealPlans = mealPlans
        self.badges = badges
        self.cookingTips = cookingTips
    }

    /// A complete snapshot of the current user's library.
    func makeArchive() -> BackupArchive {
        BackupArchive(
            recipes: recipeStore.fetchRecipes(),
            notes: notes.notes,
            shoppingList: shopping.items,
            kitchenItems: kitchen.items,
            kitchenInventory: kitchen.inventoryItems,
            mealPlans: mealPlans.mealPlans,
            badges: badges.unlockedBadges,
            cookingTips: cookingTips.tips
        )
    }

    /// Merge an archive into the current library, non-destructively.
    func restore(_ archive: BackupArchive) {
        recipeStore.mergeRecipes(archive.recipes)
        notes.merge(archive.notes)
        shopping.merge(archive.shoppingList)
        kitchen.merge(items: archive.kitchenItems, inventory: archive.kitchenInventory)
        mealPlans.merge(archive.mealPlans)
        badges.merge(archive.badges)
        cookingTips.merge(archive.cookingTips)
    }

    // MARK: - File-facing convenience

    /// Encodes the current library to backup-file bytes.
    func exportData() throws -> Data {
        try BackupCodec.encode(makeArchive())
    }

    /// Decodes backup-file bytes (enforcing the schema-version guard) and restores
    /// them into the current library.
    func importData(_ data: Data) throws {
        restore(try BackupCodec.decode(data))
    }
}
