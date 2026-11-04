import SwiftUI

private let logger = AppLogger.logger(category: "KitchenInventory")

/// Behavioural seam so views depend on this protocol, not the `KitchenInventoryManager` singleton, and tests can inject a fake.
@MainActor
protocol KitchenInventoryManaging: AnyObject, Observable {
    var items: [KitchenItem] { get }
    var inventoryItems: [KitchenInventoryModel] { get }
    func groupedItems() -> [(category: String, items: [KitchenItem])]
    func toggleItem(_ name: String, category: String?)
    func removeItem(_ item: KitchenItem)
    func removeInventoryItem(_ item: KitchenInventoryModel)
    func clearAll()
    func expiredItems() -> [KitchenInventoryModel]
    func expiringSoonItems() -> [KitchenInventoryModel]
    func lowStockItems() -> [KitchenInventoryModel]
}

private struct KitchenInventoryManagingKey: EnvironmentKey {
    // SwiftUI reads environment defaults on the main actor, so assuming main-actor isolation is safe.
    static var defaultValue: any KitchenInventoryManaging {
        MainActor.assumeIsolated { KitchenInventoryManager.shared }
    }
}

extension EnvironmentValues {
    /// Injected kitchen inventory; defaults to the shared singleton, override with `.environment(\.kitchen, fake)` in tests/previews.
    var kitchen: any KitchenInventoryManaging {
        get { self[KitchenInventoryManagingKey.self] }
        set { self[KitchenInventoryManagingKey.self] = newValue }
    }
}

@MainActor
@Observable
final class KitchenInventoryManager: KitchenInventoryManaging {
	static let shared = KitchenInventoryManager()
    
	private let saveKey = Constants.UserDefaultsKeys.kitchenItems
	private let inventorySaveKey = "kitchenInventoryItems"
	private let migrationKey = "kitchenItemsMigrationCompleted_v1"
    @ObservationIgnored private let storage: LocalStore

    private(set) var items: [KitchenItem] = []
    private(set) var inventoryItems: [KitchenInventoryModel] = []
    // O(1) name lookup — kept in sync with items on every save/load
    @ObservationIgnored private var itemNameSet: Set<String> = []
    // O(1) inventory name lookup — mirrors inventoryItems.
    @ObservationIgnored private var inventoryNameSet: Set<String> = []
    // Pre-grouped and sorted once per save/load; reading it in body is O(1).
    private(set) var groupedItemsCache: [(category: String, items: [KitchenItem])] = []

	private init() {
        self.storage = .shared
        loadItems()
		migrateOldDataIfNeeded()
        loadInventoryItems()
	}

    init(storage: LocalStore) {
        self.storage = storage
        loadItems()
        loadInventoryItems()
    }
    
    func reload() {
        loadItems()
        loadInventoryItems()
    }

    private func loadItems() {
        if let data = storage.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([KitchenItem].self, from: data) {
            items = decoded
            itemNameSet = Set(decoded.map { $0.name.lowercased() })
            groupedItemsCache = computeGroupedItems()
        } else {
            items = []
            itemNameSet = []
            groupedItemsCache = []
        }
    }
    
    private func loadInventoryItems() {
        if let data = storage.data(forKey: inventorySaveKey),
           let decoded = try? JSONDecoder().decode([KitchenInventoryModel].self, from: data) {
            inventoryItems = decoded
            inventoryNameSet = Set(decoded.map { $0.name.lowercased() })
        } else {
            inventoryItems = []
            inventoryNameSet = []
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
		NotificationManager.shared.scheduleExpiryNotification(for: item)
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
			NotificationManager.shared.cancelExpiryNotification(for: item.id)
			NotificationManager.shared.scheduleExpiryNotification(for: item)
			logger.debug("✅ Updated inventory item: '\(item.name)'")
		}
	}
	
	func removeInventoryItem(_ item: KitchenInventoryModel) {
		var updatedItems = inventoryItems
		updatedItems.removeAll { $0.id == item.id }
		HapticManager.shared.light()
		saveInventoryItems(updatedItems)
		NotificationManager.shared.cancelExpiryNotification(for: item.id)
	}
	
