import Foundation

/// Which ingredients a cooking step uses, read from the step's words — so cooking mode can show each step's
/// ingredients with their amounts. Precision over recall: a wrong ingredient on a step misleads the cook more
/// than a missing one, so matches need whole words and a generic head word ("sauce") never matches alone.
enum StepIngredientMatcher {

    /// Head words too generic to stand for one ingredient ("the sauce" with soy and fish sauce in the recipe).
    private static let genericHeadWords: Set<String> = [
        "powder", "sauce", "paste", "seeds", "seed", "leaves", "leaf", "extract", "juice", "zest", "mix",
        "stock", "cloves", "clove", "flakes", "water"
    ]

    /// Indices into `ingredients` of those the step names, in recipe order, each once.
    static func indices(usedIn step: String, from ingredients: [Ingredient]) -> [Int] {
        let text = step.lowercased()
        guard text.contains(where: \.isLetter) else { return [] }
        let whole = NSRange(text.startIndex..., in: text)
        let words = ingredients.map { IngredientNameFormatter.matchKey($0.name).split(separator: " ").map(String.init) }

        // Pass 1: full names. Their spans are claimed, so "sesame oil" doesn't also count as another "… oil".
        var used = Set<Int>()
        var claimed: [NSRange] = []
        for (i, key) in words.enumerated() where key.contains(where: { $0.contains(where: \.isLetter) }) {
            let ranges = matches(of: key, in: text, range: whole)
            if !ranges.isEmpty {
                used.insert(i)
                claimed += ranges
            }
        }

        // Pass 2: the head (last) word of a longer name — "the onion" for "red onion" — outside claimed spans.
        for (i, key) in words.enumerated() where !used.contains(i) && key.count > 1 {
            guard let head = key.last, head.count >= 3, !genericHeadWords.contains(head) else { continue }
            let free = matches(of: [head], in: text, range: whole).contains { range in
                !claimed.contains { NSIntersectionRange($0, range).length > 0 }
            }
            if free { used.insert(i) }
        }
        return used.sorted()
    }

    /// Whole-word ranges where the phrase appears, its last word in singular or plural form.
    private static func matches(of phrase: [String], in text: String, range: NSRange) -> [NSRange] {
        guard let last = phrase.last else { return [] }
        let leading = phrase.dropLast().map(NSRegularExpression.escapedPattern(for:))
        let pattern = #"\b"# + (leading + [pluralPattern(last)]).joined(separator: #"\s+"#) + #"\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return [] }
        return regex.matches(in: text, range: range).map(\.range)
    }

    /// "egg"/"eggs" → `egg(?:s|es)?`, "tomatoes" → `tomato(?:s|es)?`, "berry"/"berries" → `berr(?:y|ies)`.
    private static func pluralPattern(_ word: String) -> String {
        let vowels: Set<Character> = ["a", "e", "i", "o", "u"]
        if word.hasSuffix("ies"), word.count > 4 {
            return NSRegularExpression.escapedPattern(for: String(word.dropLast(3))) + "(?:y|ies)"
        }
        if word.hasSuffix("y"), word.count > 2, let before = word.dropLast().last, !vowels.contains(before) {
            return NSRegularExpression.escapedPattern(for: String(word.dropLast())) + "(?:y|ies)"
        }
        var stem = word
        if word.hasSuffix("oes"), word.count > 4 {
            stem = String(word.dropLast(2))
        } else if word.hasSuffix("s"), !word.hasSuffix("ss"), word.count > 3 {
            stem = String(word.dropLast())
        }
        return NSRegularExpression.escapedPattern(for: stem) + "(?:s|es)?"
    }
}

extension CookingPlan {
    /// For each item, the indices of the ingredients it uses (none for the ingredient list). Compute once per cook.
    func ingredientIndices(from ingredients: [Ingredient]) -> [[Int]] {
        items.map { item in
            item.isIngredientList ? [] : StepIngredientMatcher.indices(usedIn: item.displayText, from: ingredients)
        }
    }
}
