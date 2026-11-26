import Foundation

/// The app's three difficulty levels, easiest first. Recipes store the raw value; free text from imports and older
/// recipes is read through `init(parsing:)` — the one parser the editor, filters, Easy recipes and the bars share.
enum Difficulty: String, CaseIterable, Sendable {
    case basic = "Basic"
    case intermediate = "Intermediate"
    case expert = "Expert"

    private static let levelWords: [String: Difficulty] = [
        "easy": .basic, "basic": .basic, "beginner": .basic, "beginners": .basic, "simple": .basic,
        "medium": .intermediate, "moderate": .intermediate, "intermediate": .intermediate,
        "hard": .expert, "expert": .expert, "advanced": .expert, "difficult": .expert, "challenging": .expert
    ]
    private static let negations: Set<String> = ["not", "no", "never", "isn", "isnt"]
    /// Words that can sit between a negation and its level ("not too hard").
    private static let softeners: Set<String> = ["too", "very", "so", "that", "overly", "really", "particularly", "t"]

    /// Reads a free-text label by whole word: "uneasy" or "hardboiled" mention no level; a negated level moves one
    /// step towards the middle ("not easy", "not too hard" → Intermediate); a range lands on its middle, rounding
    /// towards the easier end ("easy–medium" → Basic, "medium-hard" → Intermediate) so the order of words never
    /// matters. No level word → Intermediate, the middle the bars and filters already show for unknown text.
    init(parsing raw: String) {
        let words = raw.lowercased().split { !$0.isLetter }.map(String.init)
        var found: [Int] = []
        for (index, word) in words.enumerated() {
            guard let level = Self.levelWords[word], let position = Self.allCases.firstIndex(of: level) else { continue }
            found.append(Self.isNegated(words, before: index) ? Self.towardsMiddle(position) : position)
        }
        guard let lowest = found.min(), let highest = found.max() else {
            self = .intermediate
            return
        }
        self = Self.allCases[(lowest + highest) / 2]
    }

    private static func isNegated(_ words: [String], before index: Int) -> Bool {
        var cursor = index - 1
        while cursor >= 0, softeners.contains(words[cursor]) { cursor -= 1 }
        return cursor >= 0 && negations.contains(words[cursor])
    }

    private static func towardsMiddle(_ position: Int) -> Int {
        let middle = allCases.count / 2
        return position < middle ? position + 1 : (position > middle ? position - 1 : position)
    }
}
