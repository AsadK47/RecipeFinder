import Foundation

private let logger = AppLogger.logger(category: "KitchenInventory")

@MainActor
final class KitchenInventoryManager: ObservableObject {
	static let shared = KitchenInventoryManager()
    
	private let saveKey = Constants.UserDefaultsKeys.kitchenItems
	private let inventorySaveKey = "kitchenInventoryItems"
	private let migrationKey = "kitchenItemsMigrationCompleted_v1"
    private let storage: UserScopedStorage

    @Published private(set) var items: [KitchenItem] = []
    @Published private(set) var inventoryItems: [KitchenInventoryModel] = []
    // O(1) name lookup — kept in sync with items on every save/load
    private var itemNameSet: Set<String> = []

	private init() {
        self.storage = .shared
		migrateOldDataIfNeeded()
        loadItems()
        loadInventoryItems()
	}

    init(storage: UserScopedStorage) {
        self.storage = storage
        loadItems()
        loadInventoryItems()
    }
    
    func reloadForCurrentUser() {
        loadItems()
        loadInventoryItems()
    }

    private func loadItems() {
        if let data = storage.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([KitchenItem].self, from: data) {
            items = decoded
            itemNameSet = Set(decoded.map { $0.name.lowercased() })
        } else {
            items = []
            itemNameSet = []
        }
    }
    
    private func loadInventoryItems() {
        if let data = storage.data(forKey: inventorySaveKey),
           let decoded = try? JSONDecoder().decode([KitchenInventoryModel].self, from: data) {
            inventoryItems = decoded
        } else {
            inventoryItems = []
        }
    }
	
	func getItems() -> [KitchenItem] {
		return items
	}
	
	func getInventoryItems() -> [KitchenInventoryModel] {
		return inventoryItems
	}
	
	func addInventoryItem(_ item: KitchenInventoryModel) {
		guard !inventoryItems.contains(where: { $0.name.lowercased() == item.name.lowercased() }) else {
			HapticManager.shared.warning()
			logger.debug("⚠️ Duplicate item '\(item.name)' not added")
			return
		}
		
		if let expiryDate = item.expiryDate {
			let calendar = Calendar.current
			if calendar.startOfDay(for: expiryDate) < calendar.startOfDay(for: Date()) {
				logger.debug("⚠️ Cannot add item '\(item.name)' with past expiry date")
				HapticManager.shared.error()
				return
			}
		}
		
		guard item.quantity > 0 else {
			logger.debug("⚠️ Cannot add item '\(item.name)' with zero or negative quantity")
			HapticManager.shared.error()
			return
		}
		
		var updatedItems = inventoryItems
		updatedItems.append(item)
		HapticManager.shared.medium()
		saveInventoryItems(updatedItems)
		logger.debug("✅ Added inventory item: '\(item.name)'")
	}
	
	func updateInventoryItem(_ item: KitchenInventoryModel) {
		if let expiryDate = item.expiryDate {
			let calendar = Calendar.current
			if calendar.startOfDay(for: expiryDate) < calendar.startOfDay(for: Date()) {
				logger.debug("⚠️ Cannot update item '\(item.name)' with past expiry date")
				HapticManager.shared.error()
				return
			}
		}
		
		guard item.quantity > 0 else {
			logger.debug("⚠️ Cannot update item '\(item.name)' with zero or negative quantity")
			HapticManager.shared.error()
			return
		}
		
		var updatedItems = inventoryItems
		if let index = updatedItems.firstIndex(where: { $0.id == item.id }) {
			updatedItems[index] = item
			HapticManager.shared.light()
			saveInventoryItems(updatedItems)
			logger.debug("✅ Updated inventory item: '\(item.name)'")
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
	
	private func migrateOldDataIfNeeded() {
		guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }
		
		let validFoods = Set(FoodsList.getAllFoods().map { $0.lowercased() })
		
		let oldCount = items.count
		let filteredItems = items.filter { item in
			validFoods.contains(item.name.lowercased())
		}
		
		let removedCount = oldCount - filteredItems.count
		if removedCount > 0 {
			logger.debug("🔄 Kitchen Migration: Removed \(removedCount) non-food items")
			saveItems(filteredItems)
		}
		
		UserDefaults.standard.set(true, forKey: migrationKey)
	}
    
	func addItem(name: String, category: String? = nil) {
		let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmedName.isEmpty else { return }
		
		let detectedCategory = category ?? CategoryClassifier.categorize(trimmedName)
		let newItem = KitchenItem(name: trimmedName, category: detectedCategory)
        
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
		itemNameSet.contains(name.lowercased())
	}
    
	func clearAll() {
		HapticManager.shared.rigid()
		saveItems([])
	}
    
	func groupedItems() -> [(category: String, items: [KitchenItem])] {
		let grouped = Dictionary(grouping: items) { $0.category }
		return grouped.keys.sorted().compactMap { category in
			guard let categoryItems = grouped[category], !categoryItems.isEmpty else { return nil }
			return (category, categoryItems)
		}
	}
    
	private func saveItems(_ newItems: [KitchenItem]) {
		if let encoded = try? JSONEncoder().encode(newItems) {
			storage.set(encoded, forKey: saveKey)
            items = newItems
            itemNameSet = Set(newItems.map { $0.name.lowercased() })
		}
	}
	
	private func saveInventoryItems(_ newInventoryItems: [KitchenInventoryModel]) {
		if let encoded = try? JSONEncoder().encode(newInventoryItems) {
			storage.set(encoded, forKey: inventorySaveKey)
            inventoryItems = newInventoryItems
		}
	}
}

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
