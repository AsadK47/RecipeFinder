import Foundation
import Combine

final class ShoppingListManager: ObservableObject {
    nonisolated(unsafe) static let shared = ShoppingListManager()
    
    private let saveKey = Constants.UserDefaultsKeys.shoppingListItems
    
    // PERFORMANCE: Cache items in memory and only read from UserDefaults once
    @Published private(set) var items: [ShoppingListModel] = []
    
    private init() {
        loadItems()
    }
    
    private func loadItems() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
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
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    func addItem(name: String, quantity: Int = 1, category: String? = nil) {
        var items = getItems()
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            print("❌ ShoppingListManager: Empty item name")
            return
        }
        
        // Validate quantity
        guard quantity > 0 else {
            print("❌ ShoppingListManager: Invalid quantity for '\(trimmedName)'")
            debugLog("⚠️ Invalid quantity for item '\(trimmedName)'. Must be greater than 0.")
            HapticManager.shared.error()
            return
        }
        
        // Check for duplicates - if exists, just increase quantity
        if let existingIndex = items.firstIndex(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            print("✅ ShoppingListManager: Updating existing item '\(trimmedName)'")
            items[existingIndex].quantity += quantity
            saveItems(items)
            HapticManager.shared.light()
            return
        }
        
        let detectedCategory = category ?? CategoryClassifier.categorize(trimmedName)
        let newItem = ShoppingListModel(name: trimmedName, quantity: quantity, category: detectedCategory)
        items.append(newItem)
        print("✅ ShoppingListManager: Added '\(trimmedName)' in category '\(detectedCategory)'. Total items: \(items.count)")
        saveItems(items)
        HapticManager.shared.medium()
    }
    
    func updateCategory(at index: Int, category: String) {
        var items = getItems()
        guard index < items.count else { return }
        items[index].category = category
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
        
        // Celebratory haptic when checking off, soft when unchecking
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
        guard quantity > 0 else { return }
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
