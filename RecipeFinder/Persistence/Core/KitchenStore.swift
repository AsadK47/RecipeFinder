import CoreData
import Foundation

/// Where the kitchen ("in my kitchen" items and the dated inventory) lives once moved out of its `LocalStore` blobs:
/// Core Data in the app, a fake in tests.
@MainActor
protocol KitchenStoring: StoreFileIdentifying {
    /// Every stored kitchen item, in list order.
    func fetchItems() throws -> [KitchenItem]
    /// Makes the store hold exactly these kitchen items, in this order.
    func replaceItems(with items: [KitchenItem]) throws
    /// Every stored inventory item, in list order.
    func fetchInventory() throws -> [KitchenInventoryModel]
    /// Makes the store hold exactly these inventory items, in this order.
    func replaceInventory(with items: [KitchenInventoryModel]) throws
}

enum KitchenStoreError: LocalizedError {
    case storeUnavailable

    var errorDescription: String? {
        switch self {
        case .storeUnavailable: "The recipe database isn't open."
        }
    }
}

/// `KitchenItemEntity` / `InventoryItemEntity` rows (RecipeModel 16), `sortOrder` = list position, matched by id and
/// updated in place like `CoreDataShoppingListStore`.
@MainActor
final class CoreDataKitchenStore: KitchenStoring {
    static let itemEntityName = "KitchenItemEntity"
    static let inventoryEntityName = "InventoryItemEntity"

    private let persistence: PersistenceController

    var storeFileID: String? { persistence.storeFileID }

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    private func readyContext() throws -> NSManagedObjectContext {
        guard persistence.ensureStoreIsReady() else { throw KitchenStoreError.storeUnavailable }
        return persistence.container.viewContext
    }

    private func fetchRows(_ entityName: String, in context: NSManagedObjectContext) throws -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        // Name breaks ties between rows sharing a position (sync duplicates), so the order is stable.
        request.sortDescriptors = [
            NSSortDescriptor(key: "sortOrder", ascending: true),
            NSSortDescriptor(key: "name", ascending: true),
        ]
        return try context.fetch(request)
    }

    /// Upserts by id: rows without an id or a second row with the same id are deleted, leftovers are deleted, and
    /// everything is saved or rolled back together so half-applied rows don't ride along with the next save.
    private func replace<Value: Identifiable>(
        _ entityName: String,
        with values: [Value],
        fill: (NSManagedObject, Value) -> Void
    ) throws where Value.ID == UUID {
        let context = try readyContext()
        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else {
            throw KitchenStoreError.storeUnavailable
        }
        do {
            var rowsByID: [UUID: NSManagedObject] = [:]
            for row in try fetchRows(entityName, in: context) {
                if let id = row.value(forKey: "id") as? UUID, rowsByID[id] == nil {
                    rowsByID[id] = row
                } else {
                    context.delete(row)
                }
            }
            for (index, value) in values.enumerated() {
                let row = rowsByID.removeValue(forKey: value.id) ?? NSManagedObject(entity: entity, insertInto: context)
                row.setIfChanged(value.id as NSUUID, forKey: "id")
                fill(row, value)
                row.setIfChanged(NSNumber(value: Int32(clamping: index)), forKey: "sortOrder")
            }
            for leftover in rowsByID.values { context.delete(leftover) }
            if context.hasChanges { try context.save() }
        } catch {
            context.rollback()
            throw error
        }
    }

    // MARK: - Kitchen items

    func fetchItems() throws -> [KitchenItem] {
        try fetchRows(Self.itemEntityName, in: readyContext()).compactMap(Self.item(from:))
    }

    /// A row without an id or name is skipped; anything else falls back to the struct's defaults.
    private static func item(from row: NSManagedObject) -> KitchenItem? {
        guard let id = row.value(forKey: "id") as? UUID,
              let name = row.value(forKey: "name") as? String else { return nil }
        return KitchenItem(
            id: id,
            name: name,
            category: row.value(forKey: "category") as? String ?? "Other",
            quantity: (row.value(forKey: "quantity") as? NSNumber)?.doubleValue ?? 1,
            unit: row.value(forKey: "unit") as? String ?? "item",
            dateAdded: row.value(forKey: "dateAdded") as? Date ?? Date(timeIntervalSinceReferenceDate: 0)
        )
    }

    func replaceItems(with items: [KitchenItem]) throws {
        try replace(Self.itemEntityName, with: items) { row, item in
            row.setIfChanged(item.name as NSString, forKey: "name")
            row.setIfChanged(item.category as NSString, forKey: "category")
            row.setIfChanged(NSNumber(value: item.quantity), forKey: "quantity")
            row.setIfChanged(item.unit as NSString, forKey: "unit")
            row.setIfChanged(item.dateAdded as NSDate, forKey: "dateAdded")
        }
    }

    // MARK: - Inventory

    func fetchInventory() throws -> [KitchenInventoryModel] {
        try fetchRows(Self.inventoryEntityName, in: readyContext()).compactMap(Self.inventoryItem(from:))
    }

    /// A row without an id or name is skipped; an unknown category/location falls back like the blob's decoder does.
    private static func inventoryItem(from row: NSManagedObject) -> KitchenInventoryModel? {
        guard let id = row.value(forKey: "id") as? UUID,
              let name = row.value(forKey: "name") as? String else { return nil }
        return KitchenInventoryModel(
            id: id,
            name: name,
            category: (row.value(forKey: "category") as? String).flatMap(IngredientCategory.init(rawValue:)) ?? .other,
            quantity: (row.value(forKey: "quantity") as? NSNumber)?.doubleValue ?? 1,
            unit: row.value(forKey: "unit") as? String ?? "",
            storageLocation: (row.value(forKey: "storageLocation") as? String)
                .flatMap(StorageLocation.init(rawValue:)) ?? .pantry,
            purchaseDate: row.value(forKey: "purchaseDate") as? Date ?? Date(timeIntervalSinceReferenceDate: 0),
            expiryDate: row.value(forKey: "expiryDate") as? Date,
            notes: row.value(forKey: "notes") as? String,
            isLowStock: (row.value(forKey: "isLowStock") as? NSNumber)?.boolValue ?? false,
            minimumQuantity: (row.value(forKey: "minimumQuantity") as? NSNumber)?.doubleValue
        )
    }

    func replaceInventory(with items: [KitchenInventoryModel]) throws {
        try replace(Self.inventoryEntityName, with: items) { row, item in
            row.setIfChanged(item.name as NSString, forKey: "name")
            row.setIfChanged(item.category.rawValue as NSString, forKey: "category")
            row.setIfChanged(NSNumber(value: item.quantity), forKey: "quantity")
            row.setIfChanged(item.unit as NSString, forKey: "unit")
            row.setIfChanged(item.storageLocation.rawValue as NSString, forKey: "storageLocation")
            row.setIfChanged(item.purchaseDate as NSDate, forKey: "purchaseDate")
            row.setIfChanged(item.expiryDate.map { $0 as NSDate }, forKey: "expiryDate")
            row.setIfChanged(item.notes.map { $0 as NSString }, forKey: "notes")
            row.setIfChanged(NSNumber(value: item.isLowStock), forKey: "isLowStock")
            row.setIfChanged(item.minimumQuantity.map { NSNumber(value: $0) }, forKey: "minimumQuantity")
        }
    }
}
