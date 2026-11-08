import SwiftUI

private let logger = AppLogger.logger(category: "ShoppingList")

/// Behavioural seam so views depend on this protocol, not the `ShoppingListManager` singleton, and tests can inject a fake.
@MainActor
protocol ShoppingListManaging: AnyObject, Observable {
    var items: [ShoppingListModel] { get }
    /// The user's own stores, in the order they added them.
    var stores: [String] { get }
    func addItem(name: String, quantity: Int, unit: String, category: String?)
    func updateCategory(at index: Int, category: String)
    @discardableResult func addStore(_ name: String) -> Bool
    @discardableResult func renameStore(_ store: String, to newName: String) -> Bool
    func deleteStore(_ store: String)
    func setStore(_ store: String, assigned: Bool, forItemIDs ids: Set<UUID>)
    func updateQuantity(at index: Int, quantity: Int)
    func toggleItem(at index: Int)
    func toggleRecurring(at index: Int)
    func deleteItem(at index: Int)
    func clearCheckedItems()
    func clearAllItems()
}

extension ShoppingListManaging {
    /// Mirrors `addItem`'s default args (a protocol requirement can't carry them) so call sites keep writing `addItem(name:)`.
    func addItem(name: String) { addItem(name: name, quantity: 1, unit: "", category: nil) }
}

private struct ShoppingListManagingKey: EnvironmentKey {
    // SwiftUI reads environment defaults on the main actor, so assuming main-actor isolation is safe.
    static var defaultValue: any ShoppingListManaging {
        MainActor.assumeIsolated { ShoppingListManager.shared }
    }
}

extension EnvironmentValues {
    /// Injected shopping list; defaults to the shared singleton, override with `.environment(\.shopping, fake)` in tests/previews.
    var shopping: any ShoppingListManaging {
        get { self[ShoppingListManagingKey.self] }
        set { self[ShoppingListManagingKey.self] = newValue }
    }
}

@MainActor
@Observable
final class ShoppingListManager: ShoppingListManaging {
    static let shared = ShoppingListManager()

    @ObservationIgnored private let saveKey = Constants.UserDefaultsKeys.shoppingListItems
    @ObservationIgnored private let storesKey = Constants.UserDefaultsKeys.groceryStores
    @ObservationIgnored private let storage: LocalStore
    @ObservationIgnored private let badgeManager: BadgeManager

    private(set) var items: [ShoppingListModel] = []
    private(set) var stores: [String] = []

    private init() {
        self.storage = .shared
        self.badgeManager = .shared
        loadItems()
    }

    init(storage: LocalStore, badgeManager: BadgeManager = .shared) {
        self.storage = storage
        self.badgeManager = badgeManager
        loadItems()
    }
    
    func reload() {
        loadItems()
    }
    
    private func loadItems() {
        if var decoded = storage.decodable([ShoppingListModel].self, forKey: saveKey) {
            // One-time migration: items saved under catalog/legacy category names were split into parallel groups.
            var changed = false
            for index in decoded.indices {
                let normalized = CategoryClassifier.normalizedCategory(decoded[index].category, for: decoded[index].name)
                if normalized != decoded[index].category { decoded[index].category = normalized; changed = true }
            }
            if changed { storage.setEncodable(decoded, forKey: saveKey) }
            items = decoded
        } else {
            items = []
        }
        loadStores()
    }

    /// First run after stores became user-defined: seed the list from tags items already carry, so nothing disappears.
    private func loadStores() {
        if let saved = storage.decodable([String].self, forKey: storesKey) {
            stores = saved
            return
        }
        var seeded: [String] = []
        for store in items.flatMap(\.stores) where !seeded.contains(store) {
            seeded.append(store)
        }
        saveStores(seeded)
    }

    private func saveStores(_ newStores: [String]) {
        stores = newStores
        storage.setEncodable(newStores, forKey: storesKey)
    }
    
    func getItems() -> [ShoppingListModel] {
        return items
    }
    
    private func saveItems(_ newItems: [ShoppingListModel]) {
        items = newItems
        storage.setEncodable(newItems, forKey: saveKey)
    }
    
    /// Non-destructive restore: unions incoming items by id, without the name-merge or re-classify that `addItem` applies.
    func merge(_ incoming: [ShoppingListModel]) {
        saveItems(BackupMerge.merged(existing: items, incoming: incoming))
        // Restored tags must exist as stores, or their filter chips would be missing.
        var merged = stores
        for store in items.flatMap(\.stores) where !merged.contains(store) {
            merged.append(store)
        }
        if merged != stores { saveStores(merged) }
    }

