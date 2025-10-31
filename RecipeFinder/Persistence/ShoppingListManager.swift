import Foundation

final class ShoppingListManager: ObservableObject {
    @Published var items: [ShoppingListItem] = []
    
    private let saveKey = Constants.UserDefaultsKeys.shoppingListItems
    
    init() {
        loadItems()
    }
    
    private func loadItems() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([ShoppingListItem].self, from: data) {
            items = decoded
        }
    }
    
    private func saveItems() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    func addItem(name: String, quantity: Int = 1, category: String? = nil) {
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
            saveItems()
            HapticManager.shared.light()
            return
        }
        
        let detectedCategory = category ?? CategoryClassifier.categorize(trimmedName)
        let newItem = ShoppingListItem(name: trimmedName, quantity: quantity, category: detectedCategory)
        items.append(newItem)
        print("✅ ShoppingListManager: Added '\(trimmedName)' in category '\(detectedCategory)'. Total items: \(items.count)")
        saveItems()
        HapticManager.shared.medium()
    }
    
    func updateCategory(at index: Int, category: String) {
        guard index < items.count else { return }
        items[index].category = category
        saveItems()
    }
    
    func updateName(at index: Int, name: String) {
        guard index < items.count else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        items[index].name = trimmedName
        saveItems()
    }
    
    func toggleItem(at index: Int) {
        guard index < items.count else { return }
        items[index].isChecked.toggle()
        
        // Celebratory haptic when checking off, soft when unchecking
        if items[index].isChecked {
            HapticManager.shared.success()
        } else {
            HapticManager.shared.light()
        }
        
        saveItems()
    }
    
    func updateQuantity(at index: Int, quantity: Int) {
        guard index < items.count else { return }
        guard quantity > 0 else { return }
        items[index].quantity = quantity
        HapticManager.shared.light()
        saveItems()
    }
    
    func deleteItem(at index: Int) {
        guard index < items.count else { return }
        items.remove(at: index)
        HapticManager.shared.delete()
        saveItems()
    }
    
    func clearCheckedItems() {
        items.removeAll { $0.isChecked }
        HapticManager.shared.celebrate()
        saveItems()
    }
    
    func clearAllItems() {
        items.removeAll()
        HapticManager.shared.rigid()
        saveItems()
    }
    
    var groupedItems: [(category: String, items: [ShoppingListItem])] {
        return CategoryClassifier.categoryOrder.compactMap { category in
            let categoryItems = items.filter { $0.category == category }
            return categoryItems.isEmpty ? nil : (category, categoryItems)
        }
    }
    
    var uncheckedCount: Int {
        items.filter { !$0.isChecked }.count
    }
    
    var checkedCount: Int {
        items.filter { $0.isChecked }.count
    }
}
