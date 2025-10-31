import Combine
import Foundation

// MARK: - Kitchen Inventory Manager
// Uses the KitchenInventoryItemModel for full inventory tracking with expiration dates

final class KitchenInventoryManager: ObservableObject {
	@Published private(set) var items: [KitchenItem] = []
	@Published private(set) var inventoryItems: [KitchenInventoryItemModel] = []
    
	private let saveKey = Constants.UserDefaultsKeys.kitchenItems
	private let inventorySaveKey = "kitchenInventoryItems"
	private let migrationKey = "kitchenItemsMigrationCompleted_v1"
    
	init() {
		loadItems()
		loadInventoryItems()
		migrateOldDataIfNeeded()
	}
	
	// MARK: - Full Inventory Item Management (New Model)
	
	func addInventoryItem(_ item: KitchenInventoryItemModel) {
		// Don't add duplicates by name
		guard !inventoryItems.contains(where: { $0.name.lowercased() == item.name.lowercased() }) else {
			HapticManager.shared.warning()
			return
		}
		
		inventoryItems.append(item)
		HapticManager.shared.medium()
		saveInventoryItems()
	}
	
	func updateInventoryItem(_ item: KitchenInventoryItemModel) {
		if let index = inventoryItems.firstIndex(where: { $0.id == item.id }) {
			inventoryItems[index] = item
			HapticManager.shared.light()
			saveInventoryItems()
		}
	}
	
	func removeInventoryItem(_ item: KitchenInventoryItemModel) {
		inventoryItems.removeAll { $0.id == item.id }
		HapticManager.shared.light()
		saveInventoryItems()
	}
	
	func hasInventoryItem(_ name: String) -> Bool {
		inventoryItems.contains { $0.name.lowercased() == name.lowercased() }
	}
	
	// Computed properties for filtering
	var expiredItems: [KitchenInventoryItemModel] {
		inventoryItems.filter { $0.isExpired }
	}
	
	var expiringSoonItems: [KitchenInventoryItemModel] {
		inventoryItems.filter { $0.isExpiringSoon }
	}
	
	var lowStockItems: [KitchenInventoryItemModel] {
		inventoryItems.filter { $0.needsRestock }
	}
	
	var itemsByCategory: [(category: IngredientCategory, items: [KitchenInventoryItemModel])] {
		let categories = IngredientCategory.allCases
		return categories.compactMap { category in
			let categoryItems = inventoryItems.filter { $0.category == category }
			return categoryItems.isEmpty ? nil : (category, categoryItems)
		}
	}
	
	var itemsByStorageLocation: [(location: StorageLocation, items: [KitchenInventoryItemModel])] {
		let locations = StorageLocation.allCases
		return locations.compactMap { location in
			let locationItems = inventoryItems.filter { $0.storageLocation == location }
			return locationItems.isEmpty ? nil : (location, locationItems)
		}
	}
	
	// MARK: - Simple Kitchen Items (Legacy - for backward compatibility)
	
	// Data Migration - Remove food items automatically on first app launch after update
	private func migrateOldDataIfNeeded() {
		guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }
		
		// Get all valid food items
		let validFoods = Set(FoodsList.getAllFoods().map { $0.lowercased() })
		
		// Filter out items that don't match food items
		let oldCount = items.count
		items = items.filter { validFoods.contains($0.name.lowercased()) }
		
		let removedCount = oldCount - items.count
		if removedCount > 0 {
			print("🔄 Kitchen Migration: Removed \(removedCount) non-food items")
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
	
	private func saveInventoryItems() {
		if let encoded = try? JSONEncoder().encode(inventoryItems) {
			UserDefaults.standard.set(encoded, forKey: inventorySaveKey)
		}
	}
	
	private func loadInventoryItems() {
		if let data = UserDefaults.standard.data(forKey: inventorySaveKey),
		   let decoded = try? JSONDecoder().decode([KitchenInventoryItemModel].self, from: data) {
			inventoryItems = decoded
		}
	}
}

// MARK: - Legacy Kitchen Item Model (for backward compatibility)

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