    /// Adds a recipe's ingredients, merging duplicates by name; fractional quantities round to nearest whole (min 1).
    func addIngredients(from recipe: RecipeModel) {
        for ingredient in recipe.ingredients {
            let qty = max(1, Int(round(ingredient.baseQuantity)))
            addItem(name: ingredient.name, quantity: qty, unit: ingredient.unit, category: nil)
        }
    }

    /// Adds ingredients from every recipe, merging duplicates by name across all so shared ingredients accumulate quantity.
    func addIngredients(from recipes: [RecipeModel]) {
        for recipe in recipes {
            addIngredients(from: recipe)
        }
    }

    func addItem(name: String, quantity: Int = 1, unit: String = "", category: String? = nil) {
        var items = getItems()
        let trimmedName = name.trimmed
        let trimmedUnit = unit.trimmed
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
        
        // Merge only when name AND unit match — summing across units ("200 g" + "2 cups") would be meaningless, so differing units stay as separate lines.
        if let existingIndex = items.firstIndex(where: {
            $0.name.nameKey == trimmedName.nameKey
                && UnitConversion.canonicalUnit($0.unit) == UnitConversion.canonicalUnit(trimmedUnit)
        }) {
            logger.debug("✅ ShoppingListManager: Updating existing item '\(trimmedName)'")
            let newQuantity = items[existingIndex].quantity + quantity
            items[existingIndex].quantity = min(newQuantity, 999)
            saveItems(items)
            HapticManager.shared.light()
            return
        }
        
        let detectedCategory = CategoryClassifier.normalizedCategory(category, for: trimmedName)
        let newItem = ShoppingListModel(name: trimmedName, quantity: quantity, unit: trimmedUnit, category: detectedCategory)
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
    
    /// Adds a store; false (nothing saved) when the name is blank or already used.
    @discardableResult
    func addStore(_ name: String) -> Bool {
        guard let valid = GroceryStoreNames.validated(name, existing: stores) else { return false }
        saveStores(stores + [valid])
        return true
    }

    /// Renames a store and every item tagged with it; false (nothing saved) when the new name is blank or taken.
    @discardableResult
    func renameStore(_ store: String, to newName: String) -> Bool {
        guard let index = stores.firstIndex(of: store),
              let valid = GroceryStoreNames.validated(newName, existing: stores.filter { $0 != store }) else { return false }
        var renamed = stores
        renamed[index] = valid
        saveStores(renamed)
        saveItems(items.map { item in
            var updated = item
            updated.stores = item.stores.map { $0 == store ? valid : $0 }
            return updated
        })
        return true
    }

    /// Removes a store; its items stay on the list, untagged from it.
    func deleteStore(_ store: String) {
        saveStores(stores.filter { $0 != store })
        saveItems(items.map { item in
            var updated = item
            updated.stores.removeAll { $0 == store }
            return updated
        })
    }

    /// Tags (or untags) every item in `ids` with `store` in one save.
    func setStore(_ store: String, assigned: Bool, forItemIDs ids: Set<UUID>) {
        saveItems(items.map { item in
            guard ids.contains(item.id) else { return item }
            var updated = item
            updated.stores.removeAll { $0 == store }
            if assigned { updated.stores.append(store) }
            return updated
        })
        HapticManager.shared.selection()
    }
    
    func updateName(at index: Int, name: String) {
        var items = getItems()
        guard index < items.count else { return }
        let trimmedName = name.trimmed
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
        let items = getItems().compactMap { item -> ShoppingListModel? in
            guard item.isChecked else { return item }
            // Staples are unchecked and kept; one-time items are removed.
            if item.isRecurring { var u = item; u.isChecked = false; return u }
            return nil
        }
        HapticManager.shared.celebrate()
        saveItems(items)
    }

    func clearAllItems() {
        // Staples survive a full clear, reset to unchecked.
        let items = getItems().compactMap { item -> ShoppingListModel? in
            guard item.isRecurring else { return nil }
            var u = item; u.isChecked = false; return u
        }
        HapticManager.shared.rigid()
        saveItems(items)
    }

    func toggleRecurring(at index: Int) {
        var items = getItems()
        guard index < items.count else { return }
        items[index].isRecurring.toggle()
        HapticManager.shared.selection()
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
