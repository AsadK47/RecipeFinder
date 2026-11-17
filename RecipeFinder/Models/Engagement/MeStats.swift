import Foundation

/// One number on Me's stats strip: "12" over "meals", read by VoiceOver as "12 meals cooked".
struct MeStat: Identifiable, Equatable {
    enum Kind: String {
        case meals, streak, cuisines
    }

    let kind: Kind
    let value: Int
    /// Short label under the number, singular or plural to match it.
    let label: String
    /// The whole stat as one phrase for VoiceOver.
    let spoken: String

    var id: Kind { kind }
}

/// Me's hero stats — meals cooked · week streak · cuisines tried — from the same counts the badges use, so the
/// strip and the badge progress never disagree. "Meals", not "dinners": every cook counts,
/// desserts and lunches too. Pure so the wording is pinned by tests.
enum MeStats {
    static func strip(recipes: [RecipeModel], streakWeeks: Int) -> [MeStat] {
        let metrics = BadgeMetrics.from(recipes: recipes, streakWeeks: streakWeeks)
        return strip(meals: metrics.recipesCooked, streakWeeks: metrics.weeklyStreak,
                     cuisines: metrics.cuisinesCooked)
    }

    static func strip(meals: Int, streakWeeks: Int, cuisines: Int) -> [MeStat] {
        let meals = max(meals, 0)
        let weeks = max(streakWeeks, 0)
        let cuisines = max(cuisines, 0)
        return [
            MeStat(kind: .meals, value: meals,
                   label: meals == 1 ? "meal" : "meals",
                   spoken: meals == 1 ? "1 meal cooked" : "\(meals) meals cooked"),
            MeStat(kind: .streak, value: weeks,
                   label: "week streak",
                   spoken: weeks == 1 ? "1 week streak" : "\(weeks) week streak"),
            MeStat(kind: .cuisines, value: cuisines,
                   label: cuisines == 1 ? "cuisine" : "cuisines",
                   spoken: cuisines == 1 ? "1 cuisine tried" : "\(cuisines) cuisines tried"),
        ]
    }

    /// All zeros (a new cook) → the hero shows an invitation instead. Any number counts: the streak comes from the cook
    /// log, which keeps a deleted recipe's cooks, so it can be live while the meal count is 0.
    static func hasCooked(_ stats: [MeStat]) -> Bool {
        stats.contains { $0.value > 0 }
    }

    /// "12 meals cooked, 3 week streak, 4 cuisines tried" — the hero's VoiceOver value.
    static func spokenSummary(_ stats: [MeStat]) -> String {
        stats.map(\.spoken).joined(separator: ", ")
    }
}
