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
    /// Sums hours and minutes in a free-form duration ("1 hr 30 min" → 90, "1.5 hours" → 90); bare number = minutes; unparseable = 0.
    static func extractMinutes(from timeString: String) -> Int {
        // Collapse a numeric range to its upper bound ("20-30 min" → "30 min") so the hyphen isn't scanned as a negative sign.
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
