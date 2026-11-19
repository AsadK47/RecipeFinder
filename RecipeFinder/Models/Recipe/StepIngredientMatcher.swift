import Foundation

/// Which ingredients a cooking step uses, read from the step's words — so cooking mode can show each step's
/// ingredients. Precision over recall: a wrong ingredient on a step misleads the cook more than a missing one.
/// Checked against the 332 bundled recipes (a Python port), not only hand-made lines.
enum StepIngredientMatcher {

    /// One ingredient a step uses. `stepGivesAmount` when the step states its own amount ("1 tbsp oil", "the
    /// remaining oil") — the recipe's total amount would then be wrong for this step.
    struct Use: Equatable {
        let index: Int
        let stepGivesAmount: Bool
    }

    /// Head words too generic to stand for one ingredient ("the sauce" with soy and fish sauce in the recipe).
    private static let genericHeadWords: Set<String> = [
        "powder", "sauce", "paste", "seeds", "seed", "leaves", "leaf", "extract", "juice", "zest", "mix",
        "stock", "cloves", "clove", "flakes", "water"
    ]
    /// Cut or form words: "chicken breast" is "the chicken" in a step, "cinnamon stick" is "the cinnamon".
    private static let cutWords: Set<String> = [
        "breast", "breasts", "thigh", "thighs", "fillet", "fillets", "mince", "drumsticks", "wings", "legs", "stick",
        "sticks", "pod", "pods", "bulb", "cube", "cubes"
    ]
    /// A word after a match that makes it a different ingredient: "garlic powder", "pepper flakes", "tomato paste".
    private static let compoundWords: Set<String> = [
        "powder", "sauce", "paste", "flakes", "extract", "juice", "zest", "stock", "seeds", "seed", "oil", "milk",
        "chives", "vinegar", "purée", "puree"
    ]
    /// Words that mean the ingredient isn't used: "without oil", "no salt".
    private static let negations: Set<String> = ["without", "no"]
    /// Words before a match that mean the step sets its own amount ("half the butter", "a few curry leaves").
    private static let partialAmountWords: Set<String> = [
        "half", "remaining", "rest", "more", "extra", "some", "few", "little", "handful", "pinch", "splash",
        "dash"
    ]

    private struct Candidate {
        let words: [String]
        let isFullName: Bool
        let index: Int
    }

    /// The ingredients the step names, in recipe order, each once.
    static func uses(in step: String, from ingredients: [Ingredient]) -> [Use] {
        let text = step.lowercased()
        guard text.contains(where: \.isLetter) else { return [] }
        let keys = ingredients.map { IngredientNameFormatter.matchKey($0.name).split(separator: " ").map(String.init) }
        // The last word of every ingredient name: "garlic cloves" is garlic, so "cloves" there isn't the spice.
        let nameEnds = Set(keys.compactMap(\.last))

        // Longest phrase first, full names before partial ones; each tier claims its spans before the next, so
        // "sesame oil" and "spring onions" aren't also read as the plain oil or onion.
        let candidates = keys.enumerated().flatMap { i, key in self.candidates(for: key, index: i) }
            .sorted { ($0.words.count, $0.isFullName ? 1 : 0) > ($1.words.count, $1.isFullName ? 1 : 0) }
        var claimed: [Range<String.Index>] = []
        var found: [Int: Bool] = [:]
        var tierStart = candidates.startIndex
        while tierStart < candidates.endIndex {
            let tier = (candidates[tierStart].words.count, candidates[tierStart].isFullName)
            let tierEnd = candidates[tierStart...].firstIndex { ($0.words.count, $0.isFullName) != tier }
                ?? candidates.endIndex
            var tierClaims: [Range<String.Index>] = []
            for candidate in candidates[tierStart..<tierEnd] where found[candidate.index] == nil {
                let hit = ranges(of: candidate.words, in: text).first { range in
                    !claimed.contains { $0.overlaps(range) }
                        && !compoundWords.contains(word(after: range, in: text) ?? "")
                        && !isNegatedOrCompound(range, in: text, phraseLength: candidate.words.count, nameEnds: nameEnds)
                }
                guard let hit else { continue }
                found[candidate.index] = stepGivesAmount(before: hit, in: text)
                tierClaims.append(hit)
            }
            claimed += tierClaims
            tierStart = tierEnd
        }
        return found.keys.sorted().map { Use(index: $0, stepGivesAmount: found[$0] ?? false) }
    }

