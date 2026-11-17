import Foundation

/// Copy for the recipe detail's timer button and cook-history card, kept pure so it is tested
/// (`RecipeDetailCopyTests`) rather than buried in view bodies.
enum RecipeDetailCopy {
    static func timerStartTitle(minutes: Int) -> String {
        minutes > 0 ? "Start \(minutes)-min timer" : "Start a timer"
    }

    static func timerStartHint(minutes: Int) -> String {
        minutes > 0 ? "Starts a \(minutes) minute timer" : "Start a cooking timer"
    }

    static func cookCount(_ count: Int) -> String {
        count == 0 ? "Not cooked yet" : "Cooked \(count) \(count == 1 ? "time" : "times")"
    }

    /// You rate what you've made, not a recipe you've never tried.
    static func showsRating(cookCount: Int) -> Bool {
        cookCount > 0
    }
}
