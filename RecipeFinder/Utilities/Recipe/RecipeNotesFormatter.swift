import Foundation

/// Builds an `AttributedString` from notes, styling detected URLs as tappable links; extracted from `RecipeDetailView` so detection is testable, not inline in `body`.
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
