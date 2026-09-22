import Foundation

/// Schema.org attribute-vocabulary parsing for `RecipeParser`. The shared core
/// (`extractSchemaAttributes`) is driven by the per-field attribute name, so it
/// serves both **microdata** (`itemscope`/`itemprop`) and **RDFa Lite**
/// (`vocab`/`typeof`/`property`) without a second diverging parser. Runs after
/// JSON-LD and WP Recipe Maker but before the free-text heuristics, so
/// structured-but-not-JSON-LD sites parse structurally instead of guesswork.
extension RecipeParser {

    static func extractMicrodata(from html: String) -> ParsedRecipe? {
        // Require an explicit schema.org Recipe scope to avoid false positives.
        extractSchemaAttributes(
            from: html,
            propAttr: "itemprop",
            scopePattern: #"itemtype=["']https?://schema\.org/Recipe["']"#
        )
    }

    /// Schema.org **RDFa Lite** (`vocab`/`typeof`/`property`), via the shared core.
    /// `typeof` may carry a bare "Recipe" (paired with a `vocab="https://schema.org/"`)
    /// or a fully-qualified "https://schema.org/Recipe" — match the token either way.
    static func extractRDFa(from html: String) -> ParsedRecipe? {
        extractSchemaAttributes(
            from: html,
            propAttr: "property",
            scopePattern: #"typeof=["'][^"']*\bRecipe\b[^"']*["']"#
        )
    }

    /// Shared schema.org extractor for the microdata / RDFa attribute vocabularies.
    /// `propAttr` is the per-field attribute name (`itemprop` vs `property`) and
    /// `scopePattern` locates the opening marker of the Recipe container; all field
    /// lookups are narrowed to the markup from that scope onward so we don't pick up
    /// a site/author "name" from the page header.
    static func extractSchemaAttributes(from html: String, propAttr: String, scopePattern: String) -> ParsedRecipe? {
        guard let scopeRange = html.range(of: scopePattern, options: [.regularExpression, .caseInsensitive]) else {
            return nil
        }
        let scoped = String(html[scopeRange.lowerBound...])

        // Ingredients — current property, then the legacy `ingredients` spelling.
        var ingredients = innerTexts(prop: "recipeIngredient", attr: propAttr, in: scoped)
        if ingredients.isEmpty {
            ingredients = innerTexts(prop: "ingredients", attr: propAttr, in: scoped)
        }
        guard !ingredients.isEmpty else { return nil }

        var result = ParsedRecipe()
        result.ingredients = ingredients

        guard let name = innerTexts(prop: "name", attr: propAttr, in: scoped).first, !name.isEmpty else {
            return nil
        }
        result.name = name

        result.description = innerTexts(prop: "description", attr: propAttr, in: scoped).first

        result.instructions = innerTexts(prop: "recipeInstructions", attr: propAttr, in: scoped)
            .filter { $0.count >= 10 }
        if result.instructions.isEmpty {
            // A single container element (e.g. <div property="recipeInstructions">
            // wrapping <p> steps) rather than one prop per step.
            result.instructions = containerInstructions(attr: propAttr, in: scoped)
        }

        result.prepTime = minutes(forProp: "prepTime", attr: propAttr, in: scoped)
        result.cookTime = minutes(forProp: "cookTime", attr: propAttr, in: scoped)

        if let yield = innerTexts(prop: "recipeYield", attr: propAttr, in: scoped).first
            ?? firstCapture(#"\#(propAttr)=["']recipeYield["'][^>]*\bcontent=["']([^"']+)["']"#, in: scoped) {
            result.servings = extractServingsFromYield(yield)
        }

        result.imageURL = firstCapture(#"\#(propAttr)=["']image["'][^>]*\bsrc=["']([^"']+)["']"#, in: scoped)
            ?? firstCapture(#"\#(propAttr)=["']image["'][^>]*\bcontent=["']([^"']+)["']"#, in: scoped)

        result.confidence = 0.85
        return result
    }

    // MARK: - Helpers

    /// All immediate text-node values for elements carrying the given attribute,
    /// decoded and trimmed. Matches the common flat form
    /// `<li itemprop="recipeIngredient">2 lbs beef</li>`.
    private static func innerTexts(prop: String, attr: String, in html: String) -> [String] {
        allCaptures(#"\#(attr)=["']\#(prop)["'][^>]*>\s*([^<]+?)\s*<"#, in: html)
            .map { decodeHTMLEntities($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// Duration for a time-valued property: prefers the ISO-8601 `datetime`
    /// attribute (in either attribute order), then falls back to parsing the
    /// human-readable inner text (e.g. "20 minutes", "2 hours").
    private static func minutes(forProp prop: String, attr: String, in html: String) -> Int? {
        let iso = firstCapture(#"\#(attr)=["']\#(prop)["'][^>]*\bdatetime=["']([^"']+)["']"#, in: html)
            ?? firstCapture(#"\bdatetime=["']([^"']+)["'][^>]*\#(attr)=["']\#(prop)["']"#, in: html)
        if let iso, let mins = parseISO8601Duration(iso) {
            return mins
        }
        if let text = innerTexts(prop: prop, attr: attr, in: html).first {
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
    /// cleaned text — used when there isn't one prop per step.
    private static func containerInstructions(attr: String, in html: String) -> [String] {
        guard let inner = innerHTML(prop: "recipeInstructions", attr: attr, in: html) else { return [] }
        return cleanHTML(inner)
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count >= 10 }
    }

    /// Inner HTML of the first element carrying the attribute, found by matching its
    /// opening tag then scanning for the matching close with depth counting so
    /// nested same-name tags don't end the element early.
    private static func innerHTML(prop: String, attr: String, in html: String) -> String? {
        let openPattern = #"<([a-zA-Z0-9]+)\b[^>]*\b\#(attr)=["']\#(prop)["'][^>]*>"#
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
