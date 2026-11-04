
import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Parses recipe data from HTML: structured data first (JSON-LD, then WP Recipe Maker), falling back to free-text heuristics. Strategies live in focused RecipeParser+* extensions.
struct RecipeParser {

    struct ParsedRecipe {
        var name: String?
        var description: String?
        var ingredients: [String] = []
        var instructions: [String] = []
        var prepTime: Int?
        var cookTime: Int?
        var servings: Int?
        var difficulty: String?
        var cuisine: String?
        var category: String?
        var imageURL: String?
        var confidence: Double = 0.0
    }

    static func parse(html: String) -> ParsedRecipe {
        var result = ParsedRecipe()
        var confidenceScore = 0.0
        let maxScore = 8.0

        if let jsonLD = extractJSONLD(from: html) {
            var enriched = jsonLD
            if enriched.imageURL == nil {
                enriched.imageURL = extractOGImage(from: html)
            }
            return enriched
        }

        if let wprm = extractWPRM(from: html) {
            var enriched = wprm
            if enriched.imageURL == nil {
                enriched.imageURL = extractOGImage(from: html)
            }
            return enriched
        }

        if let microdata = extractMicrodata(from: html) {
            var enriched = microdata
            if enriched.imageURL == nil {
                enriched.imageURL = extractOGImage(from: html)
            }
            return enriched
        }

        // RDFa Lite (vocab/typeof/property) — see RecipeParser+RDFa.
        if let rdfa = extractRDFa(from: html) {
            var enriched = rdfa
            if enriched.imageURL == nil {
                enriched.imageURL = extractOGImage(from: html)
            }
            return enriched
        }

        // Generic semantic-list fallback (BBC Good Food etc.) before free-text heuristics.
        if let domList = extractDOMList(from: html) {
            var enriched = domList
            if enriched.imageURL == nil {
                enriched.imageURL = extractOGImage(from: html)
            }
            return enriched
        }

        let text = cleanHTML(html)
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        if let name = extractRecipeName(from: html, text: text) {
            result.name = name
            confidenceScore += 1.0
        }

        if let description = extractDescription(from: text, lines: lines) {
            result.description = description
            confidenceScore += 0.5
        }

        if let prepTime = extractTime(from: text, type: .prep) {
            result.prepTime = prepTime
            confidenceScore += 1.0
        }

        if let cookTime = extractTime(from: text, type: .cook) {
            result.cookTime = cookTime
            confidenceScore += 1.0
        }

        if let servings = extractServings(from: text) {
            result.servings = servings
            confidenceScore += 1.0
        }

        let ingredients = extractIngredients(from: text, lines: lines)
        if !ingredients.isEmpty {
            result.ingredients = ingredients
            confidenceScore += 1.5
        }

        let instructions = extractInstructions(from: text, lines: lines)
        if !instructions.isEmpty {
            result.instructions = instructions
            confidenceScore += 1.5
        }

        if let difficulty = extractDifficulty(from: text) {
            result.difficulty = difficulty
            confidenceScore += 0.5
        }

        // Social/caption fallback: TikTok/Instagram pages carry no recipe body text, but the creator's caption lives in og:description.
        if result.ingredients.isEmpty, let caption = extractMetaContent(property: "og:description", from: html) {
            let capLines = caption.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            let capIngredients = extractIngredients(from: caption, lines: capLines)
            if !capIngredients.isEmpty {
                result.ingredients = capIngredients
                result.instructions = extractInstructions(from: caption, lines: capLines)
                // On social pages the body title is junk ("loading…"); og:title is the real name.
                if let ogTitle = extractMetaContent(property: "og:title", from: html)?.trimmed, !ogTitle.isEmpty {
                    result.name = ogTitle
                }
                confidenceScore += 1.5
            }
        }

        result.imageURL = extractOGImage(from: html)
        result.confidence = confidenceScore / maxScore
        return result
    }

    // MARK: - Shared utilities

    static func cleanHTML(_ html: String) -> String {
        var text = html

        text = text.replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?</script>", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?</style>", with: "", options: .regularExpression)

