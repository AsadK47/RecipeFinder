import SwiftUI

/// Behavioural seam so views depend on this protocol, not the `BadgeManager` singleton, and tests can inject a fake.
@MainActor
protocol BadgeManaging: AnyObject, Observable {
    var pendingCelebration: BadgeType? { get }
    func getAllBadges(recipeCount: Int) -> [Badge]
    func dismissCelebration()
}

private struct BadgeManagingKey: EnvironmentKey {
    // SwiftUI reads environment defaults on the main actor, so assuming main-actor isolation is safe.
    static var defaultValue: any BadgeManaging {
        MainActor.assumeIsolated { BadgeManager.shared }
    }
}

extension EnvironmentValues {
    /// Injected badge state; defaults to the shared singleton, override with `.environment(\.badges, fake)` in tests/previews.
    var badges: any BadgeManaging {
        get { self[BadgeManagingKey.self] }
        set { self[BadgeManagingKey.self] = newValue }
    }
}

@MainActor
@Observable
final class BadgeManager: BadgeManaging {
    static let shared = BadgeManager()

    var unlockedBadges: [String: Badge] = [:]

    /// Non-nil when a celebration sheet should show; `dismissCelebration()` clears it and drains the queue for back-to-back unlocks.
    private(set) var pendingCelebration: BadgeType?

    static let badgesBlobKey = "unlockedBadges"
    static let shownCelebrationsBlobKey = "shownBadgeCelebrations"
    /// Badges live in `EarnedBadgeEntity` rows; the two old `LocalStore` keys are kept current for one release.
    @ObservationIgnored private let mirror: MirroredSnapshot<EarnedBadgeRecord>
    @ObservationIgnored private let storage: LocalStore

    /// When true, unlocks persist but no celebration sheets fire; set by bulk-import to avoid a parade of sheets.
    @ObservationIgnored var isBulkImporting = false

    // FIFO queue: badges earned faster than the user can dismiss pile up here.
    @ObservationIgnored private var celebrationQueue: [BadgeType] = []
    // Persisted so a celebration never fires twice for the same badge, even if killed mid-sheet.
    @ObservationIgnored private var shownCelebrationIds: Set<String> = []

    private convenience init() {
        self.init(storage: .shared, badgeStore: CoreDataEarnedBadgeStore(persistence: .shared))
    }

    init(storage: LocalStore, badgeStore: any EarnedBadgeStoring) {
        self.storage = storage
        self.mirror = MirroredSnapshot(
            blobKey: Self.badgesBlobKey,
            storage: storage,
            readBlob: { Self.readKeptCopy(from: storage) },
            writeBlob: { Self.writeKeptCopy($0, to: storage) },
            removeBlob: {
                storage.removeObject(forKey: Self.badgesBlobKey)
                storage.removeObject(forKey: Self.shownCelebrationsBlobKey)
            },
            fetch: { try badgeStore.fetchBadges() },
            replace: { try badgeStore.replaceBadges(with: $0) },
            sync: .iCloudRules(storage: storage) { $0.badgeId }
        )
        reload()
    }

    func reload() {
        let records = mirror.load()
        unlockedBadges = EarnedBadgeRecord.earnedBadges(from: records)
        // The old shown list is unioned in: with an unreadable badges dict the mirror ignores the kept copy, and a
        // celebration the cook already saw must still never pop again. Reset clears this key too.
        let keptShown = storage.object(forKey: Self.shownCelebrationsBlobKey) as? [String] ?? []
        shownCelebrationIds = EarnedBadgeRecord.shownCelebrations(from: records).union(keptShown)
    }

    /// Erase & Reset: removes every earned badge and celebration record. If the store can't delete now, the next
    /// launch finishes it.
    func removeAllBadges() {
        mirror.removeAll()
        celebrationQueue = []
        pendingCelebration = nil
        reload()
    }

    /// The old shape: earned badges as a dictionary, shown celebrations as a separate id list. Nil when the badges
    /// dictionary is missing or unreadable — shown ids alone never stand in for the store.
    private static func readKeptCopy(from storage: LocalStore) -> [EarnedBadgeRecord]? {
        guard let earned = storage.decodable([String: Badge].self, forKey: badgesBlobKey) else { return nil }
        let shown = storage.object(forKey: shownCelebrationsBlobKey) as? [String] ?? []
        return EarnedBadgeRecord.records(earned: earned, shown: Set(shown))
    }

    private static func writeKeptCopy(_ records: [EarnedBadgeRecord], to storage: LocalStore) {
        storage.setEncodable(EarnedBadgeRecord.earnedBadges(from: records), forKey: badgesBlobKey)
        storage.set(EarnedBadgeRecord.shownCelebrations(from: records).sorted(), forKey: shownCelebrationsBlobKey)
    }

