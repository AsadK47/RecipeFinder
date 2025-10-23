import Foundation
import Combine

// MARK: - Kitchen Item Model
struct KitchenItem: Identifiable, Codable, Equatable, Hashable {
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

// MARK: - Kitchen Inventory Manager
final class KitchenInventoryManager: ObservableObject {
	@Published private(set) var items: [KitchenItem] = []
    
	private let saveKey = "KitchenItems"
    
	init() {
		loadItems()
	}
    
	// MARK: - Add/Remove Items
	func addItem(name: String, category: String? = nil) {
		let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmedName.isEmpty else { return }
		
		let detectedCategory = category ?? CategoryClassifier.categorize(trimmedName)
		let newItem = KitchenItem(name: trimmedName, category: detectedCategory)
        
		// Don't add duplicates
		guard !items.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) else { return }
        
		items.append(newItem)
		saveItems()
	}
    
	func removeItem(at index: Int) {
		guard index < items.count else { return }
		items.remove(at: index)
		saveItems()
	}
    
	func removeItem(_ item: KitchenItem) {
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
		items.contains { $0.name.lowercased() == name.lowercased() }
	}
    
	func clearAll() {
		items.removeAll()
		saveItems()
	}
    
	// MARK: - Grouped Items
	var groupedItems: [(category: String, items: [KitchenItem])] {
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
		   let decoded = try? JSONDecoder().decode([KitchenItem].self, from: data) {
			items = decoded
		}
	}
}