        text = text.replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "</p>", with: "\n\n", options: .regularExpression)
        // Turn every block-level close into a line break so headings/list items stay on their own lines — including minified pages with no source newlines, which the line-based heuristics otherwise miss.
        text = text.replacingOccurrences(
            of: "</(div|li|h[1-6]|ul|ol|tr|section|article|header|table|blockquote)>",
            with: "\n",
            options: [.regularExpression, .caseInsensitive]
        )

        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        // Preserve line structure: `decodeHTMLEntities`' NSAttributedString importer collapses newlines, which would flatten the page and defeat the line-based heuristics.
        text = text.replacingOccurrences(of: "\n", with: " \u{2424} ")
        text = decodeHTMLEntities(text)
        text = text.replacingOccurrences(of: "\\s*\u{2424}\\s*", with: "\n", options: .regularExpression)

        text = text.replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\n\\s*\\n\\s*\\n+", with: "\n\n", options: .regularExpression)

        return text.trimmed
    }

    static func decodeHTMLEntities(_ text: String) -> String {
        // NSAttributedString decodes named + numeric HTML entities (&eacute; → é, &amp; → &, &#233; → é).
        let wrapped = "<html><body>\(text)</body></html>"
        let decoded: String
        if let data = wrapped.data(using: .utf8),
           let attributed = try? NSAttributedString(
               data: data,
               options: [.documentType: NSAttributedString.DocumentType.html,
                         .characterEncoding: String.Encoding.utf8.rawValue],
               documentAttributes: nil) {
            decoded = attributed.string
        } else {
            decoded = text
        }

        var result = decoded

        let numericPattern = "&#(\\d+);"
        if result.contains("&#"), let regex = try? NSRegularExpression(pattern: numericPattern, options: []) {
            var replacements: [(NSRange, String)] = []
            let nsString = result as NSString
            let matches = regex.matches(in: result, options: [], range: NSRange(location: 0, length: nsString.length))

            for match in matches {
                let numberRange = match.range(at: 1)
                let numberStr = nsString.substring(with: numberRange)

                if let charCode = Int(numberStr),
                   charCode > 0,
                   charCode < 0x10FFFF,
                   let unicode = UnicodeScalar(charCode) {
                    let char = String(Character(unicode))
                    replacements.append((match.range, char))
                }
            }

            // Apply NSString-side: NSRange offsets are UTF-16, so mixing them with grapheme-based String.index mis-slices or crashes on non-BMP input (emoji before an entity).
            let mutable = NSMutableString(string: result)
            for (range, replacement) in replacements.reversed() {
                mutable.replaceCharacters(in: range, with: replacement)
            }
            result = mutable as String
        }

        return result
    }

    static func extractOGImage(from html: String) -> String? {
        let pattern = #"<meta[^>]+property=["\']og:image["\'][^>]+content=["\']([^"\']+)["\']"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
           let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            return String(html[range])
        }
        // Also handle reversed attribute order: content first, property second
        let patternReversed = #"<meta[^>]+content=["\']([^"\']+)["\'][^>]+property=["\']og:image["\']"#
        if let regex = try? NSRegularExpression(pattern: patternReversed, options: [.caseInsensitive]),
           let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            return String(html[range])
        }
        return nil
    }

    /// Content of an OpenGraph meta tag (e.g. `og:description`, `og:title`) — the caption TikTok/Instagram expose when the page has no recipe body text. Handles either attribute order; entities decoded (so `&#10;` → newline).
    static func extractMetaContent(property: String, from html: String) -> String? {
        let patterns = [
            "<meta[^>]+property=[\"']\(property)[\"'][^>]*\\scontent=\"([^\"]*)\"",
            "<meta[^>]+content=\"([^\"]*)\"[^>]*property=[\"']\(property)[\"']"
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                let decoded = decodeMetaPreservingNewlines(String(html[range]))
                if !decoded.isBlank {
                    return decoded
                }
            }
        }
        return nil
    }

    /// Decode a meta/caption value while keeping line breaks — plain `decodeHTMLEntities` flattens newlines, which destroys the caption's ingredient/step structure. Mirrors `cleanHTML`'s newline-protection trick.
    private static func decodeMetaPreservingNewlines(_ s: String) -> String {
        var t = s.replacingOccurrences(of: "&#10;", with: "\n")
            .replacingOccurrences(of: "&#13;", with: "\n")
            .replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: .regularExpression)
        t = t.replacingOccurrences(of: "\n", with: " \u{2424} ")
        t = decodeHTMLEntities(t)
        return t.replacingOccurrences(of: "\\s*\u{2424}\\s*", with: "\n", options: .regularExpression)
    }
}
