import CoreData
import Foundation

/// Where the shopping list and the user's grocery stores live once moved out of their `LocalStore` blobs: Core Data
/// in the app, a fake in tests.
@MainActor
protocol ShoppingListStoring: StoreFileIdentifying {
    /// Every stored item, in list order.
    func fetchItems() throws -> [ShoppingListModel]
    /// Makes the store hold exactly these items, in this order.
    func replaceItems(with items: [ShoppingListModel]) throws
    /// The user's grocery stores, in the order they added them.
    func fetchStores() throws -> [String]
    /// Makes the store hold exactly these grocery stores, in this order.
    func replaceStores(with stores: [String]) throws
}

enum ShoppingListStoreError: LocalizedError {
    case storeUnavailable

    var errorDescription: String? {
        switch self {
        case .storeUnavailable: "The recipe database isn't open."
        }
    }
}

/// `ShoppingItemEntity` / `ShoppingStoreEntity` rows (RecipeModel 16), `sortOrder` = list position, updated in place
/// like `CoreDataMealPlanStore`. Items match rows by id; grocery stores have no id of their own, so they match by name
/// (names are unique, see `GroceryStoreNames`).
@MainActor
final class CoreDataShoppingListStore: ShoppingListStoring {
    static let itemEntityName = "ShoppingItemEntity"
    static let storeEntityName = "ShoppingStoreEntity"

    private let persistence: PersistenceController

    var storeFileID: String? { persistence.storeFileID }

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    private func readyContext() throws -> NSManagedObjectContext {
        guard persistence.ensureStoreIsReady() else { throw ShoppingListStoreError.storeUnavailable }
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

    /// Saves what `apply` changed, or rolls it all back so half-applied rows don't ride along with the next save.
    private func write(_ entityName: String, apply: (NSEntityDescription, NSManagedObjectContext) throws -> Void) throws {
        let context = try readyContext()
        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else {
            throw ShoppingListStoreError.storeUnavailable
        }
        do {
            try apply(entity, context)
            if context.hasChanges { try context.save() }
        } catch {
            context.rollback()
            throw error
        }
    }

    // MARK: - Items

    func fetchItems() throws -> [ShoppingListModel] {
        try fetchRows(Self.itemEntityName, in: readyContext()).compactMap(Self.item(from:))
    }

    /// A row without an id or name is skipped; anything else falls back to the struct's defaults, so one odd row
    /// never hides the rest of the list.
    private static func item(from row: NSManagedObject) -> ShoppingListModel? {
        guard let id = row.value(forKey: "id") as? UUID,
              let name = row.value(forKey: "name") as? String else { return nil }
        let isChecked = (row.value(forKey: "isChecked") as? NSNumber)?.boolValue ?? false
        var item = ShoppingListModel(
            id: id,
            name: name,
            isChecked: isChecked,
            quantity: (row.value(forKey: "quantity") as? NSNumber)?.intValue ?? 1,
            unit: row.value(forKey: "unit") as? String ?? "",
            category: row.value(forKey: "category") as? String ?? "Other",
            dateAdded: row.value(forKey: "dateAdded") as? Date ?? Date(timeIntervalSinceReferenceDate: 0),
            stores: (row.value(forKey: "stores") as? Data).flatMap(decodeStores) ?? [],
            isRecurring: (row.value(forKey: "isRecurring") as? NSNumber)?.boolValue ?? false
        )
        item.isCompleted = (row.value(forKey: "isCompleted") as? NSNumber)?.boolValue ?? isChecked
        return item
    }

    /// RecipeModel 16 stores array attributes as JSONEncoder output (see `CoreDataCollectionStore`).
    private static func decodeStores(_ data: Data) -> [String]? {
        do {
            return try JSONDecoder().decode([String].self, from: data)
        } catch {
            AppLogger.logger(category: "ShoppingListStore").error("❌ Unreadable item stores: \(error.localizedDescription)")
            return nil
        }
    }

    func replaceItems(with items: [ShoppingListModel]) throws {
        let encoder = JSONEncoder()
        try write(Self.itemEntityName) { entity, context in
            var rowsByID: [UUID: NSManagedObject] = [:]
            for row in try fetchRows(Self.itemEntityName, in: context) {
                // Rows without an id, or a second row with the same id, can't be matched to an item.
                if let id = row.value(forKey: "id") as? UUID, rowsByID[id] == nil {
                    rowsByID[id] = row
                } else {
                    context.delete(row)
                }
            }
            for (index, item) in items.enumerated() {
                let row = rowsByID.removeValue(forKey: item.id) ?? NSManagedObject(entity: entity, insertInto: context)
                row.setIfChanged(item.id as NSUUID, forKey: "id")
                row.setIfChanged(item.name as NSString, forKey: "name")
                row.setIfChanged(NSNumber(value: Int64(item.quantity)), forKey: "quantity")
                row.setIfChanged(item.unit as NSString, forKey: "unit")
                row.setIfChanged(NSNumber(value: item.isChecked), forKey: "isChecked")
                row.setIfChanged(NSNumber(value: item.isCompleted), forKey: "isCompleted")
                row.setIfChanged(item.category as NSString, forKey: "category")
                row.setIfChanged(item.dateAdded as NSDate, forKey: "dateAdded")
                row.setIfChanged(try encoder.encode(item.stores) as NSData, forKey: "stores")
                row.setIfChanged(NSNumber(value: item.isRecurring), forKey: "isRecurring")
                row.setIfChanged(NSNumber(value: Int32(clamping: index)), forKey: "sortOrder")
            }
            for leftover in rowsByID.values { context.delete(leftover) }
        }
    }

    // MARK: - Grocery stores

    func fetchStores() throws -> [String] {
        try fetchRows(Self.storeEntityName, in: readyContext()).compactMap { $0.value(forKey: "name") as? String }
    }

    func replaceStores(with stores: [String]) throws {
        try write(Self.storeEntityName) { entity, context in
            var rowsByName: [String: NSManagedObject] = [:]
            for row in try fetchRows(Self.storeEntityName, in: context) {
                if let name = row.value(forKey: "name") as? String, rowsByName[name] == nil {
                    rowsByName[name] = row
                } else {
                    context.delete(row)
                }
            }
            for (index, name) in stores.enumerated() {
                let row = rowsByName.removeValue(forKey: name) ?? {
                    let inserted = NSManagedObject(entity: entity, insertInto: context)
                    inserted.setValue(UUID(), forKey: "id")
                    inserted.setValue(name, forKey: "name")
                    return inserted
                }()
                row.setIfChanged(NSNumber(value: Int32(clamping: index)), forKey: "sortOrder")
            }
            for leftover in rowsByName.values { context.delete(leftover) }
        }
    }
}
