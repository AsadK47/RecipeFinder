import Combine
import Foundation

// Kitchen Item Model
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

// Kitchen Inventory Manager
final class KitchenInventoryManager: ObservableObject {
	@Published private(set) var items: [KitchenItem] = []
    
	private let saveKey = Constants.UserDefaultsKeys.kitchenItems
	private let migrationKey = "kitchenItemsMigrationCompleted_v1"
    
	init() {
		loadItems()
		migrateOldDataIfNeeded()
	}
	
	// Data Migration - Remove non-USDA items automatically on first app launch after update
	private func migrateOldDataIfNeeded() {
		guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }
		
		// Get all valid USDA foods
		let validFoods = Set(FoodsList.getAllFoods().map { $0.lowercased() })
		
		// Filter out items that don't match USDA foods
		let oldCount = items.count
		items = items.filter { validFoods.contains($0.name.lowercased()) }
		
		let removedCount = oldCount - items.count
		if removedCount > 0 {
			print("🔄 Kitchen Migration: Removed \(removedCount) non-USDA items")
			saveItems()
		}
		
		// Mark migration as complete
		UserDefaults.standard.set(true, forKey: migrationKey)
	}
    
	// Add/Remove Items
	func addItem(name: String, category: String? = nil) {
		let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmedName.isEmpty else { return }
		
		let detectedCategory = category ?? CategoryClassifier.categorize(trimmedName)
		let newItem = KitchenItem(name: trimmedName, category: detectedCategory)
        
		// Don't add duplicates
		guard !items.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) else {
			HapticManager.shared.warning()
			return
		}
        
		items.append(newItem)
		HapticManager.shared.medium()
		saveItems()
	}
    
	func removeItem(at index: Int) {
		guard index < items.count else { return }
		items.remove(at: index)
		HapticManager.shared.light()
		saveItems()
	}
    
	func removeItem(_ item: KitchenItem) {
		items.removeAll { $0.id == item.id }
		HapticManager.shared.light()
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
		HapticManager.shared.rigid()
		saveItems()
	}
    
	// Grouped Items
	var groupedItems: [(category: String, items: [KitchenItem])] {
		let categories = Set(items.map { $0.category }).sorted()
        
		return categories.compactMap { category in
			let categoryItems = items.filter { $0.category == category }
			return categoryItems.isEmpty ? nil : (category, categoryItems)
		}
	}
    
	// Persistence
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
