import Foundation
import Combine

private let logger = AppLogger.logger(category: "ShoppingList")

@MainActor
final class ShoppingListManager: ObservableObject {
    static let shared = ShoppingListManager()
    
    private let saveKey = Constants.UserDefaultsKeys.shoppingListItems
    private let storage: UserScopedStorage
    private let badgeManager: BadgeManager

    @Published private(set) var items: [ShoppingListModel] = []

    private init() {
        self.storage = .shared
        self.badgeManager = .shared
        loadItems()
    }

    init(storage: UserScopedStorage, badgeManager: BadgeManager = .shared) {
        self.storage = storage
        self.badgeManager = badgeManager
        loadItems()
    }
    
    func reloadForCurrentUser() {
        loadItems()
    }
    
    private func loadItems() {
        if let data = storage.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([ShoppingListModel].self, from: data) {
            items = decoded
        } else {
            items = []
        }
    }
    
    func getItems() -> [ShoppingListModel] {
        return items
    }
    
    private func saveItems(_ newItems: [ShoppingListModel]) {
        items = newItems
        if let encoded = try? JSONEncoder().encode(newItems) {
            storage.set(encoded, forKey: saveKey)
        }
    }
    
    /// Faithful, non-destructive restore: unions incoming items by id and persists.
    /// Unlike `addItem`, it doesn't merge by name or re-classify — restored items
    /// keep exactly the identity and fields they had when backed up.
    func merge(_ incoming: [ShoppingListModel]) {
        saveItems(BackupMerge.merged(existing: items, incoming: incoming))
    }

    /// Adds all ingredients from a recipe to the list, merging duplicates by name.
    /// Fractional quantities are rounded to the nearest whole number (minimum 1).
    func addIngredients(from recipe: RecipeModel) {
        for ingredient in recipe.ingredients {
            let qty = max(1, Int(round(ingredient.baseQuantity)))
            addItem(name: ingredient.name, quantity: qty, category: nil)
        }
    }

    /// Adds ingredients from every recipe in the collection, merging duplicates
    /// by name across all recipes (same ingredient appearing in two recipes
    /// accumulates quantity rather than creating a duplicate row).
    func addIngredients(from recipes: [RecipeModel]) {
        for recipe in recipes {
            addIngredients(from: recipe)
        }
    }

    func addItem(name: String, quantity: Int = 1, category: String? = nil) {
        var items = getItems()
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            logger.error("❌ ShoppingListManager: Empty item name")
            return
        }
        
        guard quantity > 0 else {
            logger.error("❌ ShoppingListManager: Invalid quantity for '\(trimmedName)'")
            HapticManager.shared.error()
            return
        }
        
        guard quantity <= 999 else {
            logger.error("❌ ShoppingListManager: Quantity too large for '\(trimmedName)'")
            HapticManager.shared.error()
            return
        }
        
        if let existingIndex = items.firstIndex(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            logger.debug("✅ ShoppingListManager: Updating existing item '\(trimmedName)'")
            let newQuantity = items[existingIndex].quantity + quantity
            items[existingIndex].quantity = min(newQuantity, 999)
            saveItems(items)
            HapticManager.shared.light()
            return
        }
        
        let detectedCategory = category ?? CategoryClassifier.categorize(trimmedName)
        let newItem = ShoppingListModel(name: trimmedName, quantity: quantity, category: detectedCategory)
        items.append(newItem)
        logger.debug("✅ ShoppingListManager: Added '\(trimmedName)' in category '\(detectedCategory)'. Total items: \(items.count)")
        saveItems(items)
        HapticManager.shared.medium()
        badgeManager.unlockBadge(.shoppingExpert)
    }
    
    func updateCategory(at index: Int, category: String) {
        var items = getItems()
        guard index < items.count else { return }
        items[index].category = category
        saveItems(items)
    }
    
    func updateStore(at index: Int, store: String?) {
        var items = getItems()
        guard index < items.count else { return }
        items[index].preferredStore = store
        saveItems(items)
    }
    
    func updateName(at index: Int, name: String) {
        var items = getItems()
        guard index < items.count else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        items[index].name = trimmedName
        saveItems(items)
    }
    
    func toggleItem(at index: Int) {
        var items = getItems()
        guard index < items.count else { return }
        items[index].isChecked.toggle()
        
        if items[index].isChecked {
            HapticManager.shared.success()
        } else {
            HapticManager.shared.light()
        }
        
        saveItems(items)
    }
    
    func updateQuantity(at index: Int, quantity: Int) {
        var items = getItems()
        guard index < items.count else { return }
        guard quantity > 0, quantity <= 999 else { 
            HapticManager.shared.error()
            return 
        }
        items[index].quantity = quantity
        HapticManager.shared.light()
        saveItems(items)
    }
    
    func deleteItem(at index: Int) {
        var items = getItems()
        guard index < items.count else { return }
        items.remove(at: index)
        HapticManager.shared.delete()
        saveItems(items)
    }
    
    func clearCheckedItems() {
        var items = getItems()
        items.removeAll { $0.isChecked }
        HapticManager.shared.celebrate()
        saveItems(items)
    }
    
    func clearAllItems() {
        var items = getItems()
        items.removeAll()
        HapticManager.shared.rigid()
        saveItems(items)
    }
    
    func groupedItems() -> [(category: String, items: [ShoppingListModel])] {
        let items = getItems()
        return Dictionary(grouping: items, by: { $0.category })
            .map { (category: $0.key, items: $0.value) }
            .sorted { $0.category < $1.category }
    }
    
    func uncheckedCount() -> Int {
        getItems().filter { !$0.isChecked }.count
    }
    
    func checkedCount() -> Int {
        getItems().filter { $0.isChecked }.count
    }
}
