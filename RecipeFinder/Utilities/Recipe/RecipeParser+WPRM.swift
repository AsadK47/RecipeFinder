import Foundation

/// WP Recipe Maker parsing for `RecipeParser`; extracts structured fields from `wprm-recipe-*` markup, falling back to text heuristics for instructions.
extension RecipeParser {

    static func extractWPRM(from html: String) -> ParsedRecipe? {
        guard html.contains("wprm-recipe") || html.contains("wp-recipe-maker") else {
            return nil
        }

        var result = ParsedRecipe()
        result.confidence = 0.95

        result.name = wprmText(#"class="wprm-recipe-name[^"]*">([^<]+)<"#, in: html)

        let prepTimePattern = #"wprm-recipe-prep_time-minutes[^>]*>(\d+)<"#
        if let regex = try? NSRegularExpression(pattern: prepTimePattern, options: []) {
            let nsString = html as NSString
            if let match = regex.firstMatch(in: html, options: [], range: NSRange(location: 0, length: nsString.length)) {
                let minutesRange = match.range(at: 1)
                let minutesStr = nsString.substring(with: minutesRange)
                if let minutes = Int(minutesStr) {
                    result.prepTime = minutes
                }
            }
        }

        let cookTimePattern = #"wprm-recipe-cook_time-minutes[^>]*>(\d+)<"#
        if let regex = try? NSRegularExpression(pattern: cookTimePattern, options: []) {
            let nsString = html as NSString
            if let match = regex.firstMatch(in: html, options: [], range: NSRange(location: 0, length: nsString.length)) {
                let minutesRange = match.range(at: 1)
                let minutesStr = nsString.substring(with: minutesRange)
                if let minutes = Int(minutesStr) {
                    result.cookTime = minutes
                }
            }
        }

        if result.prepTime == nil {
            let prepDataPattern = #"wprm-recipe-prep[^>]*?data-minutes="(\d+)""#
            if let regex = try? NSRegularExpression(pattern: prepDataPattern, options: []) {
                let nsString = html as NSString
                if let match = regex.firstMatch(in: html, options: [], range: NSRange(location: 0, length: nsString.length)) {
                    let minutesRange = match.range(at: 1)
                    let minutesStr = nsString.substring(with: minutesRange)
                    if let minutes = Int(minutesStr) {
                        result.prepTime = minutes
                    }
                }
            }
        }

        if result.cookTime == nil {
            let cookDataPattern = #"wprm-recipe-cook[^>]*?data-minutes="(\d+)""#
            if let regex = try? NSRegularExpression(pattern: cookDataPattern, options: []) {
                let nsString = html as NSString
                if let match = regex.firstMatch(in: html, options: [], range: NSRange(location: 0, length: nsString.length)) {
                    let minutesRange = match.range(at: 1)
                    let minutesStr = nsString.substring(with: minutesRange)
                    if let minutes = Int(minutesStr) {
                        result.cookTime = minutes
                    }
                }
            }
        }

        let servingsPattern = #"wprm-recipe-servings[^>]*data-recipe="\d+"[^>]*>(\d+)<"#
        if let regex = try? NSRegularExpression(pattern: servingsPattern, options: []) {
            let nsString = html as NSString
            if let match = regex.firstMatch(in: html, options: [], range: NSRange(location: 0, length: nsString.length)) {
                if match.numberOfRanges > 1 {
                    let servingsRange = match.range(at: 1)
                    let servingsStr = nsString.substring(with: servingsRange)
                    if let servings = plausibleServings(Int(servingsStr)) {
                        result.servings = servings
                    }
                }
            }
        }

        if result.servings == nil {
            let dataServingsPattern = #"wprm-recipe-servings[^>]*?data-servings="(\d+)""#
            if let regex = try? NSRegularExpression(pattern: dataServingsPattern, options: []) {
                let nsString = html as NSString
                if let match = regex.firstMatch(in: html, options: [], range: NSRange(location: 0, length: nsString.length)) {
                    if match.numberOfRanges > 1 {
                        let servingsRange = match.range(at: 1)
                        let servingsStr = nsString.substring(with: servingsRange)
                        if let servings = plausibleServings(Int(servingsStr)) {
                            result.servings = servings
                        }
                    }
                }
            }
        }

        var ingredients: [String] = []

        let ingredientPattern = #"<li[^>]*class="[^"]*wprm-recipe-ingredient[^"]*"[^>]*>([\s\S]*?)</li>"#

        if let regex = try? NSRegularExpression(pattern: ingredientPattern, options: []) {
            let nsString = html as NSString
            let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))

            for match in matches {
                let liContent = nsString.substring(with: match.range)

                var amount = ""
                var unit = ""
                var name = ""
                var notes = ""

                // Capture the amount span's full inner HTML up to the sibling unit/name/notes span, so WPRM's nested fraction markup (1<span>1/4</span>) isn't truncated to "1" like the old ([^<]+).
                let amountBroadPattern = #"class="wprm-recipe-ingredient-amount"[^>]*>([\s\S]*?)</span>\s*<span[^>]*class="[^"]*wprm-recipe-ingredient-(?:unit|name|notes)"#
                if let amountRegex = try? NSRegularExpression(pattern: amountBroadPattern, options: []),
                   let firstMatch = amountRegex.firstMatch(in: liContent, options: [], range: NSRange(location: 0, length: (liContent as NSString).length)),
                   firstMatch.numberOfRanges > 1 {
                    let amountRange = firstMatch.range(at: 1)
                    let rawAmount = (liContent as NSString).substring(with: amountRange)
                    // Normalise spaces around fraction slashes: "1 / 4" → "1/4"
                    amount = inlineText(rawAmount).replacingOccurrences(of: #"\s*/\s*"#, with: "/", options: .regularExpression)
                }

                // Fallback for plain-text amounts with no sibling span (e.g. a bare <span>2</span></li>)
                if amount.isEmpty {
                    let amountSimplePattern = #"class="wprm-recipe-ingredient-amount"[^>]*>([^<\s][^<]*)<"#
                    if let amountRegex = try? NSRegularExpression(pattern: amountSimplePattern, options: []),
                       let firstMatch = amountRegex.firstMatch(in: liContent, options: [], range: NSRange(location: 0, length: (liContent as NSString).length)),
                       firstMatch.numberOfRanges > 1 {
                        let amountRange = firstMatch.range(at: 1)
                        amount = (liContent as NSString).substring(with: amountRange).trimmingCharacters(in: .whitespaces)
                    }
                }

                let unitPattern = #"class="wprm-recipe-ingredient-unit"[^>]*>([\s\S]*?)</span>"#
                if let unitRegex = try? NSRegularExpression(pattern: unitPattern, options: []) {
                    let unitMatches = unitRegex.matches(in: liContent, options: [], range: NSRange(location: 0, length: (liContent as NSString).length))
                    if let firstMatch = unitMatches.first, firstMatch.numberOfRanges > 1 {
                        unit = inlineText((liContent as NSString).substring(with: firstMatch.range(at: 1)))
                    }
                }

                let namePattern = #"class="wprm-recipe-ingredient-name"[^>]*>([\s\S]*?)</span>"#
                if let nameRegex = try? NSRegularExpression(pattern: namePattern, options: []) {
                    let nameMatches = nameRegex.matches(in: liContent, options: [], range: NSRange(location: 0, length: (liContent as NSString).length))
                    if let firstMatch = nameMatches.first, firstMatch.numberOfRanges > 1 {
                        name = inlineText((liContent as NSString).substring(with: firstMatch.range(at: 1)))
                    }
                }

                let notesPattern = #"class="wprm-recipe-ingredient-notes[^"]*"[^>]*>([\s\S]*?)</span>"#
                if let notesRegex = try? NSRegularExpression(pattern: notesPattern, options: []) {
                    let notesMatches = notesRegex.matches(in: liContent, options: [], range: NSRange(location: 0, length: (liContent as NSString).length))
                    if let firstMatch = notesMatches.first, firstMatch.numberOfRanges > 1 {
                        notes = inlineText((liContent as NSString).substring(with: firstMatch.range(at: 1)))
                    }
                }

                var fullIngredient = ""
                if !amount.isEmpty {
                    fullIngredient += amount + " "
                }
                if !unit.isEmpty {
                    fullIngredient += unit + " "
                }
                if !name.isEmpty {
                    fullIngredient += name
                }
                if !notes.isEmpty {
                    fullIngredient += ", " + notes
                }

                fullIngredient = decodeHTMLEntities(fullIngredient.trimmingCharacters(in: .whitespaces))

                if !fullIngredient.isEmpty && !ingredients.contains(fullIngredient) {
                    ingredients.append(fullIngredient)
                }
            }
        }

        result.ingredients = ingredients

        var instructions: [String] = []

        let instructionPattern = #"<li[^>]*class="[^"]*wprm-recipe-instruction[^"]*"[^>]*>([\s\S]*?)</li>"#

        if let regex = try? NSRegularExpression(pattern: instructionPattern, options: []) {
            let nsString = html as NSString
            let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))

