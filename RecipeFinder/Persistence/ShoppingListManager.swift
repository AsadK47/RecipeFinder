import Foundation

class ShoppingListManager: ObservableObject {
    @Published var items: [ShoppingListItem] = []
    
    private let saveKey = "ShoppingListItems"
    
    init() {
        loadItems()
    }
    
    func loadItems() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([ShoppingListItem].self, from: data) {
            items = decoded
        }
    }
    
    func saveItems() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    func addItem(name: String, quantity: Int = 1, category: String? = nil) {
        let detectedCategory = category ?? CategoryClassifier.categorize(name)
        let newItem = ShoppingListItem(name: name, quantity: quantity, category: detectedCategory)
        items.append(newItem)
        saveItems()
    }
    
    func updateCategory(at index: Int, category: String) {
        guard index < items.count else { return }
        items[index].category = category
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
        let categories = ["Produce", "Meat & Seafood", "Dairy & Eggs", "Bakery", "Pantry", "Frozen", "Beverages", "Spices & Seasonings", "Other"]
        
        return categories.compactMap { category in
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
