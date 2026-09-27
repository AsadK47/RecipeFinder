import Foundation

/// Schema.org microdata + RDFa Lite parsing via a shared attribute-driven core; runs after JSON-LD/WPRM but before free-text heuristics so structured non-JSON-LD sites parse structurally.
extension RecipeParser {

    static func extractMicrodata(from html: String) -> ParsedRecipe? {
        // Require an explicit schema.org Recipe scope to avoid false positives.
        extractSchemaAttributes(
            from: html,
            propAttr: "itemprop",
            scopePattern: #"itemtype=["']https?://schema\.org/Recipe["']"#
        )
    }

    /// RDFa Lite: `typeof` may carry a bare "Recipe" or a fully-qualified URL — match the token either way.
    static func extractRDFa(from html: String) -> ParsedRecipe? {
        extractSchemaAttributes(
            from: html,
            propAttr: "property",
            scopePattern: #"typeof=["'][^"']*\bRecipe\b[^"']*["']"#
        )
    }

    /// Shared microdata/RDFa extractor. Field lookups are narrowed to markup from the Recipe scope onward so we don't grab a site/author "name" from the page header.
    static func extractSchemaAttributes(from html: String, propAttr: String, scopePattern: String) -> ParsedRecipe? {
        guard let scopeRange = html.range(of: scopePattern, options: [.regularExpression, .caseInsensitive]) else {
            return nil
        }
        // Bound to this recipe: stop at the next schema.org/Recipe scope so a trailing related/comment recipe block doesn't bleed its ingredients in.
        let tail = String(html[scopeRange.lowerBound...])
        let scoped: String
        if tail.count > 1,
           let next = tail.range(of: scopePattern, options: [.regularExpression, .caseInsensitive],
                                 range: tail.index(after: tail.startIndex)..<tail.endIndex) {
            scoped = String(tail[..<next.lowerBound])
        } else {
            scoped = tail
        }

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
            // Single container element wrapping steps, rather than one prop per step.
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

    /// Decoded/trimmed immediate text-node values for elements with the attribute, e.g. `<li itemprop="recipeIngredient">2 lbs beef</li>`.
    private static func innerTexts(prop: String, attr: String, in html: String) -> [String] {
        allCaptures(#"\#(attr)=["']\#(prop)["'][^>]*>\s*([^<]+?)\s*<"#, in: html)
            .map { decodeHTMLEntities($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// Duration for a time-valued property: prefers the ISO-8601 `datetime` (either attribute order), else parses human-readable inner text.
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

    /// Steps from a single `recipeInstructions` container: isolate its inner HTML (balanced-tag scan) and split the cleaned text.
    private static func containerInstructions(attr: String, in html: String) -> [String] {
        guard let inner = innerHTML(prop: "recipeInstructions", attr: attr, in: html) else { return [] }
        return cleanHTML(inner)
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count >= 10 }
    }

    /// Inner HTML of the first element with the attribute; depth-counts matching tags so nested same-name tags don't end the element early.
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
