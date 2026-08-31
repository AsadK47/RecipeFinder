import Foundation

/// Schema.org JSON-LD parsing for `RecipeParser`. This is the highest-confidence
/// path: sites that embed `application/ld+json` Recipe data are parsed directly.
extension RecipeParser {

    static func extractJSONLD(from html: String) -> ParsedRecipe? {
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
            // Match "Recipe" regardless of whether the site emits the bare token or a
            // fully-qualified schema.org URL (e.g. "https://schema.org/Recipe"), and
            // regardless of case. Real sites use all of these forms.
            func matchesRecipe(_ type: String) -> Bool {
                let token = type.split(separator: "/").last.map(String.init) ?? type
                return token.caseInsensitiveCompare("Recipe") == .orderedSame
            }
            if let type = item["@type"] as? String {
                return matchesRecipe(type)
            } else if let types = item["@type"] as? [String] {
                return types.contains(where: matchesRecipe)
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
            result.instructions = flattenInstructionSteps(from: instructionsData)
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

    /// Recursively extracts individual instruction step strings from a `recipeInstructions` array.
    /// Handles flat `HowToStep` arrays, `HowToSection` containers, and mixed nesting.
    /// Previously, sections were collapsed with `.joined(separator: " ")`, losing step boundaries.
    private static func flattenInstructionSteps(from items: [Any]) -> [String] {
        var steps: [String] = []
        for item in items {
            if let str = item as? String {
                let decoded = decodeHTMLEntities(str.trimmingCharacters(in: .whitespacesAndNewlines))
                if decoded.count >= 10 { steps.append(decoded) }
            } else if let dict = item as? [String: Any] {
                // Resolve @type whether it's a String or [String]
                let typeStr: String
                if let t = dict["@type"] as? String {
                    typeStr = t
                } else if let ts = dict["@type"] as? [String] {
                    typeStr = ts.first ?? ""
                } else {
                    typeStr = ""
                }

                if typeStr == "HowToSection", let subItems = dict["itemListElement"] as? [Any] {
                    // Recurse into section — each section step becomes its own entry
                    steps.append(contentsOf: flattenInstructionSteps(from: subItems))
                } else if let text = dict["text"] as? String {
                    // HowToStep (or any dict with a "text" field)
                    let decoded = decodeHTMLEntities(text.trimmingCharacters(in: .whitespacesAndNewlines))
                    if decoded.count >= 10 { steps.append(decoded) }
                } else if let subItems = dict["itemListElement"] as? [Any] {
                    // Generic itemListElement fallback (unknown @type)
                    steps.append(contentsOf: flattenInstructionSteps(from: subItems))
                }
            }
        }
        return steps
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
}
