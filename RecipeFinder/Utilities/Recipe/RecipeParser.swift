
import Foundation

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

        result.imageURL = extractOGImage(from: html)
        result.confidence = confidenceScore / maxScore
        return result
    }
    
    private static func extractJSONLD(from html: String) -> ParsedRecipe? {
        let pattern = #"<script[^>]*type=["\']application/ld\+json["\'][^>]*>([\s\S]*?)</script>"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        
        let nsString = html as NSString
        let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            guard match.numberOfRanges > 1 else { continue }
            
            let jsonRange = match.range(at: 1)
            let jsonString = nsString.substring(with: jsonRange)
            
            guard let jsonData = jsonString.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: jsonData) else {
                continue
            }
            
            if let recipe = parseRecipeFromJSON(json) {
                return recipe
            }
        }
        
        return nil
    }
    
    private static func parseRecipeFromJSON(_ json: Any) -> ParsedRecipe? {
        var recipeData: [String: Any]?

        func isRecipeType(_ item: [String: Any]) -> Bool {
            if let type = item["@type"] as? String {
                return type == "Recipe"
            } else if let types = item["@type"] as? [String] {
                return types.contains("Recipe")
            }
            return false
        }

        if let dict = json as? [String: Any] {
            if isRecipeType(dict) {
                recipeData = dict
            } else if let graph = dict["@graph"] as? [[String: Any]] {
                recipeData = graph.first { isRecipeType($0) }
            }
        } else if let array = json as? [[String: Any]] {
            recipeData = array.first { isRecipeType($0) }
        }

        guard let data = recipeData else {
            return nil
        }
        
        var result = ParsedRecipe()
        result.confidence = 0.95
        
        if let name = data["name"] as? String {
            result.name = decodeHTMLEntities(name.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        if let description = data["description"] as? String {
            result.description = decodeHTMLEntities(description.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        if let ingredientsArray = data["recipeIngredient"] as? [Any] {
            result.ingredients = ingredientsArray.compactMap { ingredient in
                if let str = ingredient as? String {
                    return decodeHTMLEntities(str.trimmingCharacters(in: .whitespacesAndNewlines))
                } else if let dict = ingredient as? [String: Any], let text = dict["text"] as? String {
                    return decodeHTMLEntities(text.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                return nil
            }.filter { !$0.isEmpty }
        }
        
        if let instructionsData = data["recipeInstructions"] as? [Any] {
            result.instructions = instructionsData.compactMap { instruction in
                if let str = instruction as? String {
                    return decodeHTMLEntities(str.trimmingCharacters(in: .whitespacesAndNewlines))
                } else if let dict = instruction as? [String: Any] {
                    if let text = dict["text"] as? String {
                        return decodeHTMLEntities(text.trimmingCharacters(in: .whitespacesAndNewlines))
                    } else if let itemList = dict["itemListElement"] as? [[String: Any]] {
                        return decodeHTMLEntities(itemList.compactMap { step in
                            if let stepText = step["text"] as? String {
                                return stepText.trimmingCharacters(in: .whitespacesAndNewlines)
                            }
                            return nil
                        }.joined(separator: " "))
                    }
                }
                return nil
            }.filter { !$0.isEmpty && $0.count >= 10 }
        } else if let instructionsString = data["recipeInstructions"] as? String {
            let steps = instructionsString.components(separatedBy: .newlines)
                .map { decodeHTMLEntities($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
                .filter { !$0.isEmpty && $0.count >= 10 }
            result.instructions = steps
        }
        
        if let prepTime = data["prepTime"] as? String {
            result.prepTime = parseISO8601Duration(prepTime)
        }
        
        if let cookTime = data["cookTime"] as? String {
            result.cookTime = parseISO8601Duration(cookTime)
        }
        
        if let yield = data["recipeYield"] as? String {
            result.servings = extractServingsFromYield(yield)
        } else if let yieldInt = data["recipeYield"] as? Int {
            result.servings = yieldInt
        } else if let yieldArray = data["recipeYield"] as? [Any], let first = yieldArray.first {
            if let str = first as? String {
                result.servings = extractServingsFromYield(str)
            } else if let num = first as? Int {
                result.servings = num
            }
        }
        
        if let category = data["recipeCategory"] as? String {
            result.category = category
        } else if let categoryArray = data["recipeCategory"] as? [String], let first = categoryArray.first {
            result.category = first
        }
        
        if let cuisine = data["recipeCuisine"] as? String {
            result.cuisine = cuisine
        } else if let cuisineArray = data["recipeCuisine"] as? [String], let first = cuisineArray.first {
            result.cuisine = first
        }

        if let imageString = data["image"] as? String {
            result.imageURL = imageString
        } else if let imageDict = data["image"] as? [String: Any], let url = imageDict["url"] as? String {
            result.imageURL = url
        } else if let imageArray = data["image"] as? [Any] {
            if let first = imageArray.first as? String {
                result.imageURL = first
            } else if let first = imageArray.first as? [String: Any], let url = first["url"] as? String {
                result.imageURL = url
            }
        }

        // Return if we have at minimum a name + ingredients (instructions are a bonus)
        if result.name != nil && !result.ingredients.isEmpty {
            return result
        }

        return nil
    }
    
    private static func parseISO8601Duration(_ duration: String) -> Int? {
        let pattern = #"PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        
        let nsString = duration as NSString
        guard let match = regex.firstMatch(in: duration, options: [], range: NSRange(location: 0, length: nsString.length)) else {
            return nil
        }
        
        var totalMinutes = 0
        
        if match.numberOfRanges > 1 {
            let hoursRange = match.range(at: 1)
            if hoursRange.location != NSNotFound {
                let hoursStr = nsString.substring(with: hoursRange)
                if let hours = Int(hoursStr) {
                    totalMinutes += hours * 60
                }
            }
        }
        
        if match.numberOfRanges > 2 {
            let minutesRange = match.range(at: 2)
            if minutesRange.location != NSNotFound {
                let minutesStr = nsString.substring(with: minutesRange)
                if let minutes = Int(minutesStr) {
                    totalMinutes += minutes
                }
            }
        }
        
        return totalMinutes > 0 ? totalMinutes : nil
    }
    
    private static func extractServingsFromYield(_ yieldString: String) -> Int? {
        let pattern = #"(\d+)"#
        if let range = yieldString.range(of: pattern, options: .regularExpression),
           let servings = Int(yieldString[range]) {
            return servings
        }
        return nil
    }
    
    private static func extractWPRM(from html: String) -> ParsedRecipe? {
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
                
                let amountPattern = #"class="wprm-recipe-ingredient-amount">([^<]+)<"#
                if let amountRegex = try? NSRegularExpression(pattern: amountPattern, options: []) {
                    let amountMatches = amountRegex.matches(in: liContent, options: [], range: NSRange(location: 0, length: (liContent as NSString).length))
                    if let firstMatch = amountMatches.first, firstMatch.numberOfRanges > 1 {
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
    
    private static func cleanHTML(_ html: String) -> String {
        var text = html
        
        text = text.replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?</script>", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?</style>", with: "", options: .regularExpression)
        
        text = text.replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "</p>", with: "\n\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "</div>", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "</li>", with: "\n", options: .regularExpression)
        
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        text = decodeHTMLEntities(text)
        
        text = text.replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\n\\s*\\n\\s*\\n+", with: "\n\n", options: .regularExpression)
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    nonisolated(unsafe) private static var entityCache: [String: String] = [:]
    
    private static func decodeHTMLEntities(_ text: String) -> String {
        if let cached = entityCache[text] {
            return cached
        }

        // Use NSAttributedString to decode all named and numeric HTML entities
        // (e.g. &eacute; → é, &amp; → &, &#233; → é)
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
            
            for (range, replacement) in replacements.reversed() {
                let start = result.index(result.startIndex, offsetBy: range.location)
                let end = result.index(start, offsetBy: range.length)
                result.replaceSubrange(start..<end, with: replacement)
            }
        }
        
        if entityCache.count < 100 {
            entityCache[text] = result
        } else if entityCache.count > 150 {
            let keepCount = 75
            let keysToKeep = Array(entityCache.keys.prefix(keepCount))
            entityCache = entityCache.filter { keysToKeep.contains($0.key) }
        }
        
        return result
    }
    
    private static func extractRecipeName(from html: String, text: String) -> String? {
        if let titleMatch = html.range(of: "<title[^>]*>([^<]+)</title>", options: .regularExpression) {
            var title = String(html[titleMatch])
            title = title.replacingOccurrences(of: "<title[^>]*>", with: "", options: .regularExpression)
            title = title.replacingOccurrences(of: "</title>", with: "")
            title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let suffixes = [" - Recipe", " Recipe", " | RecipeName", " - Cooking", " | Food"]
            for suffix in suffixes {
                if title.hasSuffix(suffix) {
                    title = String(title.dropLast(suffix.count))
                }
            }
            
            if !title.isEmpty && title.count < 100 {
                return title
            }
        }
        
        if let h1Match = html.range(of: "<h1[^>]*>([^<]+)</h1>", options: .regularExpression) {
            var h1 = String(html[h1Match])
            h1 = h1.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            h1 = h1.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !h1.isEmpty && h1.count < 100 {
                return h1
            }
        }
        
        if let firstLine = text.components(separatedBy: .newlines).first(where: { !$0.isEmpty && $0.count < 100 }) {
            return firstLine
        }
        
        return nil
    }
    
    private static func extractDescription(from text: String, lines: [String]) -> String? {
        var descriptionLines: [String] = []
        
        for (index, line) in lines.enumerated() {
            if index == 0 { continue }
            
            if line.lowercased().contains("ingredient") || isIngredientLine(line) {
                break
            }
            
            if line.count > 30 && line.count < 300 && !line.hasPrefix("-") && !line.hasPrefix("•") {
                descriptionLines.append(line)
            }
            
            if descriptionLines.count >= 3 { break }
        }
        
        if !descriptionLines.isEmpty {
            return descriptionLines.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return nil
    }
    
    enum TimeType {
        case prep
        case cook
        case total
    }
    
    private static func extractTime(from text: String, type: TimeType) -> Int? {
        let patterns: [String]
        
        switch type {
        case .prep:
            patterns = [
                "prep time:?\\s*([0-9]+)\\s*(min|minute|minutes|hour|hours|hr|hrs)",
                "preparation time:?\\s*([0-9]+)\\s*(min|minute|minutes|hour|hours|hr|hrs)"
            ]
        case .cook:
            patterns = [
                "cook time:?\\s*([0-9]+)\\s*(min|minute|minutes|hour|hours|hr|hrs)",
                "cooking time:?\\s*([0-9]+)\\s*(min|minute|minutes|hour|hours|hr|hrs)",
                "bake time:?\\s*([0-9]+)\\s*(min|minute|minutes|hour|hours|hr|hrs)"
            ]
        case .total:
            patterns = [
                "total time:?\\s*([0-9]+)\\s*(min|minute|minutes|hour|hours|hr|hrs)"
            ]
        }
        
        for pattern in patterns {
            if let range = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let match = String(text[range])
                if let valueRange = match.range(of: "[0-9]+", options: .regularExpression),
                   let value = Int(match[valueRange]) {
                    
                    if match.lowercased().contains("hour") || match.lowercased().contains("hr") {
                        return value * 60
                    }
                    return value
                }
            }
        }
        
        return nil
    }
    
    private static func extractServings(from text: String) -> Int? {
        let patterns = [
            "serves:?\\s*([0-9]+)",
            "servings:?\\s*([0-9]+)",
            "yield:?\\s*([0-9]+)\\s*servings",
            "makes:?\\s*([0-9]+)\\s*servings"
        ]
        
        for pattern in patterns {
            if let range = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let match = String(text[range])
                if let valueRange = match.range(of: "[0-9]+", options: .regularExpression),
                   let value = Int(match[valueRange]) {
                    return value
                }
            }
        }
        
        return nil
    }
    
    private static func extractIngredients(from text: String, lines: [String]) -> [String] {
        var ingredients: [String] = []
        var uniqueIngredients = Set<String>()
        var inIngredientSection = false
        var emptyLineCount = 0
        var foundFirstIngredient = false
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmed.isEmpty {
                if inIngredientSection && foundFirstIngredient {
                    emptyLineCount += 1
                    if emptyLineCount >= 3 {
                        break
                    }
                }
                continue
            } else {
                emptyLineCount = 0
            }
            
            if trimmed.lowercased().contains("ingredient") && trimmed.count < 50 {
                if ingredients.count > 5 {
                    break
                }
                inIngredientSection = true
                continue
            }
            
            if inIngredientSection && foundFirstIngredient {
                let lower = trimmed.lowercased()
                if lower.contains("instruction") || 
                   lower.contains("method") ||
                   lower.contains("direction") ||
                   lower.contains("notes") ||
                   lower.contains("nutrition") ||
                   lower.contains("calories:") ||
                   lower.starts(with: "prep time") ||
                   lower.starts(with: "cook time") ||
                   lower.starts(with: "total time") {
                    break
                }
            }
            
            if inIngredientSection && isIngredientLine(trimmed) {
                let cleaned = cleanIngredientLine(trimmed)
                if !cleaned.isEmpty {
                    let normalizedKey = cleaned.lowercased()
                    if !uniqueIngredients.contains(normalizedKey) {
                        ingredients.append(cleaned)
                        uniqueIngredients.insert(normalizedKey)
                        foundFirstIngredient = true
                    }
                }
            }
        }
        
        return ingredients
    }
    
    private static func isIngredientLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard trimmed.count >= 3 && trimmed.count < 200 else { return false }
        
        let indicators = [
            "cup", "cups", "tbsp", "tsp", "teaspoon", "tablespoon", "oz", "ounce", "lb", "pound",
            "gram", "grams", "kg", "kilogram", "ml", "milliliter", "liter", "l",
            "clove", "cloves", "pinch", "dash", "sprig", "bunch", "piece", "pieces", "slice", "slices",
            "diced", "chopped", "sliced", "minced", "crushed", "grated", "shredded",
            "fresh", "dried", "frozen", "canned", "whole", "ground",
            "optional", "to taste", "as needed", "for serving",
            "½", "¼", "¾", "⅓", "⅔", "⅛", "⅜", "⅝", "⅞"
        ]
        
        let lowercased = trimmed.lowercased()
        
        for indicator in indicators {
            if lowercased.contains(indicator) {
                return true
            }
        }
        
        let numberPattern = "^[0-9]|\\s[0-9]|^[½¼¾⅓⅔⅛⅜⅝⅞]|\\s[½¼¾⅓⅔⅛⅜⅝⅞]"
        if lowercased.range(of: numberPattern, options: .regularExpression) != nil {
            return true
        }
        
        if trimmed.count < 80 {
            let foodWords = ["oil", "salt", "pepper", "sugar", "butter", "egg", "flour", "water", "milk", "cheese", "onion", "garlic", "tomato", "chicken", "beef", "pork", "rice", "pasta"]
            for food in foodWords {
                if lowercased.contains(food) {
                    return true
                }
            }
        }
        
        return false
    }
    
    private static func isLikelyIngredient(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = trimmed.lowercased()
        
        let excludePatterns = ["ingredient", "instruction", "method", "step", "nutrition", "calories", "print", "save", "share", "comment", "recipe by", "posted", "updated"]
        for pattern in excludePatterns {
            if lowercased == pattern || lowercased.starts(with: pattern + ":") {
                return false
            }
        }
        
        return isIngredientLine(line)
    }
    
    private static func isIngredientLineOld(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard trimmed.count >= 3 && trimmed.count < 200 else { return false }
        
        let indicators = [
            "cup", "tbsp", "tsp", "oz", "lb", "gram", "kg", "ml", "liter",
            "clove", "pinch", "dash", "sprig", "bunch", "piece", "slice",
            "diced", "chopped", "sliced", "minced", "crushed", "grated"
        ]
        
        let lowercased = trimmed.lowercased()
        for indicator in indicators {
            if lowercased.contains(indicator) {
                return true
            }
        }
        
        let normalized = IngredientNormalizer.normalize(trimmed)
        if normalized != trimmed.capitalized && !normalized.isEmpty {
            return true
        }
        
        if trimmed.range(of: "[0-9]", options: .regularExpression) != nil {
            return true
        }
        
        return false
    }
    
    private static func cleanIngredientLine(_ line: String) -> String {
        var cleaned = line
        
        cleaned = cleaned.replacingOccurrences(of: "^[•\\-*]\\s*", with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "^[0-9]+\\.\\s*", with: "", options: .regularExpression)
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private static func extractInstructions(from text: String, lines: [String]) -> [String] {
        var instructions: [String] = []
        var uniqueInstructions = Set<String>()
        var inInstructionSection = false
        var emptyLineCount = 0
        var foundFirstInstruction = false
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmed.isEmpty {
                if inInstructionSection && foundFirstInstruction {
                    emptyLineCount += 1
                    if emptyLineCount >= 3 {
                        break
                    }
                }
                continue
            } else {
                emptyLineCount = 0
            }
            
            if (trimmed.lowercased().contains("instruction") || 
                trimmed.lowercased().contains("method") ||
                trimmed.lowercased().contains("direction")) && trimmed.count < 50 {
                if instructions.count > 3 {
                    break
                }
                inInstructionSection = true
                continue
            }
            
            if inInstructionSection && foundFirstInstruction {
                let lower = trimmed.lowercased()
                if lower.contains("notes") ||
                   lower.contains("nutrition") ||
                   lower.contains("calories:") ||
                   lower.starts(with: "did you make") {
                    break
                }
            }
            
            if inInstructionSection && isInstructionLine(trimmed) {
                let cleaned = cleanInstructionLine(trimmed)
                if !cleaned.isEmpty {
                    let normalizedKey = cleaned.lowercased()
                    if !uniqueInstructions.contains(normalizedKey) {
                        instructions.append(cleaned)
                        uniqueInstructions.insert(normalizedKey)
                        foundFirstInstruction = true
                    }
                }
            }
        }
        
        return instructions
    }
    
    private static func isInstructionLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard trimmed.count >= 10 && trimmed.count < 500 else { return false }
        
        let lowercased = trimmed.lowercased()
        let excludeHeaders = ["instructions:", "method:", "directions:", "steps:", "preparation:"]
        for header in excludeHeaders {
            if lowercased == header.replacingOccurrences(of: ":", with: "") {
                return false
            }
        }
        
        let actionVerbs = [
            "add", "mix", "stir", "cook", "bake", "heat", "boil", "simmer",
            "chop", "dice", "slice", "pour", "place", "remove", "combine",
            "preheat", "transfer", "serve", "garnish", "season", "prepare",
            "whisk", "blend", "fold", "sauté", "fry", "roast", "grill",
            "melt", "cut", "drain", "rinse", "arrange", "sprinkle", "drizzle",
            "bring", "reduce", "increase", "lower", "raise", "flip", "turn",
            "cover", "uncover", "let", "allow", "wait", "set aside",
            "brush", "coat", "dip", "toss", "roll", "spread", "layer"
        ]
        
        for verb in actionVerbs {
            if lowercased.starts(with: verb + " ") || lowercased.starts(with: verb + "s ") {
                return true
            }
        }
        
        let cookingPhrases = [
            "until", "for about", "minutes", "hours", "degrees", "°f", "°c",
            "in a", "on a", "into the", "to the", "with the",
            "and cook", "and bake", "and stir", "then add", "then place"
        ]
        
        for phrase in cookingPhrases {
            if lowercased.contains(phrase) && trimmed.count > 20 {
                return true
            }
        }
        
        if trimmed.contains(".") || trimmed.contains(",") {
            for verb in actionVerbs {
                if lowercased.contains(" \(verb) ") || lowercased.contains(" \(verb)s ") {
                    return true
                }
            }
        }
        
        return false
    }
    
    private static func cleanInstructionLine(_ line: String) -> String {
        var cleaned = line
        
        cleaned = cleaned.replacingOccurrences(of: "^[•\\-*]\\s*", with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "^Step\\s*[0-9]+[:.)]?\\s*", with: "", options: [.regularExpression, .caseInsensitive])
        cleaned = cleaned.replacingOccurrences(of: "^[0-9]+[:.)]\\s*", with: "", options: .regularExpression)
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private static func extractDifficulty(from text: String) -> String? {
        let difficulties = ["easy", "medium", "moderate", "hard", "difficult", "beginner", "intermediate", "advanced"]
        
        let lowercased = text.lowercased()
        for difficulty in difficulties {
            if lowercased.range(of: "difficulty:?\\s*\(difficulty)", options: .regularExpression) != nil ||
               lowercased.range(of: "level:?\\s*\(difficulty)", options: .regularExpression) != nil {
                return difficulty.capitalized
            }
        }
        
        return nil
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
}