	func hasInventoryItem(_ name: String) -> Bool {
		inventoryNameSet.contains(name.lowercased())
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
		guard !storage.bool(forKey: migrationKey) else { return }
		
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
		
		storage.set(true, forKey: migrationKey)
	}
    
	/// Non-destructive restore: unions both `items` and `inventory` lists by id, without the name-dedupe or expiry/quantity validation that add methods apply.
	func merge(items incomingItems: [KitchenItem], inventory incomingInventory: [KitchenInventoryModel]) {
		saveItems(BackupMerge.merged(existing: items, incoming: incomingItems))
		saveInventoryItems(BackupMerge.merged(existing: inventoryItems, incoming: incomingInventory))
	}

	func addItem(name: String, category: String? = nil, quantity: Double = 1, unit: String = "item") {
		let trimmedName = name.trimmed
		guard !trimmedName.isEmpty else { return }
		guard quantity > 0 else { return }
		
		let detectedCategory = category ?? CategoryClassifier.categorize(trimmedName)
		let newItem = KitchenItem(
			name: trimmedName,
			category: detectedCategory,
			quantity: quantity,
			unit: unit
		)
        
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

	func updateQuantity(for item: KitchenItem, delta: Double) {
		guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
		let newQuantity = max(1, min(99, items[index].quantity + delta))
		guard newQuantity != items[index].quantity else { return }

		var updatedItems = items
		updatedItems[index].quantity = newQuantity
		HapticManager.shared.light()
		saveItems(updatedItems)
	}

	func updateCategory(for item: KitchenItem, category: String) {
		guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
		guard !category.isEmpty, items[index].category != category else { return }

		var updatedItems = items
		updatedItems[index].category = category
		HapticManager.shared.light()
		saveItems(updatedItems)
	}
    
	func hasItem(_ name: String) -> Bool {
		itemNameSet.contains(name.lowercased())
	}
    
	func clearAll() {
		HapticManager.shared.rigid()
		saveItems([])
	}
    
    // Returns the pre-computed cache — O(1); computing inline in body was O(K log K) per re-render.
	func groupedItems() -> [(category: String, items: [KitchenItem])] {
        groupedItemsCache
	}

    private func computeGroupedItems() -> [(category: String, items: [KitchenItem])] {
		let grouped = Dictionary(grouping: items) { $0.category }
		return grouped.keys.sorted().compactMap { category in
			guard let categoryItems = grouped[category], !categoryItems.isEmpty else { return nil }
			return (category, categoryItems.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending })
		}
	}
    
    private func saveItems(_ newItems: [KitchenItem]) {
        items = newItems
        itemNameSet = Set(newItems.map { $0.name.lowercased() })
        groupedItemsCache = computeGroupedItems()
        storage.setEncodable(newItems, forKey: saveKey)
    }

	private func saveInventoryItems(_ newInventoryItems: [KitchenInventoryModel]) {
        inventoryItems = newInventoryItems
        inventoryNameSet = Set(newInventoryItems.map { $0.name.lowercased() })
        storage.setEncodable(newInventoryItems, forKey: inventorySaveKey)
	}
}

struct KitchenItem: Identifiable, Codable, Equatable, Hashable {
	let id: UUID
	var name: String
	var category: String
	var quantity: Double
	var unit: String
	var dateAdded: Date

	enum CodingKeys: String, CodingKey {
		case id, name, category, quantity, unit, dateAdded
	}

	init(id: UUID = UUID(), name: String, category: String, quantity: Double = 1, unit: String = "item", dateAdded: Date = Date()) {
		self.id = id
		self.name = name
		self.category = category
		self.quantity = quantity
		self.unit = unit
		self.dateAdded = dateAdded
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		id = try container.decode(UUID.self, forKey: .id)
		name = try container.decode(String.self, forKey: .name)
		category = try container.decode(String.self, forKey: .category)
		quantity = try container.decodeIfPresent(Double.self, forKey: .quantity) ?? 1
		unit = try container.decodeIfPresent(String.self, forKey: .unit) ?? "item"
		dateAdded = try container.decodeIfPresent(Date.self, forKey: .dateAdded) ?? Date()
	}
}
