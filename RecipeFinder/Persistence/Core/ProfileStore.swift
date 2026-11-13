import CoreData
import Foundation

/// The cook's local profile — one `ProfileEntity` row (RecipeModel 16). `chefType` keeps the raw value so a type a
/// newer build added survives an older one.
struct ProfileRecord: Codable, Equatable {
    var uuid: String
    var firstName: String = ""
    var lastName: String = ""
    var chefType: String?
    var createdDate: Date?
    var imageData: Data?
}

/// Where the profile lives once moved out of its `LocalStore` keys: Core Data in the app, a fake in tests.
@MainActor
protocol ProfileStoring: AnyObject {
    /// The stored profile, or nil when there is none.
    func fetchProfile() throws -> ProfileRecord?
    /// Makes the store hold exactly this profile (nil removes it).
    func replaceProfile(with record: ProfileRecord?) throws
}

enum ProfileStoreError: LocalizedError {
    case storeUnavailable

    var errorDescription: String? {
        switch self {
        case .storeUnavailable: "The recipe database isn't open."
        }
    }
}

/// One `ProfileEntity` row matched by `uuid` and updated in place. A row without a uuid, or a second row (a sync
/// duplicate), is ignored on read and deleted on the next write.
@MainActor
final class CoreDataProfileStore: ProfileStoring {
    static let entityName = "ProfileEntity"

    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    private func readyContext() throws -> NSManagedObjectContext {
        guard persistence.ensureStoreIsReady() else { throw ProfileStoreError.storeUnavailable }
        return persistence.container.viewContext
    }

    /// Rows with a uuid first, then by uuid, so the same row is picked every launch.
    private func fetchRows(in context: NSManagedObjectContext) throws -> [NSManagedObject] {
        let rows = try context.fetch(NSFetchRequest<NSManagedObject>(entityName: Self.entityName))
        return rows.sorted { lhs, rhs in
            switch (lhs.value(forKey: "uuid") as? String, rhs.value(forKey: "uuid") as? String) {
            case let (left?, right?): return left < right
            case (.some, .none): return true
            default: return false
            }
        }
    }

    func fetchProfile() throws -> ProfileRecord? {
        guard let row = try fetchRows(in: readyContext()).first,
              let uuid = row.value(forKey: "uuid") as? String else { return nil }
        return ProfileRecord(
            uuid: uuid,
            firstName: row.value(forKey: "firstName") as? String ?? "",
            lastName: row.value(forKey: "lastName") as? String ?? "",
            chefType: row.value(forKey: "chefType") as? String,
            createdDate: row.value(forKey: "createdDate") as? Date,
            imageData: row.value(forKey: "imageData") as? Data
        )
    }

    /// Saved or rolled back together.
    func replaceProfile(with record: ProfileRecord?) throws {
        let context = try readyContext()
        guard let entity = NSEntityDescription.entity(forEntityName: Self.entityName, in: context) else {
            throw ProfileStoreError.storeUnavailable
        }
        do {
            var rows = try fetchRows(in: context)
            if let record {
                let matchIndex = rows.firstIndex { ($0.value(forKey: "uuid") as? String) == record.uuid }
                let row = matchIndex.map { rows.remove(at: $0) } ?? {
                    let inserted = NSManagedObject(entity: entity, insertInto: context)
                    inserted.setValue(UUID(), forKey: "id")
                    inserted.setValue(record.uuid, forKey: "uuid")
                    return inserted
                }()
                row.setIfChanged(record.firstName as NSString, forKey: "firstName")
                row.setIfChanged(record.lastName as NSString, forKey: "lastName")
                row.setIfChanged(record.chefType.map { $0 as NSString }, forKey: "chefType")
                row.setIfChanged(record.createdDate.map { $0 as NSDate }, forKey: "createdDate")
                row.setIfChanged(record.imageData.map { $0 as NSData }, forKey: "imageData")
            }
            for leftover in rows { context.delete(leftover) }
            if context.hasChanges { try context.save() }
        } catch {
            context.rollback()
            throw error
        }
    }
}
