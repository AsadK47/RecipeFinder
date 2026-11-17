import Foundation

/// Copy for the recipe detail's timer button, cook-history card and facts card, kept pure so it is tested
/// (`RecipeDetailCopyTests`) rather than buried in view bodies.
enum RecipeDetailCopy {
    static func timerStartTitle(minutes: Int) -> String {
        minutes > 0 ? "Start \(minutes)-min timer" : "Start a timer"
    }

    static func timerStartHint(minutes: Int) -> String {
        minutes > 0 ? "Starts a \(minutes) minute timer" : "Start a cooking timer"
    }

    /// Hours and minutes for a one-tap timer from the recipe's cook time; nil → open the time picker instead.
    static func timerStart(minutes: Int) -> (hours: Int, minutes: Int)? {
        minutes > 0 ? (minutes / 60, minutes % 60) : nil
    }

    static func addedToGroceries(name: String) -> String {
        "\(name) added to Groceries"
    }

    static func addedToGroceries(count: Int) -> String {
        "\(count == 1 ? "1 ingredient" : "\(count) ingredients") added to Groceries"
    }

    static let reimportUnreadable = "Couldn't read a recipe from the original text"
    static let reimportUnchanged = "Already matches the original"

    static func cookCount(_ count: Int) -> String {
        count == 0 ? "Not cooked yet" : "Cooked \(count) \(count == 1 ? "time" : "times")"
    }

    /// You rate what you've made, not a recipe you've never tried.
    static func showsRating(cookCount: Int) -> Bool {
        cookCount > 0
    }

    /// "15 minutes" → "15 min" so four or five facts fit across one row.
    static func shortTime(_ display: String) -> String {
        display
            .replacingOccurrences(of: " minutes", with: " min")
            .replacingOccurrences(of: " minute", with: " min")
            .replacingOccurrences(of: " hours", with: " hr")
            .replacingOccurrences(of: " hour", with: " hr")
    }

    /// Prep, cook, difficulty, category — and cuisine when the recipe has one.
    static func facts(for recipe: RecipeModel) -> [RecipeFactText] {
        var facts = [
            RecipeFactText(kind: .prep, value: shortTime(recipe.prepTimeDisplay)),
            RecipeFactText(kind: .cook, value: shortTime(recipe.cookTimeDisplay)),
            RecipeFactText(kind: .difficulty, value: recipe.difficulty),
            RecipeFactText(kind: .category, value: recipe.category),
        ]
        if let cuisine = recipe.cuisine, !cuisine.isEmpty {
            facts.append(RecipeFactText(kind: .cuisine, value: cuisine))
        }
        return facts
    }

    /// Indices for the two-row layout: 4 facts → 2 + 2, 5 → 3 + 2 (times stay together on the first row).
    static func factRows(count: Int) -> [[Int]] {
        guard count > 0 else { return [] }
        let firstRow = (count + 1) / 2
        return [Array(0..<firstRow), Array(firstRow..<count)].filter { !$0.isEmpty }
    }
}

enum RecipeFactKind: Equatable, Sendable {
    case prep, cook, difficulty, category, cuisine

    var label: String {
        switch self {
        case .prep: "Prep"
        case .cook: "Cook"
        case .difficulty: "Difficulty"
        case .category: "Category"
        case .cuisine: "Cuisine"
        }
    }

    var icon: String {
        switch self {
        case .prep: "clock"
        case .cook: "flame"
        case .difficulty: "chart.bar"
        case .category: "fork.knife"
        case .cuisine: "globe"
        }
    }
}

struct RecipeFactText: Equatable, Identifiable, Sendable {
    let kind: RecipeFactKind
    let value: String
    var id: String { kind.label }
}
