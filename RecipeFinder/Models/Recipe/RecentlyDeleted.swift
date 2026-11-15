import Foundation

/// A recipe the cook deleted, kept (with its photos) in Recently Deleted until it's restored, deleted for good, or
/// `RecentlyDeleted.keptFor` has passed.
struct DeletedRecipe: Identifiable, Equatable, Sendable {
    let recipe: RecipeModel
    let deletedAt: Date

    var id: UUID { recipe.id }
}

/// How long Recently Deleted keeps a recipe, and when a device may remove one for good. Every device works it out
/// from the same synced `deletedAt`.
enum RecentlyDeleted {
    static let keptFor: TimeInterval = 30 * 24 * 60 * 60
    private static let day: TimeInterval = 24 * 60 * 60

    /// What the purge needs to know about iCloud on this device (`HistoryPurgeRule`, `PersistenceController`).
    struct SyncState: Equatable, Sendable {
        /// Sync has been on here at some point, so other devices may hold this library.
        var everSynced: Bool
        /// Start of the last finished, successful CloudKit export.
        var lastExportStart: Date?
        /// A CloudKit import finished this launch, so other devices' restores made while this one was closed are in.
        var importSeenThisLaunch: Bool

        static let neverSynced = SyncState(everSynced: false, lastExportStart: nil, importSeenThisLaunch: false)
    }

    /// Rows deleted before this are old enough to go.
    static func purgeCutoff(now: Date) -> Date {
        now.addingTimeInterval(-keptFor)
    }

    /// A stamp more than a day in this device's future (another device's clock ahead) counts as made now.
    static func effectiveStamp(_ deletedAt: Date, now: Date) -> Date {
        deletedAt > now.addingTimeInterval(day) ? now : deletedAt
    }

    /// Whether this device may remove a recipe deleted at `deletedAt` (its latest stamp) for good. Kept 30 days
    /// everywhere; once sync has been on, also only after this device has (1) sent the stamp — an export that started
    /// after it finished — so other devices had their 30 days to see and restore it, and (2) received this launch's
    /// iCloud changes, so a restore made elsewhere while this device was closed isn't purged from a stale stamp.
    static func mayPurge(deletedAt: Date, now: Date, sync: SyncState) -> Bool {
        let stamp = effectiveStamp(deletedAt, now: now)
        guard stamp < purgeCutoff(now: now) else { return false }
        guard sync.everSynced else { return true }
        guard sync.importSeenThisLaunch, let lastExportStart = sync.lastExportStart else { return false }
        return stamp < lastExportStart
    }

    /// Whole days left before it goes, rounded up (a recipe deleted a minute ago has 30); 0 once it's due. Never more
    /// than 30, even when another device's clock stamped the delete in this device's future.
    static func daysLeft(_ item: DeletedRecipe, now: Date) -> Int {
        let remaining = item.deletedAt.addingTimeInterval(keptFor).timeIntervalSince(now)
        guard remaining > 0 else { return 0 }
        return min(Int((remaining / day).rounded(.up)), Int(keptFor / day))
    }

    /// "30 days left", "1 day left", "Removed soon".
    static func daysLeftText(_ item: DeletedRecipe, now: Date) -> String {
        switch daysLeft(item, now: now) {
        case 0: return "Removed soon"
        case 1: return "1 day left"
        case let days: return "\(days) days left"
        }
    }

    /// One entry per recipe (iCloud can briefly hold two rows with the same id), carrying the latest stamp — the
    /// one the purge goes by — newest first.
    static func oneEach(_ items: [DeletedRecipe]) -> [DeletedRecipe] {
        var latest: [UUID: DeletedRecipe] = [:]
        for item in items {
            if let known = latest[item.id], known.deletedAt >= item.deletedAt { continue }
            latest[item.id] = item
        }
        return latest.values.sorted {
            $0.deletedAt != $1.deletedAt ? $0.deletedAt > $1.deletedAt : $0.id.uuidString < $1.id.uuidString
        }
    }

    /// Bundled recipes to seed: those the library doesn't hold, counting Recently Deleted, so a built-in recipe the
    /// cook deleted isn't seeded back.
    static func recipesToSeed(bundled: [RecipeModel], existing: [RecipeModel], trashed: [UUID]) -> [RecipeModel] {
        let held = Set(existing.map(\.id)).union(trashed)
        return bundled.filter { !held.contains($0.id) }
    }
}
