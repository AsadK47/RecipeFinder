import Foundation

/// Canonical single-source parser for one free-text ingredient line, shared by the import builder and manual wizard so both entry paths match.
/// Units → canonical synonym token for `UnitConversion`; missing quantity is 0 (never a fabricated 1); name keeps commas/prep notes, split at display time.
enum IngredientLineParser {

    struct Parsed: Equatable {
        var quantity: Double      // resolved amount; 0 == unspecified
        var quantityText: String  // human text ("1 1/2", "3/4", "") matching `quantity`
        var unit: String          // canonical token, "" if none
        var name: String          // full name; commas / prep notes retained
    }

    /// Leading list/checkbox glyphs recipe sites prepend to ingredient rows (WordPress Recipe Maker "▢",
    /// ballot boxes, bullets). Stripped so the quantity is seen instead of swallowed into the name.
    private static let leadingMarkers = CharacterSet(charactersIn: "▢□☐◻◽◾◼▪▫◦‣·•●○∙-*")

    static func parse(_ line: String) -> Parsed {
        // 0. Strip a leading marker/checkbox glyph + whitespace so "▢100 g flour" parses as 100 g, not a bare name.
        var stripped = Substring(line)
        while let first = stripped.unicodeScalars.first,
              CharacterSet.whitespaces.contains(first) || leadingMarkers.contains(first) {
            stripped = stripped.dropFirst()
        }

        // 1. Unicode fractions → spaced ASCII so a glued "1½" becomes "1 1/2", not "11/2".
        var working = normaliseUnicodeFractions(String(stripped))

        // 2. Drop parenthetical asides: "1 (14 oz) can ..." → "1  can ...".
        working = working.replacingOccurrences(of: #"\([^)]*\)"#, with: " ", options: .regularExpression)

        working = working.trimmingCharacters(in: .whitespaces)

        // 3. OCR fix: Vision reads a leading "1" as "I" ("I tablespoon ...").
        working = working.replacingOccurrences(of: #"^I(?=\s)"#, with: "1", options: .regularExpression)

        // 4. European decimal comma at the start: "1,5 dl" → "1.5 dl".
        working = working.replacingOccurrences(of: #"^(\d+),(\d+)"#, with: "$1.$2", options: .regularExpression)

        // 4b. UK multipack "1 x 400g tin ..." — drop leading "N x" so the pack size parses, not the count.
        working = working.replacingOccurrences(of: #"^\d+\s*[x×]\s+(?=\d)"#, with: "", options: .regularExpression)

        // 5. Split a leading number glued to letters: "200g" → "200 g".
        working = working.replacingOccurrences(of: #"^([0-9][0-9/.]*)([a-zA-Z])"#, with: "$1 $2", options: .regularExpression)

        // Collapse whitespace introduced above.
        working = working.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                         .trimmingCharacters(in: .whitespaces)

        // 6. Resolve quantity once (range upper-bound → mixed → simple) so no later pass clobbers an earlier match.
        var (quantityText, afterQuantity) = extractQuantity(from: working)

        // 6b. Drop a prepended scrape/scale artifact: a bare integer immediately followed by ANOTHER number
        // ("750 500 grams", "5 1 teaspoon", "8421052632 2 cups") is a scaled/garbage value — prefer the real
        // second amount. Only fires integer-then-number, so "3 chicken" / "1 1/2 tbsp" / ranges are untouched.
        var hops = 0
        while hops < 4,
              quantityText.range(of: #"^\d+$"#, options: .regularExpression) != nil {
            // Re-split a glued "<number><letter>" ("900g") the line-start pass in step 5 couldn't reach.
            let rest = afterQuantity.trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: #"^([0-9][0-9/.]*)([a-zA-Z])"#, with: "$1 $2", options: .regularExpression)
            guard let first = rest.unicodeScalars.first, CharacterSet.decimalDigits.contains(first) else { break }
            let (q2, rem2) = extractQuantity(from: rest)
            guard !q2.isEmpty else { break }
            quantityText = q2
            afterQuantity = rem2
            hops += 1
        }

        // 7. Canonical unit.
        let (unit, afterUnit) = extractUnit(from: afterQuantity)

        // 8. Name = remainder (keep commas/prep notes); drop a leading "of".
        var name = afterUnit.trimmingCharacters(in: .whitespaces)
        name = name.replacingOccurrences(of: #"^of\s+"#, with: "", options: [.regularExpression, .caseInsensitive])
        name = name.trimmingCharacters(in: .whitespaces)

        // Name-first fallback: lines like "Minced chicken 500g", "Butter: 60g", "Sugar 3tsp" have no
        // LEADING amount, so lift the first embedded "<number><unit>" out and keep the rest as the name.
        // Only runs when no leading quantity/unit was found, so the common leading-amount lines are untouched.
        if quantityText.isEmpty, unit.isEmpty, let embedded = extractEmbeddedAmount(from: working) {
            return Parsed(
                quantity: parseQuantity(embedded.quantityText),
                quantityText: embedded.quantityText,
                unit: embedded.unit,
                name: embedded.name
            )
        }

        if quantityText.isEmpty && unit.isEmpty && name.isEmpty {
            name = working
        }

        return Parsed(
            quantity: parseQuantity(quantityText),
            quantityText: quantityText,
            unit: unit,
            name: name
        )
    }

    /// First embedded "<number><unit>" in a name-first line (e.g. "flour 200g", "butter: 60g", "sugar 3tsp"),
    /// with the amount lifted out and the rest returned as the name. Requires a real unit token (so trailing
    /// scale artifacts like "chopped 50" or bare counts like "eggs 4 2" don't false-match).
    private static func extractEmbeddedAmount(from text: String) -> (quantityText: String, unit: String, name: String)? {
        guard let regex = try? NSRegularExpression(pattern: embeddedAmountPattern, options: [.caseInsensitive]) else { return nil }
        let ns = text as NSString
        guard let m = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: ns.length)),
              m.numberOfRanges >= 3 else { return nil }

        let quantityText = ns.substring(with: m.range(at: 1))
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        let rawUnit = ns.substring(with: m.range(at: 2)).lowercased()
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        let unit = UnitConversion.unitSynonyms[rawUnit] ?? rawUnit

        let before = ns.substring(to: m.range.location)
        let after = ns.substring(from: m.range.location + m.range.length)
        var name = (before + " " + after)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: " ,:;-"))
        name = name.replacingOccurrences(of: #"^of\s+"#, with: "", options: [.regularExpression, .caseInsensitive])
        name = name.trimmingCharacters(in: .whitespaces)

        guard !name.isEmpty else { return nil }
        return (quantityText, unit, name)
    }

    /// Non-anchored "<number> <unit>" for the name-first fallback; units longest-first so "grams" beats "g".
    private static let embeddedAmountPattern: String = {
        let alternatives = UnitConversion.unitSynonyms.keys
            .sorted { $0.count != $1.count ? $0.count > $1.count : $0 < $1 }
            .map { NSRegularExpression.escapedPattern(for: $0) }
            .joined(separator: "|")
        return #"(\d+(?:\.\d+)?(?:\s+\d+/\d+)?|\d*/\d+)\s*("# + alternatives + #")(?![A-Za-z])"#
    }()

    // MARK: - Quantity

    private static func extractQuantity(from text: String) -> (quantity: String, remaining: String) {
        // Range "3/4 - 1" / "2 to 3": take upper bound (trailing-digit requirement keeps "2 tomatoes" from matching "to").
        if let m = firstMatch(#"^[\d./]+\s*(?:[-–—]|to)\s*([\d./]+)(?:\s+|$)"#, in: text) {
            return (m.group(1), m.remainder)
        }
        // Mixed number "1 1/2" — whole part 1–2 digits; a 3+ digit "whole" before a fraction is a scrape
        // artifact ("4210526316 1/2"), left for the simple rule + artifact loop to split.
        if let m = firstMatch(#"^(\d{1,2}\s+\d+/\d+)(?:\s+|$)"#, in: text) {
            return (m.group(1), m.remainder)
        }
        // Simple integer / decimal / fraction.
        if let m = firstMatch(#"^(\d+(?:\.\d+)?(?:/\d+)?|\d*/\d+)(?:\s+|$)"#, in: text) {
            return (m.group(1), m.remainder)
        }
        return ("", text)
    }

    /// Converts quantity text to Double; returns 0 for missing/unparseable (no stated amount), never a fabricated 1.
    static func parseQuantity(_ s: String) -> Double {
        let trimmed = s.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return 0 }
        if let d = Double(trimmed) { return d }
        // Mixed number "1 1/2".
        let parts = trimmed.split(separator: " ", maxSplits: 1).map(String.init)
        if parts.count == 2, let whole = Double(parts[0]), let frac = parseFraction(parts[1]) {
            return whole + frac
        }
        if let frac = parseFraction(trimmed) { return frac }
        return 0
    }

    private static func parseFraction(_ s: String) -> Double? {
        let parts = s.split(separator: "/", maxSplits: 1).map(String.init)
        guard parts.count == 2,
              let num = Double(parts[0].trimmingCharacters(in: .whitespaces)),
              let den = Double(parts[1].trimmingCharacters(in: .whitespaces)),
              den != 0 else { return nil }
        return num / den
    }

    // MARK: - Unit

    private static func extractUnit(from text: String) -> (unit: String, remaining: String) {
        guard let m = firstMatch(unitPattern, in: text, caseInsensitive: true) else {
            return ("", text)
        }
        let matched = m.group(1).lowercased().replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        let canonical = UnitConversion.unitSynonyms[matched] ?? matched
        return (canonical, m.remainder)
    }


    /// Anchored synonym alternation, longest-first ("tablespoons" beats "tbsp", "lb" beats "l"), trailed by \s/end so a unit never eats a name ("l" vs "lemon").
    private static let unitPattern: String = {
        let alternatives = UnitConversion.unitSynonyms.keys
            .sorted { $0.count != $1.count ? $0.count > $1.count : $0 < $1 }
            .map { NSRegularExpression.escapedPattern(for: $0) }
            .joined(separator: "|")
        return "^(\(alternatives))(?:\\s+|$)"
    }()

    // MARK: - Unicode fractions

    static func normaliseUnicodeFractions(_ s: String) -> String {
        let map: [(Character, String)] = [
            ("¼", "1/4"), ("½", "1/2"), ("¾", "3/4"),
            ("⅓", "1/3"), ("⅔", "2/3"),
            ("⅛", "1/8"), ("⅜", "3/8"), ("⅝", "5/8"), ("⅞", "7/8"),
            ("⅕", "1/5"), ("⅖", "2/5"), ("⅗", "3/5"), ("⅘", "4/5"),
            ("⅙", "1/6"), ("⅚", "5/6")
        ]
        var result = s
        for (char, replacement) in map {
            // Surround with spaces so "1½" → "1 1/2 " rather than "11/2 ".
            result = result.replacingOccurrences(of: String(char), with: " \(replacement) ")
        }
        return result
    }

    // MARK: - Regex helper

    private struct MatchResult {
        let groups: [String]
        let remainder: String
        func group(_ i: Int) -> String { i < groups.count ? groups[i] : "" }
    }

    private static func firstMatch(_ pattern: String, in text: String, caseInsensitive: Bool = false) -> MatchResult? {
        let options: NSRegularExpression.Options = caseInsensitive ? [.caseInsensitive] : []
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return nil }
        let ns = text as NSString
        guard let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: ns.length)) else {
            return nil
        }
        var groups: [String] = []
        for i in 0..<match.numberOfRanges {
            let r = match.range(at: i)
            groups.append(r.location == NSNotFound ? "" : ns.substring(with: r))
        }
        let remainder = ns.substring(from: match.range.location + match.range.length)
        return MatchResult(groups: groups, remainder: remainder)
    }
}
