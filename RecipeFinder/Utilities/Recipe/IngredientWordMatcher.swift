import Foundation

/// Word-boundary-aware ingredient/keyword matching to kill the `String.contains` bug class ("ham" in "graham", "gin" in "ginger"); supports contiguous multi-word keywords and simple s/es plurals. Does NOT resolve semantic collisions like "sugar" in "sugar snap peas".
enum IngredientWordMatcher {

    /// Whether `text` contains `keyword` as a run of whole words.
    static func matches(text: String, keyword: String) -> Bool {
        matches(textWords: words(in: text), keyword: keyword)
    }

    /// Hot-path overload: tokenise `text` once, test many keywords against it (e.g. `CategoryClassifier.categorize`).
    static func matches(textWords: [String], keyword: String) -> Bool {
        let keywordWords = words(in: keyword)
        guard !keywordWords.isEmpty, keywordWords.count <= textWords.count else {
            return false
        }

        // Slide the keyword's word-sequence across the text's words.
        let window = keywordWords.count
        for start in 0...(textWords.count - window) {
            let matched = (0..<window).allSatisfy { offset in
                wordsEqual(textWords[start + offset], keywordWords[offset])
            }
            if matched { return true }
        }
        return false
    }

    /// Lowercased words split on non-alphanumeric boundaries; public so callers can tokenise once and reuse.
    static func words(in term: String) -> [String] {
        term.lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
    }

    /// Two words are equal ignoring a trailing simple English plural on either side.
    private static func wordsEqual(_ a: String, _ b: String) -> Bool {
        a == b || isPlural(a, of: b) || isPlural(b, of: a)
    }

    /// Whether `plural` is `singular` with an "s" / "es" suffix.
    private static func isPlural(_ plural: String, of singular: String) -> Bool {
        plural == singular + "s" || plural == singular + "es"
    }
}
