import Foundation

enum FractionFormatter {
    static func toFraction(_ value: Double) -> String? {
        guard value.isFinite else { return nil }
        let tolerance = 0.001
        let whole = Int(value)
        let decimal = value - Double(whole)
        
        let fractions: [(Double, String)] = [
            (0.125, "⅛"), (0.25, "¼"), (0.333, "⅓"), (0.375, "⅜"),
            (0.5, "½"), (0.625, "⅝"), (0.666, "⅔"), (0.75, "¾"), (0.875, "⅞")
        ]
        
        for (decimalValue, fractionSymbol) in fractions {
            if abs(decimal - decimalValue) < tolerance {
                if whole == 0 {
                    return fractionSymbol
                } else {
                    return "\(whole)\(fractionSymbol)"
                }
            }
        }
        
        return nil
    }

    static func format(_ value: Double) -> String {
        guard value.isFinite else { return "0" }
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        if let fraction = toFraction(value) {
            return fraction
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2g", value)
    }
}

/// Web and JSON-LD text writes "1⁄2" with U+2044 and dashes as U+2010/U+2011/U+2012/U+2212 (or their small and
/// full-width forms): read them as "/" and "-". A superscript fraction flattened to text ("1¹⁄₂" → "11⁄2") puts the
/// whole number right against a one-digit numerator: split it ("1 1/2"), or "11/2" reads as 5½.
/// Shared by step timers, recipe times and ingredient amounts so all three read a number the same way.
enum NumberText {
    private static let unusualScalars: Set<Unicode.Scalar> = [
        "\u{2044}", "\u{2010}", "\u{2011}", "\u{2012}", "\u{2212}", "\u{FE63}", "\u{FF0D}"
    ]

    static func plain(_ text: String) -> String {
        // Most text has none of these; skip the regex work (cards parse times hundreds of times per rebuild).
        guard text.unicodeScalars.contains(where: { unusualScalars.contains($0) }) else { return text }
        return text
            .replacingOccurrences(of: "(\\d)([1-9])\u{2044}([2-9])(?!\\d)", with: "$1 $2/$3", options: .regularExpression)
            .replacingOccurrences(of: "\u{2044}", with: "/")
            .replacingOccurrences(of: "[\u{2010}\u{2011}\u{2012}\u{2212}\u{FE63}\u{FF0D}]", with: "-",
                                  options: .regularExpression)
    }
}

enum TimeExtractor {
    /// Fraction glyphs as values. A glyph is always a fraction (it can't mean "or"), so it skips the slash rule below.
    private static let vulgarFractions: [Character: Double] = [
        "¼": 1 / 4, "½": 1 / 2, "¾": 3 / 4, "⅓": 1 / 3, "⅔": 2 / 3, "⅛": 1 / 8, "⅜": 3 / 8, "⅝": 5 / 8, "⅞": 7 / 8,
        "⅕": 1 / 5, "⅖": 2 / 5, "⅗": 3 / 5, "⅘": 4 / 5, "⅙": 1 / 6, "⅚": 5 / 6
    ]

    /// ½, ⅓, ⅔, ¼, ¾ — the fractions a recipe time is written in; nil for anything else.
    private static func timeFraction(top: Substring, bottom: Substring) -> Double? {
        let allowed: Set<String> = ["1/2", "1/3", "2/3", "1/4", "3/4"]
        guard allowed.contains("\(top)/\(bottom)"), let top = Double(top), let bottom = Double(bottom) else { return nil }
        return top / bottom
    }

