import Foundation

/// The app's three difficulty levels, easiest first. Recipes store the raw value; free text from imports, shared
/// files and older recipes is read through `init(parsing:)` — the one parser the importer, editor, filters, Easy
/// recipes and the bars share.
enum Difficulty: String, CaseIterable, Sendable {
    case basic = "Basic"
    case intermediate = "Intermediate"
    case expert = "Expert"

    /// Level words → position in `allCases`.
    private static let levelWords: [String: Int] = [
        "easy": 0, "easier": 0, "easiest": 0, "basic": 0, "beginner": 0, "beginners": 0, "simple": 0, "simplest": 0,
        "medium": 1, "moderate": 1, "intermediate": 1,
        "hard": 2, "harder": 2, "hardest": 2, "expert": 2, "advanced": 2, "difficult": 2, "challenging": 2,
        "challenge": 2, "tricky": 2, "trickier": 2
    ]
    private static let negations: Set<String> = ["not", "no", "never", "isn", "isnt"]
    /// Words that can sit between a negation and its level ("not too hard", "not for beginners").
    private static let softeners: Set<String> = [
        "too", "very", "so", "that", "overly", "really", "particularly", "exactly", "at", "all", "a", "the",
        "for", "suitable", "t"
    ]

    /// Reads a free-text label by whole word: "uneasy" or "hardboiled" mention no level; a negated level means the
    /// middle ("not easy", "not too hard", "not for beginners" → Intermediate — the safe claim either way); a range
    /// lands on its middle, rounding towards the easier end ("easy–medium" → Basic, "medium-hard" → Intermediate),
    /// so word order never matters. No level word → Intermediate, the middle the bars already show for unknown text.
    init(parsing raw: String) {
        let words = Self.words(raw)
        var found: [Int] = []
        for (index, word) in words.enumerated() {
            guard let position = Self.levelWords[word] else { continue }
            found.append(Self.isNegated(words, before: index) ? 1 : position)
        }
        guard let lowest = found.min(), let highest = found.max() else {
            self = .intermediate
            return
        }
        self = Self.allCases[(lowest + highest) / 2]
    }

    /// Whether the text names a level at all — the importer keeps a "Difficulty:" label only when it does.
    static func mentionsLevel(_ raw: String) -> Bool {
        words(raw).contains { levelWords[$0] != nil }
    }

    private static func words(_ raw: String) -> [String] {
        raw.lowercased().split { !$0.isLetter }.map(String.init)
    }

    private static func isNegated(_ words: [String], before index: Int) -> Bool {
        var cursor = index - 1
        while cursor >= 0, softeners.contains(words[cursor]) { cursor -= 1 }
        return cursor >= 0 && negations.contains(words[cursor])
    }
}
