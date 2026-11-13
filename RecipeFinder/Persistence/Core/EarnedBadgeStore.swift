import CoreData
import Foundation

/// One badge the cook has earned and/or already seen celebrated — one `EarnedBadgeEntity` row (RecipeModel 16).
/// A row can be shown-but-not-earned: a badge revoked after its celebration keeps the flag, so earning it again
/// never pops the sheet twice.
struct EarnedBadgeRecord: Codable, Equatable {
    let badgeId: String
    let isEarned: Bool
    let dateEarned: Date?
    let celebrationShown: Bool

    /// The manager's two lists as rows, sorted by badge id so the blob and the store always list them the same way.
    static func records(earned: [String: Badge], shown: Set<String>) -> [EarnedBadgeRecord] {
        Set(earned.keys).union(shown).sorted().map { id in
            EarnedBadgeRecord(
                badgeId: id,
                isEarned: earned[id] != nil,
                dateEarned: earned[id]?.dateEarned,
                celebrationShown: shown.contains(id)
            )
        }
    }

    /// Earned badges by id; display fields come from `BadgeType`, an id this build doesn't know keeps a bare badge so
    /// it survives until a build that knows it.
    static func earnedBadges(from records: [EarnedBadgeRecord]) -> [String: Badge] {
        var badges: [String: Badge] = [:]
        for record in records where record.isEarned {
            let template = BadgeType(rawValue: record.badgeId)?.badge
                ?? Badge(id: record.badgeId, title: record.badgeId, description: "", icon: "rosette", color: "gray")
            badges[record.badgeId] = Badge(
                id: record.badgeId,
                title: template.title,
                description: template.description,
                icon: template.icon,
                color: template.color,
                dateEarned: record.dateEarned,
                isUnlocked: true,
                howToEarn: template.howToEarn
            )
        }
        return badges
    }

    static func shownCelebrations(from records: [EarnedBadgeRecord]) -> Set<String> {
        Set(records.filter(\.celebrationShown).map(\.badgeId))
    }
}

/// Where earned badges live once moved out of their `LocalStore` blobs: Core Data in the app, a fake in tests.
@MainActor
protocol EarnedBadgeStoring: AnyObject {
    /// Every stored badge row, sorted by badge id.
    func fetchBadges() throws -> [EarnedBadgeRecord]
    /// Makes the store hold exactly these rows.
    func replaceBadges(with records: [EarnedBadgeRecord]) throws
}

enum EarnedBadgeStoreError: LocalizedError {
    case storeUnavailable

    var errorDescription: String? {
        switch self {
        case .storeUnavailable: "The recipe database isn't open."
        }
    }
}

/// `EarnedBadgeEntity` rows matched by `badgeId` (unique per badge) and updated in place; new rows get a fresh UUID
/// `id` like `CoreDataShoppingListStore`'s grocery stores.
@MainActor
final class CoreDataEarnedBadgeStore: EarnedBadgeStoring {
    static let entityName = "EarnedBadgeEntity"

    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    private func readyContext() throws -> NSManagedObjectContext {
        guard persistence.ensureStoreIsReady() else { throw EarnedBadgeStoreError.storeUnavailable }
        return persistence.container.viewContext
    }

    private func fetchRows(in context: NSManagedObjectContext) throws -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: Self.entityName)
        request.sortDescriptors = [NSSortDescriptor(key: "badgeId", ascending: true)]
        return try context.fetch(request)
    }

    /// A row without a badge id is skipped, and a second row for the same badge (a sync duplicate) is ignored. Sorted
    /// in Swift so the order matches `EarnedBadgeRecord.records` exactly, whatever collation the store uses.
    func fetchBadges() throws -> [EarnedBadgeRecord] {
        var seen: Set<String> = []
        let records: [EarnedBadgeRecord] = try fetchRows(in: readyContext()).compactMap { row in
            guard let badgeId = row.value(forKey: "badgeId") as? String, seen.insert(badgeId).inserted else {
                return nil
            }
            return EarnedBadgeRecord(
                badgeId: badgeId,
                isEarned: (row.value(forKey: "isUnlocked") as? NSNumber)?.boolValue ?? false,
                dateEarned: row.value(forKey: "dateEarned") as? Date,
                celebrationShown: (row.value(forKey: "celebrationShown") as? NSNumber)?.boolValue ?? false
            )
        }
        return records.sorted { $0.badgeId < $1.badgeId }
    }

    /// Rows without a badge id, duplicates and leftovers are deleted; saved or rolled back together.
    func replaceBadges(with records: [EarnedBadgeRecord]) throws {
        let context = try readyContext()
        guard let entity = NSEntityDescription.entity(forEntityName: Self.entityName, in: context) else {
            throw EarnedBadgeStoreError.storeUnavailable
        }
        do {
            var rowsByBadge: [String: NSManagedObject] = [:]
            for row in try fetchRows(in: context) {
                if let badgeId = row.value(forKey: "badgeId") as? String, rowsByBadge[badgeId] == nil {
                    rowsByBadge[badgeId] = row
                } else {
                    context.delete(row)
                }
            }
            for record in records {
                let row = rowsByBadge.removeValue(forKey: record.badgeId) ?? {
                    let inserted = NSManagedObject(entity: entity, insertInto: context)
                    inserted.setValue(UUID(), forKey: "id")
                    inserted.setValue(record.badgeId, forKey: "badgeId")
                    return inserted
                }()
                row.setIfChanged(NSNumber(value: record.isEarned), forKey: "isUnlocked")
                row.setIfChanged(record.dateEarned.map { $0 as NSDate }, forKey: "dateEarned")
                row.setIfChanged(NSNumber(value: record.celebrationShown), forKey: "celebrationShown")
            }
            for leftover in rowsByBadge.values { context.delete(leftover) }
            if context.hasChanges { try context.save() }
        } catch {
            context.rollback()
            throw error
        }
    }
}
