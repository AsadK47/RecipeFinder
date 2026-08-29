import Foundation

/// Splits a free-text ingredient line (e.g. "2 cups flour") into its quantity,
/// unit, and name. Extracted verbatim from `RecipeWizardView` so the parsing is
/// unit-testable and no longer lives inline in a SwiftUI view.
///
/// The behavior here intentionally mirrors the original inline implementation,
/// including its handling of unicode fractions and leading range amounts.
enum WizardIngredientParser {

    struct Parsed: Equatable {
        var quantity: String
        var unit: String
        var name: String
    }

    static func parse(_ fullIngredient: String) -> Parsed {
        let trimmed = normaliseUnicodeFractions(fullIngredient).trimmingCharacters(in: .whitespaces)

        let quantityPattern = #"^([\d\./\-]+)\s+"#
        var quantity = ""
        var remaining = trimmed

        // Normalise range amounts like "3/4 – 1" or "¾-1" — take the upper bound
        let rangePattern = #"^[\d/\.]+\s*[-–]\s*([\d/\.]+)\s+"#
        if let regex = try? NSRegularExpression(pattern: rangePattern, options: []) {
            let nsRemaining = remaining as NSString
            if let match = regex.firstMatch(in: remaining, options: [], range: NSRange(location: 0, length: nsRemaining.length)) {
                quantity = nsRemaining.substring(with: match.range(at: 1))
                remaining = nsRemaining.substring(from: match.range.location + match.range.length)
            }
        }

        if let regex = try? NSRegularExpression(pattern: quantityPattern, options: []) {
            let nsString = trimmed as NSString
            if let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(location: 0, length: nsString.length)) {
                let quantityRange = match.range(at: 1)
                quantity = nsString.substring(with: quantityRange)
                remaining = nsString.substring(from: match.range.location + match.range.length)
            }
        }

        let unitPattern = #"^(tbsp|tsp|cups?|ml|l|liter|liters|g|kg|oz|lbs?|cloves?|pieces?|pinch|dash|inch(?:es)?)(?:\s+|$)"#
        var unit = ""

        if let regex = try? NSRegularExpression(pattern: unitPattern, options: .caseInsensitive) {
            let nsString = remaining as NSString
            if let match = regex.firstMatch(in: remaining, options: [], range: NSRange(location: 0, length: nsString.length)) {
                let unitRange = match.range(at: 1)
                unit = nsString.substring(with: unitRange)
                let afterUnit = match.range.location + match.range.length
                remaining = nsString.substring(from: afterUnit)
            }
        }

        var name = remaining.trimmingCharacters(in: .whitespaces)

        if let commaIndex = name.firstIndex(of: ",") {
            name = String(name[..<commaIndex])
        }

        name = name.trimmingCharacters(in: .whitespaces)

        if quantity.isEmpty && unit.isEmpty && name.isEmpty {
            name = trimmed
        }

        return Parsed(quantity: quantity, unit: unit, name: name)
    }

    static func normaliseUnicodeFractions(_ s: String) -> String {
        let map: [(Character, String)] = [
            ("¼", "1/4"), ("½", "1/2"), ("¾", "3/4"),
            ("⅓", "1/3"), ("⅔", "2/3"),
            ("⅛", "1/8"), ("⅜", "3/8"), ("⅝", "5/8"), ("⅞", "7/8"),
            ("⅕", "1/5"), ("⅖", "2/5"), ("⅗", "3/5"), ("⅘", "4/5"),
            ("⅙", "1/6"), ("⅚", "5/6"),
        ]
        var result = s
        for (char, replacement) in map {
            result = result.replacingOccurrences(of: String(char), with: replacement + " ")
        }
        return result
    }
}
