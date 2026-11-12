import CoreData
import Foundation

/// Where cook dates live once moved out of the `LocalStore` blob: Core Data in the app, a fake in tests.
@MainActor
protocol CookDateStoring: AnyObject {
    /// Every stored cook date, oldest first.
    func fetchCookDates() throws -> [Date]
    func addCookDates(_ dates: [Date]) throws
    func deleteAllCookDates() throws
}

enum CookDateStoreError: LocalizedError {
    case storeUnavailable

    var errorDescription: String? {
        switch self {
        case .storeUnavailable: "The recipe database isn't open."
        }
    }
}

/// `CookDateEntity` rows (RecipeModel 16), one per cook. Uses KVC on plain `NSManagedObject`, like the recipe writes,
/// so tests that load the model in several containers never hit "multiple entities claim the class".
@MainActor
final class CoreDataCookDateStore: CookDateStoring {
    static let entityName = "CookDateEntity"

    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    private func readyContext() throws -> NSManagedObjectContext {
        guard persistence.ensureStoreIsReady() else { throw CookDateStoreError.storeUnavailable }
        return persistence.container.viewContext
    }

    func fetchCookDates() throws -> [Date] {
        let context = try readyContext()
        let request = NSFetchRequest<NSManagedObject>(entityName: Self.entityName)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        return try context.fetch(request).compactMap { $0.value(forKey: "date") as? Date }
    }

    func addCookDates(_ dates: [Date]) throws {
        guard !dates.isEmpty else { return }
        let context = try readyContext()
        guard let entity = NSEntityDescription.entity(forEntityName: Self.entityName, in: context) else {
            throw CookDateStoreError.storeUnavailable
        }
        for date in dates {
            let row = NSManagedObject(entity: entity, insertInto: context)
            row.setValue(UUID(), forKey: "id")
            row.setValue(date, forKey: "date")
        }
        try save(context)
    }

    func deleteAllCookDates() throws {
        let context = try readyContext()
        let request = NSFetchRequest<NSManagedObject>(entityName: Self.entityName)
        for row in try context.fetch(request) { context.delete(row) }
        try save(context)
    }

    /// A failed save is rolled back so half-inserted rows don't ride along with the next unrelated save.
    private func save(_ context: NSManagedObjectContext) throws {
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
