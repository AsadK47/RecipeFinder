import Foundation

// MARK: - Kitchen Inventory Manager

final class KitchenInventoryManager: ObservableObject {
	nonisolated(unsafe) static let shared = KitchenInventoryManager()
    
	private let saveKey = Constants.UserDefaultsKeys.kitchenItems
	private let inventorySaveKey = "kitchenInventoryItems"
	private let migrationKey = "kitchenItemsMigrationCompleted_v1"
    
    // Cache items in memory for performance
    @Published private(set) var items: [KitchenItem] = []
    @Published private(set) var inventoryItems: [KitchenInventoryModel] = []
    
	private init() {
		migrateOldDataIfNeeded()
        loadItems()
        loadInventoryItems()
	}
    
    // MARK: - Loading
    
    private func loadItems() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([KitchenItem].self, from: data) {
            items = decoded
        }
    }
    
    private func loadInventoryItems() {
        if let data = UserDefaults.standard.data(forKey: inventorySaveKey),
           let decoded = try? JSONDecoder().decode([KitchenInventoryModel].self, from: data) {
            inventoryItems = decoded
        }
    }
	
	// MARK: - Getters (Deprecated - use @Published properties instead)
	
	func getItems() -> [KitchenItem] {
		return items
	}
	
	func getInventoryItems() -> [KitchenInventoryModel] {
		return inventoryItems
	}
	
	// MARK: - Full Inventory Item Management (New Model)
	
	func addInventoryItem(_ item: KitchenInventoryModel) {
		// Don't add duplicates by name
		guard !inventoryItems.contains(where: { $0.name.lowercased() == item.name.lowercased() }) else {
			HapticManager.shared.warning()
			debugLog("⚠️ Duplicate item '\(item.name)' not added")
			return
		}
		
		// Validate expiry date is not in the past (allow same-day)
		if let expiryDate = item.expiryDate {
			let calendar = Calendar.current
			if calendar.startOfDay(for: expiryDate) < calendar.startOfDay(for: Date()) {
				debugLog("⚠️ Cannot add item '\(item.name)' with past expiry date")
				HapticManager.shared.error()
				return
			}
		}
		
		// Validate quantity is positive
		guard item.quantity > 0 else {
			debugLog("⚠️ Cannot add item '\(item.name)' with zero or negative quantity")
			HapticManager.shared.error()
			return
		}
		
		var updatedItems = inventoryItems
		updatedItems.append(item)
		HapticManager.shared.medium()
		saveInventoryItems(updatedItems)
		debugLog("✅ Added inventory item: '\(item.name)'")
	}
	
	func updateInventoryItem(_ item: KitchenInventoryModel) {
		// Validate expiry date is not in the past
		if let expiryDate = item.expiryDate {
			let calendar = Calendar.current
			if calendar.startOfDay(for: expiryDate) < calendar.startOfDay(for: Date()) {
				debugLog("⚠️ Cannot update item '\(item.name)' with past expiry date")
				HapticManager.shared.error()
				return
			}
		}
		
		// Validate quantity is positive
		guard item.quantity > 0 else {
			debugLog("⚠️ Cannot update item '\(item.name)' with zero or negative quantity")
			HapticManager.shared.error()
			return
		}
		
		var updatedItems = inventoryItems
		if let index = updatedItems.firstIndex(where: { $0.id == item.id }) {
			updatedItems[index] = item
			HapticManager.shared.light()
			saveInventoryItems(updatedItems)
			debugLog("✅ Updated inventory item: '\(item.name)'")
		}
	}
	
	func removeInventoryItem(_ item: KitchenInventoryModel) {
		var updatedItems = inventoryItems
		updatedItems.removeAll { $0.id == item.id }
		HapticManager.shared.light()
		saveInventoryItems(updatedItems)
	}
	
	func hasInventoryItem(_ name: String) -> Bool {
		inventoryItems.contains { $0.name.lowercased() == name.lowercased() }
	}
	
	// Computed properties for filtering
	func expiredItems() -> [KitchenInventoryModel] {
		inventoryItems.filter { $0.isExpired }
	}
	
	func expiringSoonItems() -> [KitchenInventoryModel] {
		inventoryItems.filter { $0.isExpiringSoon }
	}
	
	func lowStockItems() -> [KitchenInventoryModel] {
		inventoryItems.filter { $0.needsRestock }
	}
	
	func itemsByCategory() -> [(category: IngredientCategory, items: [KitchenInventoryModel])] {
		let categories = IngredientCategory.allCases
		return categories.compactMap { category in
			let categoryItems = inventoryItems.filter { $0.category == category }
			return categoryItems.isEmpty ? nil : (category, categoryItems)
		}
	}
	
	func itemsByStorageLocation() -> [(location: StorageLocation, items: [KitchenInventoryModel])] {
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
		let filteredItems = items.filter { item in
			validFoods.contains(item.name.lowercased())
		}
		
		let removedCount = oldCount - filteredItems.count
		if removedCount > 0 {
			print("🔄 Kitchen Migration: Removed \(removedCount) non-food items")
			saveItems(filteredItems)
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
        
		var updatedItems = items
		updatedItems.append(newItem)
		HapticManager.shared.medium()
		saveItems(updatedItems)
	}
    
	func removeItem(at index: Int) {
		guard index < items.count else { return }
		var updatedItems = items
		updatedItems.remove(at: index)
		HapticManager.shared.light()
		saveItems(updatedItems)
	}
    
	func removeItem(_ item: KitchenItem) {
		var updatedItems = items
		updatedItems.removeAll { $0.id == item.id }
		HapticManager.shared.light()
		saveItems(updatedItems)
	}
    
	func toggleItem(_ name: String, category: String? = nil) {
		if let index = items.firstIndex(where: { $0.name.lowercased() == name.lowercased() }) {
			var updatedItems = items
			updatedItems.remove(at: index)
			HapticManager.shared.light()
			saveItems(updatedItems)
		} else {
			addItem(name: name, category: category)
		}
	}
    
	func hasItem(_ name: String) -> Bool {
		items.contains { $0.name.lowercased() == name.lowercased() }
	}
    
	func clearAll() {
		HapticManager.shared.rigid()
		saveItems([])
	}
    
	// Grouped Items
	func groupedItems() -> [(category: String, items: [KitchenItem])] {
		let categories = Set(items.map { $0.category }).sorted()
        
		return categories.compactMap { category in
			let categoryItems = items.filter { $0.category == category }
			return categoryItems.isEmpty ? nil : (category, categoryItems)
		}
	}
    
	// Persistence
	private func saveItems(_ newItems: [KitchenItem]) {
		if let encoded = try? JSONEncoder().encode(newItems) {
			UserDefaults.standard.set(encoded, forKey: saveKey)
            items = newItems // Update cache
		}
	}
	
	private func saveInventoryItems(_ newInventoryItems: [KitchenInventoryModel]) {
		if let encoded = try? JSONEncoder().encode(newInventoryItems) {
			UserDefaults.standard.set(encoded, forKey: inventorySaveKey)
            inventoryItems = newInventoryItems // Update cache
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
