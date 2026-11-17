import Foundation

/// One number on Me's stats strip: "12" over "dinners", read by VoiceOver as "12 dinners cooked".
struct MeStat: Identifiable, Equatable {
    enum Kind: String {
        case dinners, streak, cuisines
    }

    let kind: Kind
    let value: Int
    /// Short label under the number, singular or plural to match it.
    let label: String
    /// The whole stat as one phrase for VoiceOver.
    let spoken: String

    var id: Kind { kind }
}

/// Me's hero stats — dinners cooked · week streak · cuisines tried — from the same counts the badges use, so the
/// strip and the badge progress never disagree. Pure so the wording is pinned by tests.
enum MeStats {
    static func strip(recipes: [RecipeModel], streakWeeks: Int) -> [MeStat] {
        let metrics = BadgeMetrics.from(recipes: recipes, streakWeeks: streakWeeks)
        return strip(dinners: metrics.recipesCooked, streakWeeks: metrics.weeklyStreak,
                     cuisines: metrics.cuisinesCooked)
    }

    static func strip(dinners: Int, streakWeeks: Int, cuisines: Int) -> [MeStat] {
        let dinners = max(dinners, 0)
        let weeks = max(streakWeeks, 0)
        let cuisines = max(cuisines, 0)
        return [
            MeStat(kind: .dinners, value: dinners,
                   label: dinners == 1 ? "dinner" : "dinners",
                   spoken: dinners == 1 ? "1 dinner cooked" : "\(dinners) dinners cooked"),
            MeStat(kind: .streak, value: weeks,
                   label: "week streak",
                   spoken: weeks == 1 ? "1 week streak" : "\(weeks) week streak"),
            MeStat(kind: .cuisines, value: cuisines,
                   label: cuisines == 1 ? "cuisine" : "cuisines",
                   spoken: cuisines == 1 ? "1 cuisine tried" : "\(cuisines) cuisines tried"),
        ]
    }

    /// Before the first cook the strip would be three zeros; the hero shows this invitation instead.
    static func hasCooked(_ stats: [MeStat]) -> Bool {
        stats.contains { $0.kind == .dinners && $0.value > 0 }
    }

    /// "12 dinners cooked, 3 week streak, 4 cuisines tried" — the hero's VoiceOver value.
    static func spokenSummary(_ stats: [MeStat]) -> String {
        stats.map(\.spoken).joined(separator: ", ")
    }
}
