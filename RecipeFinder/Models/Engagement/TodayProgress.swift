import Foundation

/// Today's progress row: the weekly streak, cooks this week, and the cooking badge you're closest to.
/// Pure so the "which badge next" rule is testable; TodayView builds it on each data change.
struct TodayProgress: Equatable {
    struct NextBadge: Equatable {
        let type: BadgeType
        let current: Int
        let target: Int

        /// VoiceOver reads "4 of 5", not the "4 / 5" shown under the bar.
        var spokenText: String { "\(text), \(current) of \(target)" }

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

    /// The badge row opens Me's trophy shelf on this badge's card; no row (nil) once every cooking badge is earned.
    var badgeShelfRequest: TrophyShelfRequest? { nextBadge.map { TrophyShelfRequest(badgeID: $0.type.rawValue) } }

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

    /// Closest first — the same ranking as Me's "Next up", limited to the cooking badges.
    private static func nextBadge(metrics: BadgeMetrics, unlockedBadgeIDs: Set<String>) -> NextBadge? {
        guard let type = BadgeType.closest(
            metrics: metrics, unlockedBadgeIDs: unlockedBadgeIDs, among: cookingMetrics, limit: 1
        ).first, let progress = type.progress(for: metrics) else { return nil }
        return NextBadge(type: type, current: progress.current, target: progress.target)
    }
}

/// Asks Me to show the trophy shelf (Profile), opening one badge's card when `badgeID` is set.
struct TrophyShelfRequest: Equatable {
    let badgeID: String?
}
