import Foundation

final class ShoppingListManager: ObservableObject {
    @Published private(set) var items: [ShoppingListItem] = []
    
    private let saveKey = "ShoppingListItems"
    
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
        guard !trimmedName.isEmpty else { return }
        
        let detectedCategory = category ?? CategoryClassifier.categorize(trimmedName)
        let newItem = ShoppingListItem(name: trimmedName, quantity: quantity, category: detectedCategory)
        items.append(newItem)
        saveItems()
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
        saveItems()
    }
    
    func updateQuantity(at index: Int, quantity: Int) {
        guard index < items.count else { return }
        items[index].quantity = quantity
        saveItems()
    }
    
    func deleteItem(at index: Int) {
        guard index < items.count else { return }
        items.remove(at: index)
        saveItems()
    }
    
    func clearCheckedItems() {
        items.removeAll { $0.isChecked }
        saveItems()
    }
    
    func clearAllItems() {
        items.removeAll()
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
