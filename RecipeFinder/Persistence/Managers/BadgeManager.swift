import Foundation

@MainActor
final class BadgeManager: ObservableObject {
    static let shared = BadgeManager()

    @Published var unlockedBadges: [String: Badge] = [:]

    /// Non-nil when a badge celebration sheet should be shown. Set back to nil
    /// (via `dismissCelebration()`) when the sheet is dismissed; this drains the
    /// queue so back-to-back unlocks each get a moment.
    @Published private(set) var pendingCelebration: BadgeType?

    private let storage: UserScopedStorage
    private let badgesKey = "unlockedBadges"
    private let shownCelebrationsKey = "shownBadgeCelebrations"

    // FIFO queue: badges earned faster than the user can dismiss pile up here.
    private var celebrationQueue: [BadgeType] = []
    // Persisted set so the celebration never fires twice for the same badge,
    // even if the app is killed mid-sheet.
    private var shownCelebrationIds: Set<String> = []

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

    /// Faithful, non-destructive restore: unions incoming badges by id. On a key
    /// collision the currently-held badge wins, so this device's `dateEarned` is
    /// preserved rather than overwritten by the backup's. Restored badges never
    /// trigger celebration sheets — they were already earned elsewhere.
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

    func checkAndUnlockBadges(recipeCount: Int) {
        for badgeType in BadgeType.allCases {
            guard recipeCount >= badgeType.requiredCount,
                  !isBadgeUnlocked(badgeType.rawValue) else { continue }
            // welcomeAboard fires silently — a "you joined" pop mid-session
            // would be contextually confusing; the others are recipe-count wins.
            let silent = badgeType == .welcomeAboard
            unlockBadge(badgeType, silent: silent)
        }
    }

    /// Unlock a badge. Pass `silent: true` to persist the unlock without showing
    /// the celebration sheet (used for welcome/seed badges that fire at launch).
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

        guard !silent, !shownCelebrationIds.contains(badge.id) else { return }
        celebrationQueue.append(badgeType)
        drainQueueIfIdle()
    }

    /// Call this when the badge-earned sheet is dismissed to advance to the next
    /// queued celebration, if any.
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
        if let encoded = try? JSONEncoder().encode(unlockedBadges) {
            storage.set(encoded, forKey: badgesKey)
        }
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
