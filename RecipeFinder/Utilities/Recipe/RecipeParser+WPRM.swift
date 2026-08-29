import Foundation

/// WP Recipe Maker (WPRM) parsing for `RecipeParser`. Many WordPress food blogs
/// emit `wprm-recipe-*` markup; this extracts structured fields from it and falls
/// back to the text heuristics for instructions when needed.
extension RecipeParser {

    static func extractWPRM(from html: String) -> ParsedRecipe? {
        guard html.contains("wprm-recipe") || html.contains("wp-recipe-maker") else {
            return nil
        }

        var result = ParsedRecipe()
        result.confidence = 0.95

        if let nameMatch = html.range(of: "class=\"wprm-recipe-name[^\"]*\">([^<]+)<", options: .regularExpression) {
            let matched = String(html[nameMatch])
            if let contentRange = matched.range(of: ">([^<]+)<", options: .regularExpression) {
                var name = String(matched[contentRange])
                    .replacingOccurrences(of: ">", with: "")
                    .replacingOccurrences(of: "<", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                name = decodeHTMLEntities(name)
                result.name = name
            }
        }

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
                    if let servings = Int(servingsStr), servings >= 1 && servings <= 100 {
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
                        if let servings = Int(servingsStr), servings >= 1 && servings <= 100 {
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

                // Broad pattern: captures all inner HTML of the amount span up to the closing </span>
                // that is immediately followed by the unit/name/notes sibling span.
                // This handles WPRM's nested fraction HTML, e.g.:
                //   1<span class="wprm-recipe-fraction"><span>1</span>/<span>4</span></span>
                // where the old ([^<]+) pattern would only capture "1", dropping the "/4".
                let amountBroadPattern = #"class="wprm-recipe-ingredient-amount"[^>]*>([\s\S]*?)</span>\s*<span[^>]*class="[^"]*wprm-recipe-ingredient-(?:unit|name|notes)"#
                if let amountRegex = try? NSRegularExpression(pattern: amountBroadPattern, options: []),
                   let firstMatch = amountRegex.firstMatch(in: liContent, options: [], range: NSRange(location: 0, length: (liContent as NSString).length)),
                   firstMatch.numberOfRanges > 1 {
                    let amountRange = firstMatch.range(at: 1)
                    var rawAmount = (liContent as NSString).substring(with: amountRange)
                    // Replace tags with a space so mixed numbers like 1<span>1/4</span> become "1 1/4"
                    rawAmount = rawAmount.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
                    // Normalise spaces around fraction slashes: "1 / 4" → "1/4"
                    rawAmount = rawAmount.replacingOccurrences(of: #"\s*/\s*"#, with: "/", options: .regularExpression)
                    rawAmount = rawAmount.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                    amount = rawAmount.trimmingCharacters(in: .whitespaces)
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

                let unitPattern = #"class="wprm-recipe-ingredient-unit">([^<]+)<"#
                if let unitRegex = try? NSRegularExpression(pattern: unitPattern, options: []) {
                    let unitMatches = unitRegex.matches(in: liContent, options: [], range: NSRange(location: 0, length: (liContent as NSString).length))
                    if let firstMatch = unitMatches.first, firstMatch.numberOfRanges > 1 {
                        let unitRange = firstMatch.range(at: 1)
                        unit = (liContent as NSString).substring(with: unitRange).trimmingCharacters(in: .whitespaces)
                    }
                }

                let namePattern = #"class="wprm-recipe-ingredient-name">([^<]+)<"#
                if let nameRegex = try? NSRegularExpression(pattern: namePattern, options: []) {
                    let nameMatches = nameRegex.matches(in: liContent, options: [], range: NSRange(location: 0, length: (liContent as NSString).length))
                    if let firstMatch = nameMatches.first, firstMatch.numberOfRanges > 1 {
                        let nameRange = firstMatch.range(at: 1)
                        name = (liContent as NSString).substring(with: nameRange).trimmingCharacters(in: .whitespaces)
                    }
                }

                let notesPattern = #"class="wprm-recipe-ingredient-notes[^\"]*\">([^<]+)<"#
                if let notesRegex = try? NSRegularExpression(pattern: notesPattern, options: []) {
                    let notesMatches = notesRegex.matches(in: liContent, options: [], range: NSRange(location: 0, length: (liContent as NSString).length))
                    if let firstMatch = notesMatches.first, firstMatch.numberOfRanges > 1 {
                        let notesRange = firstMatch.range(at: 1)
                        notes = (liContent as NSString).substring(with: notesRange).trimmingCharacters(in: .whitespaces)
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

                        instruction = instruction.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
                        instruction = instruction.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                        instruction = decodeHTMLEntities(instruction)
                        instruction = instruction.trimmingCharacters(in: .whitespacesAndNewlines)

                        if !instruction.isEmpty && instruction.count >= 10 {
                            instructions.append(instruction)
                        }
                    }
                }
            }
        }

        result.instructions = instructions

        if let cuisineMatch = html.range(of: "wprm-recipe-cuisine[^>]*>([^<]+)<", options: .regularExpression) {
            let matched = String(html[cuisineMatch])
            if let contentRange = matched.range(of: ">([^<]+)<", options: .regularExpression) {
                let cuisine = String(matched[contentRange])
                    .replacingOccurrences(of: ">", with: "")
                    .replacingOccurrences(of: "<", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                result.cuisine = cuisine
            }
        }

        if let courseMatch = html.range(of: "wprm-recipe-course[^>]*>([^<]+)<", options: .regularExpression) {
            let matched = String(html[courseMatch])
            if let contentRange = matched.range(of: ">([^<]+)<", options: .regularExpression) {
                let course = String(matched[contentRange])
                    .replacingOccurrences(of: ">", with: "")
                    .replacingOccurrences(of: "<", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                result.category = course
            }
        }

        if result.name != nil && !result.ingredients.isEmpty && !result.instructions.isEmpty {
            return result
        }

        if result.name != nil && !result.ingredients.isEmpty {
            let text = cleanHTML(html)
            let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            let fallbackInstructions = extractInstructions(from: text, lines: lines)

            if !fallbackInstructions.isEmpty {
                result.instructions = fallbackInstructions
                return result
            }
        }

        return nil
    }
}
