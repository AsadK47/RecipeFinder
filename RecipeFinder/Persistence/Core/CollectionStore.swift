import CoreData
import Foundation

/// Where collections live once moved out of the `LocalStore` blob: Core Data in the app, a fake in tests.
@MainActor
protocol CollectionStoring: AnyObject {
    /// Every stored collection, in list order.
    func fetchCollections() throws -> [RecipeCollection]
    /// Makes the store hold exactly these collections, in this order.
    func replaceCollections(with collections: [RecipeCollection]) throws
}

enum CollectionStoreError: LocalizedError {
    case storeUnavailable

    var errorDescription: String? {
        switch self {
        case .storeUnavailable: "The recipe database isn't open."
        }
    }
}

/// `CollectionEntity` rows (RecipeModel 16), one per collection, `sortOrder` = list position. Rows are updated in place
/// by id (not deleted and re-inserted) so sync later sees edits, not churn. KVC on plain `NSManagedObject`, like
/// `CoreDataCookDateStore`.
@MainActor
final class CoreDataCollectionStore: CollectionStoring {
    static let entityName = "CollectionEntity"

    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    private func readyContext() throws -> NSManagedObjectContext {
        guard persistence.ensureStoreIsReady() else { throw CollectionStoreError.storeUnavailable }
        return persistence.container.viewContext
    }

    private func fetchRows(in context: NSManagedObjectContext) throws -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: Self.entityName)
        request.sortDescriptors = [
            NSSortDescriptor(key: "sortOrder", ascending: true),
            NSSortDescriptor(key: "createdAt", ascending: true),
        ]
        return try context.fetch(request)
    }

    func fetchCollections() throws -> [RecipeCollection] {
        let context = try readyContext()
        let decoder = JSONDecoder()
        return try fetchRows(in: context).compactMap { row in
            guard let id = row.value(forKey: "id") as? UUID else { return nil }
            let recipeIDs = try (row.value(forKey: "recipeIDs") as? Data).map { try decoder.decode([UUID].self, from: $0) }
            return RecipeCollection(
                id: id,
                name: row.value(forKey: "name") as? String ?? "",
                colorName: (row.value(forKey: "colorName") as? String).flatMap(CollectionColor.init(rawValue:)) ?? .blue,
                recipeIDs: recipeIDs ?? [],
                createdAt: row.value(forKey: "createdAt") as? Date ?? .distantPast
            )
        }
    }

    func replaceCollections(with collections: [RecipeCollection]) throws {
        let context = try readyContext()
        guard let entity = NSEntityDescription.entity(forEntityName: Self.entityName, in: context) else {
            throw CollectionStoreError.storeUnavailable
        }
        do {
            try apply(collections, entity: entity, in: context)
            if context.hasChanges { try context.save() }
        } catch {
            // Rolled back so half-applied rows don't ride along with the next unrelated save.
            context.rollback()
            throw error
        }
    }

    private func apply(
        _ collections: [RecipeCollection], entity: NSEntityDescription, in context: NSManagedObjectContext
    ) throws {
        var rowsByID: [UUID: NSManagedObject] = [:]
        for row in try fetchRows(in: context) {
            // Rows without an id, or a second row with the same id, can't be matched to a collection.
            if let id = row.value(forKey: "id") as? UUID, rowsByID[id] == nil {
                rowsByID[id] = row
            } else {
                context.delete(row)
            }
        }
        let encoder = JSONEncoder()
        for (index, collection) in collections.enumerated() {
            let row = rowsByID.removeValue(forKey: collection.id) ?? NSManagedObject(entity: entity, insertInto: context)
            row.setValue(collection.id, forKey: "id")
            row.setValue(collection.name, forKey: "name")
            row.setValue(collection.colorName.rawValue, forKey: "colorName")
            row.setValue(try encoder.encode(collection.recipeIDs), forKey: "recipeIDs")
            row.setValue(collection.createdAt, forKey: "createdAt")
            row.setValue(NSNumber(value: Int32(clamping: index)), forKey: "sortOrder")
        }
        for leftover in rowsByID.values { context.delete(leftover) }
    }
}
