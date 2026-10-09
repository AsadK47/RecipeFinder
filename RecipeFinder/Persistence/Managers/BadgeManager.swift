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

    @ObservationIgnored private let storage: UserScopedStorage
    @ObservationIgnored private let badgesKey = "unlockedBadges"
    @ObservationIgnored private let shownCelebrationsKey = "shownBadgeCelebrations"

    /// When true, unlocks persist but no celebration sheets fire; set by bulk-import to avoid a parade of sheets.
    @ObservationIgnored var isBulkImporting = false

    // FIFO queue: badges earned faster than the user can dismiss pile up here.
    @ObservationIgnored private var celebrationQueue: [BadgeType] = []
    // Persisted so a celebration never fires twice for the same badge, even if killed mid-sheet.
    @ObservationIgnored private var shownCelebrationIds: Set<String> = []

    private init() {
        self.storage = .shared
        loadBadges()
        loadShownCelebrations()
    }

    init(storage: UserScopedStorage) {
        self.storage = storage
        loadBadges()
        loadShownCelebrations()
    }

    func reloadForCurrentUser() {
        loadBadges()
        loadShownCelebrations()
    }

    /// Non-destructive restore: unions by id (held badge wins on collision, preserving `dateEarned`); restored badges never trigger celebration sheets.
    func merge(_ incoming: [String: Badge]) {
        let previousIds = Set(unlockedBadges.keys)
        unlockedBadges = BackupMerge.mergedBadges(existing: unlockedBadges, incoming: incoming)
        // Mark all newly-merged badges as already-shown so they don't pop a sheet.
        let newIds = Set(unlockedBadges.keys).subtracting(previousIds)
        for id in newIds {
            shownCelebrationIds.insert(id)
        }
        saveShownCelebrations()
        saveBadges()
    }

    /// Legacy library-size path (import/add trigger sites). Only unlocks collection badges — cooking/streak/
    /// breadth badges go through `checkAndUnlockBadges(metrics:)` so they can't unlock on a zero threshold.
    func checkAndUnlockBadges(recipeCount: Int, silent: Bool = false) {
        for badgeType in BadgeType.allCases {
            guard badgeType.criterion.metric == .recipesCollected,
                  recipeCount >= badgeType.criterion.threshold,
                  !isBadgeUnlocked(badgeType.rawValue) else { continue }
            // welcomeAboard fires silently — a "you joined" pop mid-session would be confusing.
            let shouldBeSilent = silent || badgeType == .welcomeAboard
            unlockBadge(badgeType, silent: shouldBeSilent)
        }
    }

    /// Unified metrics path: unlocks every threshold badge whose metric has reached its target. A superset of
    /// the recipe-count path (it also catches collection badges), driven from the cook choke point.
    func checkAndUnlockBadges(metrics: BadgeMetrics, silent: Bool = false) {
        for badgeType in BadgeType.allCases {
            guard let metric = badgeType.criterion.metric,
                  metrics.value(for: metric) >= badgeType.criterion.threshold,
                  !isBadgeUnlocked(badgeType.rawValue) else { continue }
            let shouldBeSilent = silent || badgeType == .welcomeAboard
            unlockBadge(badgeType, silent: shouldBeSilent)
        }
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
        saveBadges()

        guard !isBulkImporting, !silent, !shownCelebrationIds.contains(badge.id) else { return }
        celebrationQueue.append(badgeType)
        drainQueueIfIdle()
    }

    /// Call when the badge-earned sheet is dismissed to advance to the next queued celebration.
    func dismissCelebration() {
        pendingCelebration = nil
        drainQueueIfIdle()
    }

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
        saveShownCelebrations()
        pendingCelebration = next
    }

    private func saveBadges() {
        storage.setEncodable(unlockedBadges, forKey: badgesKey)
    }

    private func loadBadges() {
        if let data = storage.data(forKey: badgesKey),
           let decoded = try? JSONDecoder().decode([String: Badge].self, from: data) {
            unlockedBadges = decoded
        } else {
            unlockedBadges = [:]
        }
    }

    private func saveShownCelebrations() {
        storage.set(Array(shownCelebrationIds), forKey: shownCelebrationsKey)
    }

    private func loadShownCelebrations() {
        let stored = storage.object(forKey: shownCelebrationsKey) as? [String] ?? []
        shownCelebrationIds = Set(stored)
    }
}
