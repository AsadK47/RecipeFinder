import Foundation

/// A recipe the cook deleted, kept (with its photos) in Recently Deleted until it's restored, deleted for good, or
/// `RecentlyDeleted.keptFor` has passed.
struct DeletedRecipe: Identifiable, Equatable, Sendable {
    let recipe: RecipeModel
    let deletedAt: Date

    var id: UUID { recipe.id }
}

/// How long Recently Deleted keeps a recipe. Every device works it out from the same synced `deletedAt`, so they
/// agree on when it goes.
enum RecentlyDeleted {
    static let keptFor: TimeInterval = 30 * 24 * 60 * 60

    /// Rows deleted before this are removed for good.
    static func purgeCutoff(now: Date) -> Date {
        now.addingTimeInterval(-keptFor)
    }

    static func isExpired(_ item: DeletedRecipe, now: Date) -> Bool {
        item.deletedAt < purgeCutoff(now: now)
    }

    /// Whole days left before it goes, rounded up (a recipe deleted a minute ago has 30); 0 once it's due. Never more
    /// than 30, even when another device's clock stamped the delete in this device's future.
    static func daysLeft(_ item: DeletedRecipe, now: Date) -> Int {
        let remaining = item.deletedAt.addingTimeInterval(keptFor).timeIntervalSince(now)
        guard remaining > 0 else { return 0 }
        return min(Int((remaining / (24 * 60 * 60)).rounded(.up)), Int(keptFor / (24 * 60 * 60)))
    }

    /// "30 days left", "1 day left", "Removed soon".
    static func daysLeftText(_ item: DeletedRecipe, now: Date) -> String {
        switch daysLeft(item, now: now) {
        case 0: return "Removed soon"
        case 1: return "1 day left"
        case let days: return "\(days) days left"
        }
    }

    /// One entry per recipe (iCloud can briefly hold two rows with the same id), earliest delete kept, newest first.
    static func oneEach(_ items: [DeletedRecipe]) -> [DeletedRecipe] {
        var earliest: [UUID: DeletedRecipe] = [:]
        for item in items {
            if let known = earliest[item.id], known.deletedAt <= item.deletedAt { continue }
            earliest[item.id] = item
        }
        return earliest.values.sorted {
            $0.deletedAt != $1.deletedAt ? $0.deletedAt > $1.deletedAt : $0.id.uuidString < $1.id.uuidString
        }
    }
}
