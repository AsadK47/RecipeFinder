import Foundation

@MainActor
final class BadgeManager: ObservableObject {
    static let shared = BadgeManager()

    @Published var unlockedBadges: [String: Badge] = [:]

    private let storage: UserScopedStorage
    private let badgesKey = "unlockedBadges"

    private init() {
        self.storage = .shared
        loadBadges()
    }

    init(storage: UserScopedStorage) {
        self.storage = storage
        loadBadges()
    }

    func reloadForCurrentUser() {
        loadBadges()
    }

    /// Faithful, non-destructive restore: unions incoming badges by id. On a key
    /// collision the currently-held badge wins, so this device's `dateEarned` is
    /// preserved rather than overwritten by the backup's.
    func merge(_ incoming: [String: Badge]) {
        unlockedBadges = BackupMerge.mergedBadges(existing: unlockedBadges, incoming: incoming)
        saveBadges()
    }

    func checkAndUnlockBadges(recipeCount: Int) {
        for badgeType in BadgeType.allCases {
            if recipeCount >= badgeType.requiredCount && !isBadgeUnlocked(badgeType.rawValue) {
                unlockBadge(badgeType)
            }
        }
    }

    func unlockBadge(_ badgeType: BadgeType, customDate: Date? = nil) {
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
    }

    func isBadgeUnlocked(_ badgeId: String) -> Bool {
        unlockedBadges[badgeId] != nil
    }

    func getAllBadges(recipeCount: Int) -> [Badge] {
        BadgeType.allCases.map { unlockedBadges[$0.rawValue] ?? $0.badge }
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
}