            for match in matches {
                let liContent = nsString.substring(with: match.range)

                let textPattern = #"wprm-recipe-instruction-text[^>]*>([\s\S]*?)</div>"#
                if let textRegex = try? NSRegularExpression(pattern: textPattern, options: []) {
                    let textMatches = textRegex.matches(in: liContent, options: [], range: NSRange(location: 0, length: (liContent as NSString).length))

                    if let textMatch = textMatches.first {
                        let textRange = textMatch.range(at: 1)
                        var instruction = (liContent as NSString).substring(with: textRange)

                        instruction = decodeHTMLEntities(inlineText(instruction)).trimmed

                        if !instruction.isEmpty && instruction.count >= 10 {
                            instructions.append(instruction)
                        }
                    }
                }
            }
        }

        result.instructions = instructions

        if let cuisine = wprmText("wprm-recipe-cuisine[^>]*>([^<]+)<", in: html) { result.cuisine = cuisine }
        if let course = wprmText("wprm-recipe-course[^>]*>([^<]+)<", in: html) { result.category = course }

        if result.name != nil && !result.ingredients.isEmpty && !result.instructions.isEmpty {
            return result
        }

        if result.name != nil && !result.ingredients.isEmpty {
            let text = cleanHTML(html)
            let lines = nonBlankLines(text)
            let fallbackInstructions = extractInstructions(from: text, lines: lines)

            if !fallbackInstructions.isEmpty {
                result.instructions = fallbackInstructions
                return result
            }
        }

        return nil
    }

    /// Text of the first element matching `pattern` (its text in the first `>…<`), entity-decoded and trimmed — one
    /// path for name/cuisine/course so none of them skips decoding ("Caf&eacute;").
    private static func wprmText(_ pattern: String, in html: String) -> String? {
        guard let match = html.range(of: pattern, options: .regularExpression) else { return nil }
        let matched = html[match]
        guard let content = matched.range(of: ">([^<]+)<", options: .regularExpression) else { return nil }
        let text = decodeHTMLEntities(String(matched[content].dropFirst().dropLast())).trimmed
        return text.isEmpty ? nil : text
    }
}
