import Foundation

// MARK: - Kitchen Inventory Manager

final class KitchenInventoryManager: ObservableObject {
	nonisolated(unsafe) static let shared = KitchenInventoryManager()
    
	private let saveKey = Constants.UserDefaultsKeys.kitchenItems
	private let inventorySaveKey = "kitchenInventoryItems"
	private let migrationKey = "kitchenItemsMigrationCompleted_v1"
    
	private init() {
		migrateOldDataIfNeeded()
	}
	
	// MARK: - Getters
	
	func getItems() -> [KitchenItem] {
		if let data = UserDefaults.standard.data(forKey: saveKey),
		   let decoded = try? JSONDecoder().decode([KitchenItem].self, from: data) {
			return decoded
		}
		return []
	}
	
	func getInventoryItems() -> [KitchenInventoryModel] {
		if let data = UserDefaults.standard.data(forKey: inventorySaveKey),
		   let decoded = try? JSONDecoder().decode([KitchenInventoryModel].self, from: data) {
			return decoded
		}
		return []
	}
	
	// MARK: - Full Inventory Item Management (New Model)
	
	func addInventoryItem(_ item: KitchenInventoryModel) {
		var inventoryItems = getInventoryItems()
		// Don't add duplicates by name
		guard !inventoryItems.contains(where: { $0.name.lowercased() == item.name.lowercased() }) else {
			HapticManager.shared.warning()
			return
		}
		
		inventoryItems.append(item)
		HapticManager.shared.medium()
		saveInventoryItems(inventoryItems)
	}
	
	func updateInventoryItem(_ item: KitchenInventoryModel) {
		var inventoryItems = getInventoryItems()
		if let index = inventoryItems.firstIndex(where: { $0.id == item.id }) {
			inventoryItems[index] = item
			HapticManager.shared.light()
			saveInventoryItems(inventoryItems)
		}
	}
	
	func removeInventoryItem(_ item: KitchenInventoryModel) {
		var inventoryItems = getInventoryItems()
		inventoryItems.removeAll { $0.id == item.id }
		HapticManager.shared.light()
		saveInventoryItems(inventoryItems)
	}
	
	func hasInventoryItem(_ name: String) -> Bool {
		getInventoryItems().contains { $0.name.lowercased() == name.lowercased() }
	}
	
	// Computed properties for filtering
	func expiredItems() -> [KitchenInventoryModel] {
		getInventoryItems().filter { $0.isExpired }
	}
	
	func expiringSoonItems() -> [KitchenInventoryModel] {
		getInventoryItems().filter { $0.isExpiringSoon }
	}
	
	func lowStockItems() -> [KitchenInventoryModel] {
		getInventoryItems().filter { $0.needsRestock }
	}
	
	func itemsByCategory() -> [(category: IngredientCategory, items: [KitchenInventoryModel])] {
		let inventoryItems = getInventoryItems()
		let categories = IngredientCategory.allCases
		return categories.compactMap { category in
			let categoryItems = inventoryItems.filter { $0.category == category }
			return categoryItems.isEmpty ? nil : (category, categoryItems)
		}
	}
	
	func itemsByStorageLocation() -> [(location: StorageLocation, items: [KitchenInventoryModel])] {
		let inventoryItems = getInventoryItems()
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
		
		var items = getItems()
		// Get all valid food items
		let validFoods = Set(FoodsList.getAllFoods().map { $0.lowercased() })
		
		// Filter out items that don't match food items
		let oldCount = items.count
		items = items.filter { validFoods.contains($0.name.lowercased()) }
		
		let removedCount = oldCount - items.count
		if removedCount > 0 {
			print("🔄 Kitchen Migration: Removed \(removedCount) non-food items")
			saveItems(items)
		}
		
		// Mark migration as complete
		UserDefaults.standard.set(true, forKey: migrationKey)
	}
    
	// Add/Remove Items
	func addItem(name: String, category: String? = nil) {
		var items = getItems()
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
		saveItems(items)
	}
    
	func removeItem(at index: Int) {
		var items = getItems()
		guard index < items.count else { return }
		items.remove(at: index)
		HapticManager.shared.light()
		saveItems(items)
	}
    
	func removeItem(_ item: KitchenItem) {
		var items = getItems()
		items.removeAll { $0.id == item.id }
		HapticManager.shared.light()
		saveItems(items)
	}
    
	func toggleItem(_ name: String, category: String? = nil) {
		var items = getItems()
		if let index = items.firstIndex(where: { $0.name.lowercased() == name.lowercased() }) {
			items.remove(at: index)
			HapticManager.shared.light()
			saveItems(items)
		} else {
			addItem(name: name, category: category)
		}
	}
    
	func hasItem(_ name: String) -> Bool {
		getItems().contains { $0.name.lowercased() == name.lowercased() }
	}
    
	func clearAll() {
		var items = getItems()
		items.removeAll()
		HapticManager.shared.rigid()
		saveItems(items)
	}
    
	// Grouped Items
	func groupedItems() -> [(category: String, items: [KitchenItem])] {
		let items = getItems()
		let categories = Set(items.map { $0.category }).sorted()
        
		return categories.compactMap { category in
			let categoryItems = items.filter { $0.category == category }
			return categoryItems.isEmpty ? nil : (category, categoryItems)
		}
	}
    
	// Persistence
	private func saveItems(_ items: [KitchenItem]) {
		if let encoded = try? JSONEncoder().encode(items) {
			UserDefaults.standard.set(encoded, forKey: saveKey)
		}
	}
	
	private func saveInventoryItems(_ inventoryItems: [KitchenInventoryModel]) {
		if let encoded = try? JSONEncoder().encode(inventoryItems) {
			UserDefaults.standard.set(encoded, forKey: inventorySaveKey)
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