    /// Phrases that may stand for an ingredient: its full name (each side of an "or"), its last two words
    /// ("light soy sauce" → "soy sauce"), its head word ("red onion" → "onion") unless that's generic, and the
    /// word before a cut ("chicken breast" → "chicken").
    private static func candidates(for key: [String], index: Int) -> [Candidate] {
        var alternatives = key.split(separator: "or").map(Array.init)
        // "white or rice vinegar" means white vinegar, not anything "white".
        if let last = alternatives.last, let head = last.last, alternatives.count > 1 {
            alternatives = alternatives.dropLast().map { $0.count < last.count ? $0 + [head] : $0 } + [last]
        }
        return alternatives.flatMap { words -> [Candidate] in
            guard words.contains(where: { $0.contains(where: \.isLetter) }) else { return [] }
            var list = [Candidate(words: words, isFullName: true, index: index)]
            if words.count >= 3 { list.append(Candidate(words: Array(words.suffix(2)), isFullName: false, index: index)) }
            if words.count >= 2, let head = words.last, head.count >= 3, !genericHeadWords.contains(head) {
                list.append(Candidate(words: [head], isFullName: false, index: index))
            }
            if words.count >= 2, let head = words.last, cutWords.contains(head), words[words.count - 2].count >= 3 {
                list.append(Candidate(words: [words[words.count - 2]], isFullName: false, index: index))
            }
            return list
        }
    }

    /// "without oil" / "no salt", or a one-word match that ends another ingredient's name ("garlic cloves").
    private static func isNegatedOrCompound(_ range: Range<String.Index>, in text: String, phraseLength: Int,
                                            nameEnds: Set<String>) -> Bool {
        guard let previous = wordsBefore(range, in: text).last else { return false }
        return negations.contains(previous) || (phraseLength == 1 && nameEnds.contains(previous))
    }

    private static func stepGivesAmount(before range: Range<String.Index>, in text: String) -> Bool {
        wordsBefore(range, in: text).contains { word in
            partialAmountWords.contains(word) || word.contains(where: { $0.isNumber || "½¼¾⅓⅔".contains($0) })
        }
    }

    /// Up to four words before the match, within its clause (stops at , . ; : and brackets).
    private static func wordsBefore(_ range: Range<String.Index>, in text: String) -> [String] {
        let clause = text[..<range.lowerBound].split(omittingEmptySubsequences: false) { ",.;:()".contains($0) }.last
        return (clause ?? "").split(whereSeparator: \.isWhitespace).suffix(4).map(String.init)
    }

    private static func word(after range: Range<String.Index>, in text: String) -> String? {
        let rest = text[range.upperBound...]
        guard rest.first?.isWhitespace == true else { return nil }
        let word = rest.drop(while: \.isWhitespace).prefix(while: \.isLetter)
        return word.isEmpty ? nil : String(word)
    }

    /// Whole-word ranges where the phrase appears, its last word in singular or plural form.
    private static func ranges(of phrase: [String], in text: String) -> [Range<String.Index>] {
        guard let last = phrase.last else { return [] }
        let leading = phrase.dropLast().map(NSRegularExpression.escapedPattern(for:))
        let pattern = #"\b"# + (leading + ["(?:" + pluralPattern(last) + ")"]).joined(separator: #"\s+"#) + #"\b"#
        // Every word is escaped, so the pattern always compiles; nil would only mean no match.
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return [] }
        return regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            .compactMap { Range($0.range, in: text) }
    }

    /// "egg"/"eggs" → `egg(?:s|es)?`, "tomatoes"/"peaches" → `tomato…`/`peach(?:s|es)?`, "berry"/"berries" →
    /// `berr(?:y|ies)`, "chilli"/"chillies" match each other.
    private static func pluralPattern(_ word: String) -> String {
        let vowels: Set<Character> = ["a", "e", "i", "o", "u"]
        let escaped = NSRegularExpression.escapedPattern(for:)
        if word.hasSuffix("ies"), word.count > 4 { return escaped(String(word.dropLast(3))) + "(?:y|ies|i|is)" }
        if word.hasSuffix("y"), word.count > 2, let before = word.dropLast().last, !vowels.contains(before) {
            return escaped(String(word.dropLast())) + "(?:y|ies)"
        }
        if word.hasSuffix("i"), word.count > 3 { return escaped(word) + "(?:s|es)?|" + escaped(String(word.dropLast())) + "ies" }
        var stem = word
        if ["oes", "ches", "shes", "xes", "sses"].contains(where: { word.hasSuffix($0) }), word.count > 4 {
            stem = String(word.dropLast(2))
        } else if word.hasSuffix("s"), !word.hasSuffix("ss"), word.count > 3 {
            stem = String(word.dropLast())
        }
        return escaped(stem) + "(?:s|es)?"
    }
}

extension CookingPlan {
    /// For each item, the ingredients it uses (none for the ingredient list). Compute once per cook.
    func ingredientUses(from ingredients: [Ingredient]) -> [[StepIngredientMatcher.Use]] {
        items.map { item in
            item.isIngredientList ? [] : StepIngredientMatcher.uses(in: item.displayText, from: ingredients)
        }
    }
}
