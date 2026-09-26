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

enum TimeExtractor {
    /// Total minutes in a free-form duration string. Understands hours and
    /// minutes and sums them ("1 hr 30 min" → 90, "1.5 hours" → 90); a bare
    /// leading number is treated as minutes ("30" → 30). Anything unparseable
    /// is 0.
    ///
    /// Previously this read only the leading integer, so "1 hour" collapsed to
    /// 1 minute and hour-based times slipped through the cook-time filter.
    static func extractMinutes(from timeString: String) -> Int {
        // Collapse a numeric range to its upper bound ("20-30 min" → "30 min")
        // first, so the hyphen isn't scanned as a negative sign (which produced
        // negative times) and additive parsing below stays correct.
        let normalized = timeString.lowercased()
            .replacing(/([0-9.]+)\s*[-–—]\s*([0-9.]+)/) { String($0.output.2) }

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

        return foundNumber ? max(0, Int(totalMinutes.rounded())) : 0
    }
}
