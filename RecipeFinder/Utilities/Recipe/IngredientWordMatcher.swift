import Foundation

/// Whole-word matching for ingredient / keyword comparisons.
///
/// Extracted to kill a recurring bug class across the ingredient logic: plain
/// `String.contains` matched a keyword inside an unrelated word — "ham" in
/// "graham", "salt" in "salted butter", "corn" in "popcorn", "gin" in "ginger".
/// Matching here is word-boundary aware, supports multi-word keywords (which must
/// appear as a contiguous run of words), and treats simple English plurals
/// ("s" / "es") as equal so "onion" matches "onions".
///
/// Note it deliberately does *not* solve genuine whole-word collisions such as
/// "sugar snap peas" containing the real word "sugar" — that needs semantic, not
/// lexical, disambiguation.
enum IngredientWordMatcher {

    /// Whether `text` contains `keyword` as a run of whole words.
    static func matches(text: String, keyword: String) -> Bool {
        matches(textWords: words(in: text), keyword: keyword)
    }

    /// Overload for hot paths that tokenise `text` once and test many keywords
    /// against it (e.g. `CategoryClassifier.categorize`).
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

    /// Splits into lowercased words on any non-alphanumeric boundary, dropping
    /// punctuation and empties. Public so callers can tokenise once and reuse.
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
