import SwiftUI

private let logger = AppLogger.logger(category: "ShoppingList")

/// Behavioural seam so views depend on this protocol, not the `ShoppingListManager` singleton, and tests can inject a fake.
@MainActor
protocol ShoppingListManaging: AnyObject, Observable {
    var items: [ShoppingListModel] { get }
    func addItem(name: String, quantity: Int, unit: String, category: String?)
    func updateCategory(at index: Int, category: String)
    func updateStore(at index: Int, store: String?)
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
    @ObservationIgnored private let storage: LocalStore
    @ObservationIgnored private let badgeManager: BadgeManager

    private(set) var items: [ShoppingListModel] = []

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
        storage.setEncodable(newItems, forKey: saveKey)
    }
    
    /// Non-destructive restore: unions incoming items by id, without the name-merge or re-classify that `addItem` applies.
    func merge(_ incoming: [ShoppingListModel]) {
        saveItems(BackupMerge.merged(existing: items, incoming: incoming))
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
            $0.name.lowercased() == trimmedName.lowercased()
                && $0.unit.lowercased() == trimmedUnit.lowercased()
        }) {
            logger.debug("✅ ShoppingListManager: Updating existing item '\(trimmedName)'")
            let newQuantity = items[existingIndex].quantity + quantity
            items[existingIndex].quantity = min(newQuantity, 999)
            saveItems(items)
            HapticManager.shared.light()
            return
        }
        
        let detectedCategory = category ?? CategoryClassifier.categorize(trimmedName)
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
    
    func updateStore(at index: Int, store: String?) {
        var items = getItems()
        guard index < items.count else { return }
        items[index].preferredStore = store
        saveItems(items)
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
