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
        if result.instructions.isEmpty {
            // A single container element (e.g. <div itemprop="recipeInstructions">
            // wrapping <p> steps) rather than one itemprop per step.
            result.instructions = containerInstructions(in: scoped)
        }

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

    /// Steps pulled from a single `recipeInstructions` **container** element, by
    /// isolating that element's inner HTML (balanced-tag scan) and splitting its
    /// cleaned text — used when there isn't one itemprop per step.
    private static func containerInstructions(in html: String) -> [String] {
        guard let inner = innerHTML(itemprop: "recipeInstructions", in: html) else { return [] }
        return cleanHTML(inner)
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count >= 10 }
    }

    /// Inner HTML of the first element carrying `itemprop`, found by matching its
    /// opening tag then scanning for the matching close with depth counting so
    /// nested same-name tags don't end the element early.
    private static func innerHTML(itemprop: String, in html: String) -> String? {
        let openPattern = #"<([a-zA-Z0-9]+)\b[^>]*\bitemprop=["']\#(itemprop)["'][^>]*>"#
        guard let openRegex = try? NSRegularExpression(pattern: openPattern, options: [.caseInsensitive]) else {
            return nil
        }
        let ns = html as NSString
        guard let open = openRegex.firstMatch(in: html, range: NSRange(location: 0, length: ns.length)) else {
            return nil
        }
        let tag = ns.substring(with: open.range(at: 1)).lowercased()
        let contentStart = open.range.location + open.range.length
        let rest = ns.substring(from: contentStart) as NSString

        guard let tokenRegex = try? NSRegularExpression(pattern: #"</?\#(tag)\b[^>]*>"#, options: [.caseInsensitive]) else {
            return nil
        }
        var depth = 1
        for token in tokenRegex.matches(in: rest as String, range: NSRange(location: 0, length: rest.length)) {
            let text = rest.substring(with: token.range)
            if text.hasPrefix("</") {
                depth -= 1
                if depth == 0 {
                    return rest.substring(to: token.range.location)
                }
            } else if !text.hasSuffix("/>") {
                depth += 1
            }
        }
        return nil
    }
}
