import Foundation

/// Schema.org **microdata** parsing for `RecipeParser` (`itemscope`/`itemprop`).
/// Runs after JSON-LD and WP Recipe Maker but before the free-text heuristics, so
/// microdata-only sites — an older but still-common style — parse structurally
/// instead of falling back to guesswork.
extension RecipeParser {

    static func extractMicrodata(from html: String) -> ParsedRecipe? {
        // Require an explicit schema.org Recipe scope to avoid false positives, and
        // narrow all field lookups to the markup from that scope onward so we don't
        // pick up a site/author "name" from the page header.
        let scopePattern = #"itemtype=["']https?://schema\.org/Recipe["']"#
        guard let scopeRange = html.range(of: scopePattern, options: [.regularExpression, .caseInsensitive]) else {
            return nil
        }
        let scoped = String(html[scopeRange.lowerBound...])

        // Ingredients — current property, then the legacy `ingredients` spelling.
        var ingredients = innerTexts(itemprop: "recipeIngredient", in: scoped)
        if ingredients.isEmpty {
            ingredients = innerTexts(itemprop: "ingredients", in: scoped)
        }
        guard !ingredients.isEmpty else { return nil }

        var result = ParsedRecipe()
        result.ingredients = ingredients

        guard let name = innerTexts(itemprop: "name", in: scoped).first, !name.isEmpty else {
            return nil
        }
        result.name = name

        result.description = innerTexts(itemprop: "description", in: scoped).first

        result.instructions = innerTexts(itemprop: "recipeInstructions", in: scoped)
            .filter { $0.count >= 10 }

        result.prepTime = minutes(forItemprop: "prepTime", in: scoped)
        result.cookTime = minutes(forItemprop: "cookTime", in: scoped)

        if let yield = innerTexts(itemprop: "recipeYield", in: scoped).first
            ?? firstCapture(#"itemprop=["']recipeYield["'][^>]*\bcontent=["']([^"']+)["']"#, in: scoped) {
            result.servings = extractServingsFromYield(yield)
        }

        result.imageURL = firstCapture(#"itemprop=["']image["'][^>]*\bsrc=["']([^"']+)["']"#, in: scoped)
            ?? firstCapture(#"itemprop=["']image["'][^>]*\bcontent=["']([^"']+)["']"#, in: scoped)

        result.confidence = 0.85
        return result
    }

    // MARK: - Helpers

    /// All immediate text-node values for elements carrying the given `itemprop`,
    /// decoded and trimmed. Matches the common flat form
    /// `<li itemprop="recipeIngredient">2 lbs beef</li>`.
    private static func innerTexts(itemprop: String, in html: String) -> [String] {
        allCaptures(#"itemprop=["']\#(itemprop)["'][^>]*>\s*([^<]+?)\s*<"#, in: html)
            .map { decodeHTMLEntities($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// Duration for a time-valued itemprop: prefers the ISO-8601 `datetime`
    /// attribute (in either attribute order), then falls back to parsing the
    /// human-readable inner text (e.g. "20 minutes", "2 hours").
    private static func minutes(forItemprop prop: String, in html: String) -> Int? {
        let iso = firstCapture(#"itemprop=["']\#(prop)["'][^>]*\bdatetime=["']([^"']+)["']"#, in: html)
            ?? firstCapture(#"\bdatetime=["']([^"']+)["'][^>]*itemprop=["']\#(prop)["']"#, in: html)
        if let iso, let mins = parseISO8601Duration(iso) {
            return mins
        }
        if let text = innerTexts(itemprop: prop, in: html).first {
            return minutesFromText(text)
        }
        return nil
    }

    private static func minutesFromText(_ text: String) -> Int? {
        var total = 0
        if let h = firstCapture(#"(\d+)\s*(?:hours?|hrs?)\b"#, in: text) { total += (Int(h) ?? 0) * 60 }
        if let m = firstCapture(#"(\d+)\s*(?:minutes?|mins?)\b"#, in: text) { total += Int(m) ?? 0 }
        return total > 0 ? total : nil
    }

    private static func allCaptures(_ pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return []
        }
        let ns = text as NSString
        return regex.matches(in: text, range: NSRange(location: 0, length: ns.length)).compactMap { match in
            guard match.numberOfRanges > 1 else { return nil }
            let range = match.range(at: 1)
            guard range.location != NSNotFound else { return nil }
            return ns.substring(with: range)
        }
    }

    private static func firstCapture(_ pattern: String, in text: String) -> String? {
        allCaptures(pattern, in: text).first
    }
}
