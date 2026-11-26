import Foundation

/// Pure, testable model of a cooking-mode session: the ordered items (ingredient list → pre-prep → steps)
/// and every index-derived value the view renders — progress fraction, "Step N of M", first/last. Keeping the
/// off-by-one-prone arithmetic here (not trapped in `CookingModeView`'s private computed properties) means it
/// can be unit-tested directly.
struct CookingPlan: Equatable {
    enum Item: Equatable {
        case ingredientList
        case prePrep(index: Int, text: String)
        case step(index: Int, text: String)

        var isIngredientList: Bool {
            if case .ingredientList = self { return true }
            return false
        }

        var displayText: String {
            switch self {
            case .ingredientList:       return ""
            case .prePrep(_, let text): return text
            case .step(_, let text):    return text
            }
        }
    }

    let items: [Item]
    private let prePrepCount: Int
    private let stepCount: Int

    init(prePrep: [String], steps: [String]) {
        var items: [Item] = [.ingredientList]
        for (i, text) in prePrep.enumerated() { items.append(.prePrep(index: i, text: text)) }
        for (i, text) in steps.enumerated() { items.append(.step(index: i, text: text)) }
        self.items = items
        self.prePrepCount = prePrep.count
        self.stepCount = steps.count
    }

    var count: Int { items.count }

    func isFirst(_ index: Int) -> Bool { index == 0 }
    func isLast(_ index: Int) -> Bool { index == count - 1 }

    /// Fraction complete for the progress bar: item `index` (0-based) counts as done, so index 0 of N → 1/N.
    func progress(_ index: Int) -> Double {
        guard count > 0 else { return 0 }
        return Double(index + 1) / Double(count)
    }

    /// Section label + how many items that section has, for the current item ("Step", 8).
    func phaseLabel(at index: Int) -> (label: String, total: Int) {
        guard items.indices.contains(index) else { return ("", 0) }
        switch items[index] {
        case .ingredientList: return ("", 0)
        case .prePrep:        return ("Pre-Prep", prePrepCount)
        case .step:           return ("Step", stepCount)
        }
    }

    /// 1-based position within its own section (pre-prep or step); 0 for the ingredient list.
    func positionInPhase(at index: Int) -> Int {
        guard items.indices.contains(index) else { return 0 }
        switch items[index] {
        case .ingredientList:          return 0
        case .prePrep(let i, _), .step(let i, _): return i + 1
        }
    }

    /// One line per item for the Live Activity / Siri session (`CookingSession`).
    var sessionLines: [String] {
        items.map { $0.isIngredientList ? "First, gather your ingredients." : $0.displayText }
    }

    /// Timer minutes for a pre-prep or step item; nil for the ingredient list or an out-of-range index.
    func timerMinutes(at index: Int) -> Int? {
        // The ingredient list's displayText is "", which parses to nil.
        guard items.indices.contains(index) else { return nil }
        return Self.timerMinutes(in: items[index].displayText)
    }

    // Only counts an amount followed by a time unit, so "350°F"/"2 eggs" aren't read as durations. An amount is a
    // number (with an optional ½-style fraction), a lone fraction, or the words "a"/"an"/"half an"; a range
    // ("10-15", "2 to 3", "20 or 25") keeps its lower bound in group 1 (owner 2026-11-25). Compiled once.
    private static let amount = #"(?:\d+(?:\.\d+)?(?:\s*[½¼¾⅓⅔])?|[½¼¾⅓⅔])"#
    private static let timerRegex = try? NSRegularExpression(
        pattern: #"(\bhalf an?\b|\ban? half\b|\ban?\b|"# + amount + #")(?:\s*(?:-|–|—|\bto\b|\bor\b)\s*"# + amount + #")?"#
            + #"\s*(hours?|hrs?|minutes?|mins?|seconds?|secs?)\b"#,
        options: [.caseInsensitive]
    )

    private static let fractions: [Character: Double] = ["½": 0.5, "¼": 0.25, "¾": 0.75, "⅓": 1.0 / 3, "⅔": 2.0 / 3]

    /// The number an amount stands for: "an" → 1, "half an"/"a half" → 0.5, "1½" → 1.5, "½" → 0.5, "12" → 12.
    private static func value(ofAmount text: String) -> Double {
        let words = text.lowercased()
        if words.hasSuffix("half") || words.hasPrefix("half") { return 0.5 }
        if words == "a" || words == "an" { return 1 }
        var digits = ""
        var fraction = 0.0
        for character in words {
            if let part = fractions[character] { fraction = part } else if !character.isWhitespace { digits.append(character) }
        }
        return (Double(digits) ?? 0) + fraction
    }

    /// Minutes for the text's FIRST duration. A compound like "1 hour 30 minutes" is combined, but separate mentions
    /// ("chill 6 hours, up to 48 hours"; "broil 4-5 minutes… within 6 minutes") are not summed into one huge timer.
    static func timerMinutes(in text: String) -> Int? {
        guard let regex = timerRegex else { return nil }
        let ns = text as NSString
        // "a"/"an" before "second" is the ordinal ("in a second bowl"), never a one-second timer.
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length)).filter { match in
            let amount = ns.substring(with: match.range(at: 1)).lowercased()
            let unit = ns.substring(with: match.range(at: 2)).lowercased()
            return !((amount == "a" || amount == "an") && unit.hasPrefix("s"))
        }
        guard let first = matches.first else { return nil }

        func minutes(of match: NSTextCheckingResult) -> (value: Double, rank: Int) {
            let value = Self.value(ofAmount: ns.substring(with: match.range(at: 1)))
            let unit = ns.substring(with: match.range(at: 2)).lowercased()
            if unit.hasPrefix("h") { return (value * 60, 2) }
            if unit.hasPrefix("s") { return (value / 60, 0) }
            return (value, 1)
        }

        var (totalMinutes, lastRank) = minutes(of: first)
        var previousEnd = first.range.location + first.range.length
        for match in matches.dropFirst() {
            // Continue only for an adjacent, smaller unit ("1 hour 30 minutes", "1 hr and 15 mins").
            let gap = ns.substring(with: NSRange(location: previousEnd, length: match.range.location - previousEnd))
            let joiner = gap.trimmingCharacters(in: .whitespaces).lowercased()
            let part = minutes(of: match)
            guard joiner.isEmpty || joiner == "and" || joiner == ",", part.rank < lastRank else { break }
            totalMinutes += part.value
            lastRank = part.rank
            previousEnd = match.range.location + match.range.length
        }
        let rounded = Int(totalMinutes.rounded())
        return rounded > 0 ? rounded : nil
    }
}