    /// Sums hours and minutes in a free-form duration ("1 hr 30 min" → 90, "1.5 hours" → 90, "1 1/2 hours" → 90);
    /// bare number = minutes; unparseable = 0.
    static func extractMinutes(from timeString: String) -> Int {
        var text = NumberText.plain(timeString.lowercased())
        if text.contains(where: { vulgarFractions[$0] != nil }) {
            // "1½", "1 ½", "1-½" are one amount (½ is below any whole number, so never a range); then a lone "½".
            text = text.replacing(/(\d+)[\s-]*([¼½¾⅓⅔⅛⅜⅝⅞⅕⅖⅗⅘⅙⅚])/) { match in
                guard let whole = Double(match.output.1), let glyph = match.output.2.first,
                      let part = vulgarFractions[glyph] else { return String(match.output.0) }
                return String(whole + part)
            }
            text = text.map { character in vulgarFractions[character].map { " \($0) " } ?? String(character) }.joined()
        }
        // Fractions as decimals: a mixed number ("1 1/2", US "1-1/2") is one amount, then a lone "3/4" → 0.75. Without
        // this the scanner reads "1 1/2 hours" as 1 + 1 + 2 hours. Only halves, thirds and quarters are time fractions;
        // any other "a/b" is a slash for "or" ("10/12 minutes", "6/8 hours") and reads as the range a-b.
        if text.contains("/") {
            text = text.replacing(/(^|[^\d.\/])(\d+)[\s-]+(\d+)\/(\d+)/) { match in
                guard let whole = Double(match.output.2),
                      let part = timeFraction(top: match.output.3, bottom: match.output.4) else { return String(match.output.0) }
                return "\(match.output.1)\(whole + part)"
            }
            text = text.replacing(/(\d+)\/(\d+)/) { match in
                timeFraction(top: match.output.1, bottom: match.output.2).map { String($0) }
                    ?? "\(match.output.1)-\(match.output.2)"
            }
        }
        // Collapse a numeric range to its upper bound ("20-30 min" → "30 min") so the hyphen isn't scanned as a negative sign.
        // The Regex is slow and cards, Today and discovery parse hundreds of times per rebuild, so only run it when
        // there's a dash to collapse. (No MemoCache: this file is also built into the share extension.)
        let normalized = text.contains(where: { "-–—".contains($0) })
            ? text.replacing(/([0-9.]+)\s*[-–—]\s*([0-9.]+)/) { String($0.output.2) }
            : text

        let scanner = Scanner(string: normalized)
        scanner.charactersToBeSkipped = .whitespaces

        var totalMinutes = 0.0
        var foundNumber = false

        while !scanner.isAtEnd {
            guard let number = scanner.scanDouble() else {
                _ = scanner.scanCharacter()
                continue
            }
            foundNumber = true
            let unit = scanner.scanCharacters(from: .letters) ?? ""
            // Hours scale up; minutes and bare/unknown units count as minutes.
            totalMinutes += unit.hasPrefix("h") ? number * 60 : number
        }

        // Clamp before Int() — a huge parsed number (garbage/OCR) would trap the Double→Int conversion.
        return foundNumber ? max(0, Int(min(totalMinutes.rounded(), 1_000_000))) : 0
    }
}

/// The app's two duration formats, so every time label and countdown reads the same.
enum DurationFormatter {
    /// "45 minutes" under an hour, then "1 hr" / "9 hr 45 min" ("585 minutes" is unreadable).
    static func label(minutes total: Int) -> String {
        guard total >= 60 else { return "\(total) minutes" }
        let hours = total / 60, minutes = total % 60
        return minutes == 0 ? "\(hours) hr" : "\(hours) hr \(minutes) min"
    }

    static func hours(of total: Int) -> Int { total / 60 }
    static func minutes(of total: Int) -> Int { total % 60 }

    /// New total after picking an hour count, keeping the minutes.
    static func total(_ total: Int, settingHours hours: Int) -> Int { hours * 60 + minutes(of: total) }

    /// New total after picking a minute count, keeping the hours.
    static func total(_ total: Int, settingMinutes minutes: Int) -> Int { hours(of: total) * 60 + minutes }

    /// 0, 5 … 55, plus the current minutes when an import gave an odd value (e.g. 7), so the picker can show it.
    static func minuteChoices(including total: Int) -> [Int] {
        let steps = Array(stride(from: 0, through: 55, by: 5))
        let current = minutes(of: total)
        return steps.contains(current) ? steps : (steps + [current]).sorted()
    }

    /// Countdown clock, "01:05:09".
    static func clock(seconds: Int) -> String {
        String(format: "%02d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }
}
