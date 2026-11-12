import Foundation

/// The trophy-shelf rows on Me. Order is the shelf order.
enum BadgeGroup: String, CaseIterable, Identifiable {
    case cooking, streaks, importing, planning

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cooking: "Cooking"
        case .streaks: "Streaks"
        case .importing: "Importing"
        case .planning: "Planning"
        }
    }

    var icon: String {
        switch self {
        case .cooking: "frying.pan.fill"
        case .streaks: "flame.fill"
        case .importing: "square.and.arrow.down.fill"
        case .planning: "calendar"
        }
    }
}

/// Where a locked badge's "earn it here" button takes you.
enum BadgeEarnAction: Equatable {
    case cook, rate, addRecipe, plan, groceries

    var title: String {
        switch self {
        case .cook: "Pick something to cook"
        case .rate: "Open your recipes"
        case .addRecipe: "Go to Recipes and tap +"
        case .plan: "Open Plan"
        case .groceries: "Open Groceries"
        }
    }

    var icon: String {
        switch self {
        case .cook: "frying.pan.fill"
        case .rate: "book.fill"
        case .addRecipe: "plus"
        case .plan: "calendar"
        case .groceries: "cart.fill"
        }
    }

    /// Posted once the pager has closed; ContentView switches to `tab`.
    var notification: Notification.Name {
        switch self {
        case .cook: .openToday
        case .rate, .addRecipe: .openRecipes
        case .plan: .openMealPlan
        case .groceries: .openGroceries
        }
    }

}

extension BadgeMetric {
    /// The noun after "7 / 10" on a locked badge.
    var unit: String {
        switch self {
        case .recipesCollected: "recipes"
        case .recipesCooked: "cooks"
        case .weeklyStreak: "weeks"
        case .cuisinesCooked: "cuisines"
        case .sameRecipeCooked: "cooks of one dish"
        case .recipesRated: "rated"
        case .cookPhotos: "photos"
        }
    }
}

extension BadgeType {
    var group: BadgeGroup {
        switch criterion.metric {
        case .recipesCooked, .cuisinesCooked, .sameRecipeCooked, .recipesRated, .cookPhotos: return .cooking
        case .weeklyStreak: return .streaks
        case .recipesCollected: return .importing
        case nil:
            switch self {
            case .mealPlanner, .shoppingExpert: return .planning
            case .firstImport, .firstPhotoImport: return .importing
            case .welcomeAboard, .firstRecipe, .fiveRecipes, .tenRecipes, .twentyFiveRecipes, .fiftyRecipes,
                 .hundredRecipes, .headChef, .cookedTen, .cookedTwentyFive, .cookedFifty, .cookedHundred,
                 .streakTwoWeeks, .streakFourWeeks, .streakTwelveWeeks, .streakFiftyTwoWeeks, .cuisinesFive,
                 .sameRecipeFive, .ratedTen, .firstCookPhoto:
                // Threshold badges are grouped by metric above; a new event badge must pick its row here.
                return .importing
            }
        }
    }

    /// nil for Welcome Aboard — it's earned by opening the app.
    var earnAction: BadgeEarnAction? {
        switch self {
        case .welcomeAboard: return nil
        case .mealPlanner: return .plan
        case .shoppingExpert: return .groceries
        case .firstImport, .firstPhotoImport: return .addRecipe
        default:
            switch criterion.metric {
            case .recipesRated, .cookPhotos: return .rate
            case .recipesCollected: return .addRecipe
            default: return .cook
            }
        }
    }

    /// "7 / 10 cooks"; nil for one-off badges.
    func progressText(for metrics: BadgeMetrics) -> String? {
        guard let metric = criterion.metric, let progress = progress(for: metrics) else { return nil }
        return "\(progress.current) / \(progress.target) \(metric.unit)"
    }

    /// Share done, 0…1, for the ring; nil for one-off badges.
    func progressFraction(for metrics: BadgeMetrics) -> Double? {
        guard let progress = progress(for: metrics) else { return nil }
        return Double(progress.current) / Double(progress.target)
    }
}

/// One shelf row: a group's badges, newest earned first, then the locked ones in the order you'd earn them.
struct BadgeShelfSection: Identifiable {
    let group: BadgeGroup
    let badges: [Badge]

    var id: String { group.id }
    var earnedCount: Int { badges.filter(\.isUnlocked).count }
    var total: Int { badges.count }
    var countText: String { "\(earnedCount) / \(total)" }
}

enum BadgeShelf {
    /// `badges` = every badge, earned ones as stored (with their date). Ids that are no longer a `BadgeType` are dropped.
    static func sections(_ badges: [Badge]) -> [BadgeShelfSection] {
        let byID = Dictionary(badges.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return BadgeGroup.allCases.map { group in
            let inGroup = BadgeType.allCases.enumerated()
                .filter { $0.element.group == group }
                .map { (order: $0.offset, badge: byID[$0.element.rawValue] ?? $0.element.badge) }
            let earned = inGroup.filter { $0.badge.isUnlocked }.sorted { lhs, rhs in
                switch (lhs.badge.dateEarned, rhs.badge.dateEarned) {
                case let (l?, r?) where l != r: return l > r
                case (.some, nil): return true
                case (nil, .some): return false
                default: return lhs.order < rhs.order
                }
            }
            let locked = inGroup.filter { !$0.badge.isUnlocked }
            return BadgeShelfSection(group: group, badges: (earned + locked).map { $0.badge })
        }
    }

    /// Swipe order of the full-screen badge pager: the shelf, row by row.
    static func pagerOrder(_ sections: [BadgeShelfSection]) -> [Badge] {
        sections.flatMap(\.badges)
    }

    static func startIndex(of badgeID: String, in pager: [Badge]) -> Int {
        pager.firstIndex { $0.id == badgeID } ?? 0
    }

    /// VoiceOver reads "/" as "slash".
    static func spokenCount(_ sections: [BadgeShelfSection]) -> String {
        "\(sections.reduce(0) { $0 + $1.earnedCount }) of \(sections.reduce(0) { $0 + $1.total }) badges earned"
    }

    static func countText(_ sections: [BadgeShelfSection]) -> String {
        "\(sections.reduce(0) { $0 + $1.earnedCount }) / \(sections.reduce(0) { $0 + $1.total })"
    }
}
