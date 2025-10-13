import Foundation
import Combine

// MARK: - Pantry Item Model
struct PantryItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var category: String
    var dateAdded: Date
    
    init(id: UUID = UUID(), name: String, category: String, dateAdded: Date = Date()) {
        self.id = id
        self.name = name
        self.category = category
        self.dateAdded = dateAdded
    }
}

// MARK: - Pantry Manager
class PantryManager: ObservableObject {
    @Published var items: [PantryItem] = []
    
    private let saveKey = "PantryItems"
    
    init() {
        loadItems()
    }
    
    // MARK: - Add/Remove Items
    func addItem(name: String, category: String? = nil) {
        let detectedCategory = category ?? CategoryClassifier.categorize(name)
        let newItem = PantryItem(name: name, category: detectedCategory)
        
        // Don't add duplicates
        guard !items.contains(where: { $0.name.lowercased() == name.lowercased() }) else { return }
        
        items.append(newItem)
        saveItems()
    }
    
    func removeItem(at index: Int) {
        guard index < items.count else { return }
        items.remove(at: index)
        saveItems()
    }
    
    func removeItem(_ item: PantryItem) {
        items.removeAll { $0.id == item.id }
        saveItems()
    }
    
    func toggleItem(_ name: String, category: String? = nil) {
        if let index = items.firstIndex(where: { $0.name.lowercased() == name.lowercased() }) {
            removeItem(at: index)
        } else {
            addItem(name: name, category: category)
        }
    }
    
    func hasItem(_ name: String) -> Bool {
        return items.contains { $0.name.lowercased() == name.lowercased() }
    }
    
    func clearAll() {
        items.removeAll()
        saveItems()
    }
    
    // MARK: - Grouped Items
    var groupedItems: [(category: String, items: [PantryItem])] {
        let categories = Set(items.map { $0.category }).sorted()
        
        return categories.compactMap { category in
            let categoryItems = items.filter { $0.category == category }
            return categoryItems.isEmpty ? nil : (category, categoryItems)
        }
    }
    
    // MARK: - Persistence
    private func saveItems() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadItems() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([PantryItem].self, from: data) {
            items = decoded
        }
    }
}
