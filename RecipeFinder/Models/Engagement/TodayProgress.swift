import Foundation

/// Today's progress row: the weekly streak, cooks this week, and the cooking badge you're closest to.
/// Pure so the "which badge next" rule is testable; TodayView builds it on each data change.
struct TodayProgress: Equatable {
    struct NextBadge: Equatable {
        let type: BadgeType
        let current: Int
        let target: Int

        var remaining: Int { max(0, target - current) }

        /// "2 more cooks to Home Cook" — the unit says what to do, not just how far.
        var text: String {
            let unit: String
            switch type.criterion.metric {
            case .weeklyStreak: unit = remaining == 1 ? "week" : "weeks"
            case .cuisinesCooked: unit = remaining == 1 ? "cuisine" : "cuisines"
            case .recipesRated: unit = remaining == 1 ? "rating" : "ratings"
            case .cookPhotos: unit = remaining == 1 ? "cook photo" : "cook photos"
            case .recipesCollected: unit = remaining == 1 ? "recipe" : "recipes"
            // Only repeats of one dish count toward Signature Dish, so say so.
            case .sameRecipeCooked: unit = remaining == 1 ? "cook of one dish" : "cooks of one dish"
            case .recipesCooked, nil: unit = remaining == 1 ? "cook" : "cooks"
            }
            return "\(remaining) more \(unit) to \(type.badge.title)"
        }
    }

    let streakWeeks: Int
    let cooksThisWeek: Int
    /// The locked cooking badge with the most progress; nil once every cooking badge is earned.
    let nextBadge: NextBadge?

    /// Badges Today points at: the ones earned by cooking (library size is left to Me — Today rewards cooking).
    static let cookingMetrics: Set<BadgeMetric> = [
        .recipesCooked, .weeklyStreak, .cuisinesCooked, .sameRecipeCooked, .recipesRated, .cookPhotos,
    ]

    static func make(recipes: [RecipeModel], streak: CookingStreak, unlockedBadgeIDs: Set<String>) -> TodayProgress {
        let metrics = BadgeMetrics.from(recipes: recipes, streakWeeks: streak.currentWeeks)
        return TodayProgress(
            streakWeeks: streak.currentWeeks,
            cooksThisWeek: streak.cooksThisWeek,
            nextBadge: nextBadge(metrics: metrics, unlockedBadgeIDs: unlockedBadgeIDs)
        )
    }

    /// Closest first (highest share done), then fewest left, then the badge list's own order.
    private static func nextBadge(metrics: BadgeMetrics, unlockedBadgeIDs: Set<String>) -> NextBadge? {
        let candidates = BadgeType.allCases.enumerated().compactMap { index, type -> (NextBadge, Int)? in
            guard let metric = type.criterion.metric, cookingMetrics.contains(metric),
                  !unlockedBadgeIDs.contains(type.rawValue),
                  let progress = type.progress(for: metrics), progress.current < progress.target else { return nil }
            return (NextBadge(type: type, current: progress.current, target: progress.target), index)
        }
        return candidates.min { a, b in
            // Cross-multiplied so 1/2 vs 2/4 tie exactly (no floating point).
            let left = a.0.current * b.0.target, right = b.0.current * a.0.target
            if left != right { return left > right }
            if a.0.remaining != b.0.remaining { return a.0.remaining < b.0.remaining }
            return a.1 < b.1
        }?.0
    }
}

/// "Try something new": one recipe you've never cooked, the same all week, a different one next week.
enum TrySomethingNew {
    /// Your own uncooked recipes come before samples (you saved them to cook them). Within that pool each recipe
    /// gets a stable score from the week + its id, and the lowest wins — so the pick holds all week, across launches
    /// and list orders, and adding a recipe only changes it if the new one happens to score lower.
    static func pick(recipes: [RecipeModel], now: Date = Date(), calendar: Calendar = .current) -> RecipeModel? {
        let uncooked = recipes.filter { $0.cookCount == 0 && $0.lastCookedAt == nil }
        let own = uncooked.filter { !$0.isSampleRecipe }
        let pool = own.isEmpty ? uncooked : own
        let week = weekKey(now, calendar: calendar)
        return pool.min { a, b in
            let left = score(week, a.id), right = score(week, b.id)
            return left != right ? left < right : a.id.uuidString < b.id.uuidString
        }
    }

    /// The week's start as "yyyy-mm-dd" (numbers, not a formatted string, so locale can't change it).
    static func weekKey(_ date: Date, calendar: Calendar) -> String {
        let start = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        return "\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
    }

    /// FNV-1a: Swift's `hashValue` is seeded per launch, which would reshuffle the pick every time the app opens.
    private static func score(_ week: String, _ id: UUID) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in "\(week)|\(id.uuidString)".utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return hash
    }
}