    /// Non-destructive restore: unions by id (held badge wins on collision, preserving `dateEarned`); restored badges never trigger celebration sheets.
    func merge(_ incoming: [String: Badge]) {
        let (merged, addedIDs) = BackupMerge.mergedBadgesWithAdditions(existing: unlockedBadges, incoming: incoming)
        unlockedBadges = merged
        // Mark all newly-merged badges as already-shown so they don't pop a sheet.
        shownCelebrationIds.formUnion(addedIDs)
        save()
    }

    /// Legacy library-size path (import/add trigger sites). Only unlocks collection badges — cooking/streak/
    /// breadth badges go through `checkAndUnlockBadges(metrics:)` so they can't unlock on a zero threshold.
    func checkAndUnlockBadges(recipeCount: Int, silent: Bool = false) {
        let earned = BadgeType.allCases.filter {
            $0.criterion.metric == .recipesCollected
                && recipeCount >= $0.criterion.threshold
                && !isBadgeUnlocked($0.rawValue)
        }
        unlockBatch(earned, silent: silent)
    }

    /// Unified metrics path: unlocks every threshold badge whose metric has reached its target. A superset of
    /// the recipe-count path (it also catches collection badges), driven from the cook choke point.
    func checkAndUnlockBadges(metrics: BadgeMetrics, silent: Bool = false) {
        let earned = BadgeType.allCases.filter { badgeType in
            guard let metric = badgeType.criterion.metric else { return false }
            return metrics.value(for: metric) >= badgeType.criterion.threshold && !isBadgeUnlocked(badgeType.rawValue)
        }
        unlockBatch(earned, silent: silent)
    }

    /// Unlocks every badge in `earned`, but celebrates at most one: when several cross at once (e.g. a jump in the
    /// library size) the user saw a parade of sheets. The highest-threshold badge gets the sheet; the rest are
    /// saved quietly and marked shown so they never pop later. welcomeAboard is always silent.
    private func unlockBatch(_ earned: [BadgeType], silent: Bool) {
        let celebrated = silent ? nil : earned
            .filter { $0 != .welcomeAboard }
            .max { $0.criterion.threshold < $1.criterion.threshold }
        for badgeType in earned where badgeType != celebrated {
            // Marked before the unlock so its save carries the flag (a kill right after can't lose it).
            shownCelebrationIds.insert(badgeType.rawValue)
            unlockBadge(badgeType, silent: true)
        }
        if let celebrated { unlockBadge(celebrated) }
    }

    /// Removes collection badges the library no longer earns. Used once after repairing legacy sample recipes that
    /// had been miscounted as user-collected (which had unlocked every collection badge at once).
    func revokeUnearnedCollectionBadges(collectedCount: Int) {
        var changed = false
        for badgeType in BadgeType.allCases
        where badgeType.criterion.metric == .recipesCollected
            && badgeType != .welcomeAboard
            && collectedCount < badgeType.criterion.threshold
            && isBadgeUnlocked(badgeType.rawValue) {
            unlockedBadges[badgeType.rawValue] = nil
            changed = true
        }
        if changed { save() }
    }

    /// Unlock a badge; `silent: true` persists without a celebration sheet (used for welcome/seed badges at launch).
    func unlockBadge(_ badgeType: BadgeType, customDate: Date? = nil, silent: Bool = false) {
        guard !isBadgeUnlocked(badgeType.rawValue) else { return }

        let badge = badgeType.badge
        let unlockedBadge = Badge(
            id: badge.id,
            title: badge.title,
            description: badge.description,
            icon: badge.icon,
            color: badge.color,
            dateEarned: customDate ?? Date(),
            isUnlocked: true,
            howToEarn: badge.howToEarn
        )
        unlockedBadges[badge.id] = unlockedBadge
        save()

        guard !isBulkImporting, !silent, !shownCelebrationIds.contains(badge.id) else { return }
        celebrationQueue.append(badgeType)
        drainQueueIfIdle()
    }

    /// Call when the badge-earned sheet is dismissed to advance to the next queued celebration.
    func dismissCelebration() {
        pendingCelebration = nil
        drainQueueIfIdle()
    }

    #if DEBUG
    /// UI-test hook (`-show-badge-reveal`): opens a reveal without unlocking or recording anything, so later launches
    /// see the same shelf.
    func showRevealForUITesting(_ badgeType: BadgeType) {
        guard pendingCelebration == nil else { return }
        pendingCelebration = badgeType
    }
    #endif

    func isBadgeUnlocked(_ badgeId: String) -> Bool {
        unlockedBadges[badgeId] != nil
    }

    func getAllBadges(recipeCount: Int) -> [Badge] {
        BadgeType.allCases.map { unlockedBadges[$0.rawValue] ?? $0.badge }
    }

    // MARK: - Private

    private func drainQueueIfIdle() {
        guard pendingCelebration == nil, let next = celebrationQueue.first else { return }
        celebrationQueue.removeFirst()
        shownCelebrationIds.insert(next.rawValue)
        save()
        pendingCelebration = next
    }

    private func save() {
        mirror.save(EarnedBadgeRecord.records(earned: unlockedBadges, shown: shownCelebrationIds))
    }
}
