import Foundation

/// Canonical parser for a single free-text ingredient line — "2 tablespoons olive
/// oil", "1½ red pepper", "salt to taste". The single source of truth shared by
/// the import builder and the manual wizard so both entry paths behave identically
/// (previously two diverged copies).
///
/// Design notes:
/// - Units are recognised by synonym (spelled-out or abbreviated) and stored as a
///   canonical token ("tablespoons" → "tbsp", "grams" → "g") that `UnitConversion`
///   understands.
/// - A missing quantity is `0` (unspecified), never a fabricated `1`.
/// - The name keeps commas / prep notes ("garlic, minced"); `IngredientNameFormatter`
///   splits main-name vs prep note at display time.
enum IngredientLineParser {

    struct Parsed: Equatable {
        var quantity: Double      // resolved amount; 0 == unspecified
        var quantityText: String  // human text ("1 1/2", "3/4", "") matching `quantity`
        var unit: String          // canonical token, "" if none
        var name: String          // full name; commas / prep notes retained
    }

    static func parse(_ line: String) -> Parsed {
        // 1. Unicode fractions → ASCII with surrounding spaces so a digit-glued
        //    fraction ("1½") becomes "1 1/2", not "11/2".
        var working = normaliseUnicodeFractions(line)

        // 2. Drop parenthetical asides: "1 (14 oz) can ..." → "1  can ...".
        working = working.replacingOccurrences(of: #"\([^)]*\)"#, with: " ", options: .regularExpression)

        working = working.trimmingCharacters(in: .whitespaces)

        // 3. OCR fix: Vision reads a leading "1" as "I" ("I tablespoon ...").
        working = working.replacingOccurrences(of: #"^I(?=\s)"#, with: "1", options: .regularExpression)

        // 4. European decimal comma at the start: "1,5 dl" → "1.5 dl".
        working = working.replacingOccurrences(of: #"^(\d+),(\d+)"#, with: "$1.$2", options: .regularExpression)

        // 4b. UK multipack "1 x 400g tin ..." — drop the leading "N x" so the pack
        //     size (400 g) parses rather than the count.
        working = working.replacingOccurrences(of: #"^\d+\s*[x×]\s+(?=\d)"#, with: "", options: .regularExpression)

        // 5. Split a leading number glued to letters: "200g" → "200 g".
        working = working.replacingOccurrences(of: #"^([0-9][0-9/.]*)([a-zA-Z])"#, with: "$1 $2", options: .regularExpression)

        // Collapse whitespace introduced above.
        working = working.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                         .trimmingCharacters(in: .whitespaces)

        // 6. Resolve the quantity exactly once (range upper-bound → mixed → simple),
        //    so no later pass clobbers an earlier match.
        let (quantityText, afterQuantity) = extractQuantity(from: working)

        // 7. Canonical unit.
        let (unit, afterUnit) = extractUnit(from: afterQuantity)

        // 8. Name = remainder (keep commas/prep notes); drop a leading "of".
        var name = afterUnit.trimmingCharacters(in: .whitespaces)
        name = name.replacingOccurrences(of: #"^of\s+"#, with: "", options: [.regularExpression, .caseInsensitive])
        name = name.trimmingCharacters(in: .whitespaces)

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

    // MARK: - Quantity

    private static func extractQuantity(from text: String) -> (quantity: String, remaining: String) {
        // Range like "3/4 - 1", "3/4 – 1", or "2 to 3": take the upper bound.
        // (The trailing digit requirement keeps "2 tomatoes" from matching "to".)
        if let m = firstMatch(#"^[\d./]+\s*(?:[-–—]|to)\s*([\d./]+)(?:\s+|$)"#, in: text) {
            return (m.group(1), m.remainder)
        }
        // Mixed number "1 1/2".
        if let m = firstMatch(#"^(\d+\s+\d+/\d+)(?:\s+|$)"#, in: text) {
            return (m.group(1), m.remainder)
        }
        // Simple integer / decimal / fraction.
        if let m = firstMatch(#"^(\d+(?:\.\d+)?(?:/\d+)?|\d*/\d+)(?:\s+|$)"#, in: text) {
            return (m.group(1), m.remainder)
        }
        return ("", text)
    }

    /// Converts quantity text to a Double. Returns 0 for missing/unparseable
    /// (an ingredient with no stated amount), never a fabricated 1.
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
        let canonical = unitCanonical[matched] ?? matched
        return (canonical, m.remainder)
    }

    /// Synonym → canonical token. Abbreviations and spelled-out forms collapse to
    /// one token; count/other units keep a literal singular form.
    private static let unitCanonical: [String: String] = [
        "teaspoon": "tsp", "teaspoons": "tsp", "tsp": "tsp",
        "tablespoon": "tbsp", "tablespoons": "tbsp", "tbsp": "tbsp", "tbs": "tbsp",
        "cup": "cup", "cups": "cup",
        "milliliter": "ml", "milliliters": "ml", "millilitre": "ml", "millilitres": "ml", "ml": "ml",
        "liter": "l", "liters": "l", "litre": "l", "litres": "l", "l": "l",
        "deciliter": "dl", "deciliters": "dl", "dl": "dl",
        "centiliter": "cl", "centiliters": "cl", "cl": "cl",
        "fl oz": "fl oz", "fluid ounce": "fl oz", "fluid ounces": "fl oz",
        "pint": "pt", "pints": "pt", "pt": "pt",
        "quart": "qt", "quarts": "qt", "qt": "qt",
        "gallon": "gal", "gallons": "gal", "gal": "gal",
        "gram": "g", "grams": "g", "gramme": "g", "grammes": "g", "g": "g",
        "kilogram": "kg", "kilograms": "kg", "kg": "kg",
        "ounce": "oz", "ounces": "oz", "oz": "oz",
        "pound": "lbs", "pounds": "lbs", "lb": "lbs", "lbs": "lbs",
        "clove": "clove", "cloves": "clove",
        "piece": "piece", "pieces": "piece",
        "slice": "slice", "slices": "slice",
        "pinch": "pinch", "pinches": "pinch",
        "dash": "dash", "dashes": "dash",
        "stick": "stick", "sticks": "stick",
        "can": "can", "cans": "can", "tin": "can", "tins": "can",
        "package": "package", "packages": "package", "pkg": "package",
        "bunch": "bunch", "bunches": "bunch",
        "sprig": "sprig", "sprigs": "sprig",
        "handful": "handful", "handfuls": "handful",
        "inch": "inch", "inches": "inch"
    ]

    /// Anchored alternation of every synonym, longest first so "tablespoons" wins
    /// over "tbsp" and "lb" over "l". Must be followed by whitespace or end so a
    /// unit never swallows the start of an ingredient name ("l" vs "lemon").
    private static let unitPattern: String = {
        let alternatives = unitCanonical.keys
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
