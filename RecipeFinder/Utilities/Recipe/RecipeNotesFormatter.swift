import Foundation

/// Builds an `AttributedString` from a recipe's notes, detecting URLs and styling
/// them as tappable links. Extracted from `RecipeDetailView` so the link
/// detection is unit-testable and not computed inline in a SwiftUI `body`.
enum RecipeNotesFormatter {

    static func attributedString(from notes: String) -> AttributedString {
        var attributed = AttributedString(notes)
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let raw = notes
        let matches = detector?.matches(in: raw, range: NSRange(raw.startIndex..., in: raw)) ?? []
        for match in matches {
            guard let url = match.url,
                  let range = Range(match.range, in: raw),
                  let attrRange = Range(range, in: attributed) else { continue }
            attributed[attrRange].link = url
            attributed[attrRange].foregroundColor = .accentColor
            attributed[attrRange].underlineStyle = .single
        }
        return attributed
    }
}
