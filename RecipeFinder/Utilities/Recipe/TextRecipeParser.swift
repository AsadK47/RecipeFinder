import Foundation

/// Parses free-form recipe text (notes, captions, messages) into wizard prefill: S1 splits on loose section headers ("INGREDIENTS 👇", "Method:"), filling any missing section via S2 line classification (quantity/bullet/emoji = ingredient, numbered/imperative = instruction).
enum TextRecipeParser {

    static func parse(_ text: String) -> RecipeWizardView.PrefilledRecipeData? {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard lines.count >= 3 else { return nil }

        let servings = RecipeParser.plausibleServings(firstIntMatch(#"(?:serves|servings?|yield)\s*:?\s*(\d+)"#, in: text))
        // "time" optional so "Prep 20 minutes" resolves; extractMinutes handles hours so "2 hours" → 120, not 2.
        let prepTime = extractMinutes(#"prep(?:aration)?(?:\s*time)?\s*:?\s*(\d+)"#, in: text)
        let cookTime = extractMinutes(#"cook(?:ing)?(?:\s*time)?\s*:?\s*(\d+)"#, in: text)

        var ingredients: [String]
        var instructions: [String]

        if let sections = splitBySectionHeaders(lines) {
            ingredients = sections.ingredients
            instructions = mergeInstructionLines(sections.instructions)
            // If only one section was found via headers, fill the other via line classification.
            if ingredients.isEmpty || instructions.isEmpty {
                let classified = classifyLines(lines)
                if ingredients.isEmpty { ingredients = classified.ingredients }
                if instructions.isEmpty { instructions = mergeInstructionLines(classified.instructions) }
            }
        } else {
            (ingredients, instructions) = classifyLines(lines)
            instructions = mergeInstructionLines(instructions)
        }

        // Drop footnotes on the raw line first (before markers stripped) so a leading "*" footnote is recognisable.
        ingredients = ingredients.filter { !isAsideLine($0) }.map(stripListMarker).filter { !$0.isEmpty && !isMetadataLine($0) }
        // isMetadataLine NOT applied to instructions: a merged step like "Prep the tin…10 minutes" would be wrongly dropped.
        instructions = instructions.filter { !isAsideLine($0) }.map(stripListMarker).filter { !$0.isEmpty }

        guard !ingredients.isEmpty, !instructions.isEmpty else { return nil }

        return RecipeWizardView.PrefilledRecipeData(
            name: title(from: lines),
            description: nil,
            ingredients: ingredients,
            instructions: instructions,
            prepTime: prepTime,
            cookTime: cookTime,
            servings: servings,
            difficulty: nil,
            notes: nil,
            category: nil,
            isFavorite: nil,
            imageURL: nil
        )
    }

    // MARK: - Title

    private static func title(from lines: [String]) -> String? {
        let candidates = lines.filter { !isSectionHeader($0) && !isMetadataLine($0) }
        guard let first = candidates.first else { return nil }

        var cleaned = stripTrailingBullets(stripLeadingBullets(first))
            .replacingOccurrences(of: #"^(recipe\s*:?\s*)"#, with: "", options: [.regularExpression, .caseInsensitive])
            .trimmingCharacters(in: .whitespaces)
        guard cleaned.count <= 80, !looksLikeIngredient(cleaned) else { return nil }

        // OCR may split a wrapped ALL-CAPS title across two lines; merge line 2 when both are short, all-caps, digit-free.
        if candidates.count >= 2 {
            let raw2 = candidates[1].trimmingCharacters(in: .whitespaces)
            let isAllCaps1 = cleaned == cleaned.uppercased() && cleaned.contains(where: { $0.isLetter })
            let isAllCaps2 = raw2 == raw2.uppercased() && raw2.contains(where: { $0.isLetter })
            let noDigits2 = !raw2.contains(where: { $0.isNumber })
            let combined = cleaned + " " + raw2
            if isAllCaps1 && isAllCaps2 && noDigits2 && raw2.count <= 25 && combined.count <= 70
                && !looksLikeIngredient(raw2) {
                cleaned = combined
            }
        }

        // Convert ALL CAPS cookbook headers to title case so they don't shout at the user.
        if cleaned == cleaned.uppercased() && cleaned.contains(where: { $0.isLetter }) {
            cleaned = cleaned.localizedCapitalized
        }

        return cleaned.trimmingCharacters(in: .whitespaces).isEmpty ? nil : cleaned.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Section-header strategy

    private static func splitBySectionHeaders(_ lines: [String]) -> (ingredients: [String], instructions: [String])? {
        var ingredientLines: [String] = []
        var instructionLines: [String] = []
        var current: Section?

        for line in lines {
            if matchesHeader(line, keywords: ingredientHeaderKeywords) {
                current = .ingredients
                continue
            }
            if matchesHeader(line, keywords: instructionHeaderKeywords) {
                current = .instructions
                continue
            }

            switch current {
            case .ingredients: ingredientLines.append(line)
            case .instructions: instructionLines.append(line)
            case nil: break
            }
        }

        guard !ingredientLines.isEmpty || !instructionLines.isEmpty else { return nil }
        return (ingredientLines, instructionLines)
    }

    private enum Section {
        case ingredients
        case instructions
    }

    private static let ingredientHeaderKeywords = [
        "ingredients", "you will need", "you'll need", "what you need", "what you'll need",
        "garnish", "for the garnish", "to serve", "to garnish",
        // Alternative terms used on international and content-creator recipe sites
        "material", "materials",
        // Common recipe sub-sections (exact-match after normalization is safe here)
        "marinade", "for the marinade", "sauce", "for the sauce",
        "filling", "for the filling", "dough", "for the dough",
        "batter", "for the batter", "topping", "toppings",
        "frosting", "icing", "glaze", "crust", "base", "coating"
    ]
    private static let instructionHeaderKeywords = [
        "instructions", "method", "directions", "steps", "preparation",
        "direction",          // singular — seen in some scraped recipes
        "before you start",   // bosh.tv recipe format
        "how to make", "how to", "procedure",
        "to cook", "to prepare", "to make", "make it",
        "cooking order",      // used on some Chinese/Korean recipe sites
        "method of preparation"
    ]

    private static func isSectionHeader(_ line: String) -> Bool {
        matchesHeader(line, keywords: ingredientHeaderKeywords + instructionHeaderKeywords)
    }

    /// Loose match: reduce line to letters/spaces and compare to keyword, so "INGREDIENTS 👇"/"Method:" match but a longer phrase like "Ingredients you'll need for the base" doesn't.
    private static func matchesHeader(_ line: String, keywords: [String]) -> Bool {
        let normalized = normalizedHeader(line)
        guard !normalized.isEmpty else { return false }
        return keywords.map(normalizedHeader).contains(normalized)
    }

    private static func normalizedHeader(_ line: String) -> String {
        let lettersAndSpaces = String(String.UnicodeScalarView(
            line.unicodeScalars.map { CharacterSet.letters.contains($0) ? $0 : " " }
        ))
        return lettersAndSpaces
            .lowercased()
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Line-classification strategy

    private static func classifyLines(_ lines: [String]) -> (ingredients: [String], instructions: [String]) {
        var ingredients: [String] = []
        var instructions: [String] = []
        // Captions sometimes repeat the title on line 2 ("Margaritas\nMargaritas\n…"); skip it so it can't merge into the first real step.
        let normalizedTitle = stripListMarker(lines.first ?? "").lowercased()

        // Skip the title line when classifying.
        for line in lines.dropFirst() where !isMetadataLine(line) {
            let stripped = stripListMarker(line)
            guard !stripped.isEmpty else { continue }
            if stripped.lowercased() == normalizedTitle && !looksLikeIngredient(line) { continue }

            // Numbered steps take priority (digit-led, else they'd match looksLikeIngredient); anything non-ingredient defaults to instruction, no verb whitelist.
            if looksLikeNumberedStep(line) {
                instructions.append(line)
            } else if looksLikeIngredient(line) {
                ingredients.append(line)
            } else {
                instructions.append(line)
            }
        }

        return (ingredients, instructions)
    }

    private static func looksLikeIngredient(_ line: String) -> Bool {
        // Quantity-led ("2 cups flour"), bulleted ("- flour"), or emoji-led ("🧄 garlic").
        line.range(of: #"^[-•*]?\s*(\d|["# + RecipeParser.unicodeFractionCharacters + "])", options: .regularExpression) != nil
            || line.range(of: #"^[-•*]\s+\S"#, options: .regularExpression) != nil
            || startsWithBullet(line)
    }

    private static func looksLikeNumberedStep(_ line: String) -> Bool {
        // "1. Preheat…", "2) Mix…", "Step 3: …"
        // `(?!\d)` so a decimal amount ("1.75 tbsp ghee") isn't read as list marker "1.".
        if line.range(of: #"^(step\s+\d+|\d+[\.\)](?!\d))\s*"#, options: [.regularExpression, .caseInsensitive]) != nil {
            return true
        }
        // OCR drops the period ("1 Preheat oven…"); case-sensitive so "2 cups flour" isn't mistaken for a step.
        return line.range(of: #"^\d+\s+[A-Z][a-z]"#, options: .regularExpression) != nil
    }

    // MARK: - Cleanup

    private static func stripListMarker(_ line: String) -> String {
        let withoutNumber = line.replacingOccurrences(
            of: #"^(step\s+\d+\s*[:\.\)]?|\d+[\.\)](?!\d))\s*"#,
            with: "", options: [.regularExpression, .caseInsensitive]
        )
        return stripLeadingBullets(withoutNumber).trimmingCharacters(in: .whitespaces)
    }

    private static func stripLeadingBullets(_ s: String) -> String {
        let chars = Array(s)
        var i = 0
        while i < chars.count, chars[i].isWhitespace || isBulletCharacter(chars[i]) { i += 1 }
        return String(chars[i...])
    }

    private static func stripTrailingBullets(_ s: String) -> String {
        let chars = Array(s)
        var j = chars.count
        while j > 0, chars[j - 1].isWhitespace || isBulletCharacter(chars[j - 1]) { j -= 1 }
        return String(chars[0..<j])
    }

    private static func startsWithBullet(_ line: String) -> Bool {
        guard let first = line.drop(while: { $0.isWhitespace }).first else { return false }
        return isBulletCharacter(first)
    }

    /// A leading decoration (dash/star bullet or emoji), never a letter/digit/fraction (those are content to keep).
    private static func isBulletCharacter(_ c: Character) -> Bool {
        if c.isLetter || c.isNumber { return false }
        if "-•*▪◦‣·▫●○▶►➤➥➢▢□☐◻◽◾◼".contains(c) { return true }
        // Emoji, but not low-codepoint symbols like fractions or punctuation.
        return c.unicodeScalars.contains { $0.properties.isEmoji && ($0.value > 0x238C || $0.properties.isEmojiPresentation) }
    }

    /// Footnotes/asides that aren't ingredient or step: a "Note:"/"Tip:" line or a "*"-glued footnote; a spaced "* " bullet ("* 2 eggs") is real content and is NOT matched.
    private static func isAsideLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.range(of: #"^(note|notes|tip|tips)\b\s*[:.\-]"#, options: [.regularExpression, .caseInsensitive]) != nil
            || trimmed.range(of: #"^\*[^\s*]"#, options: .regularExpression) != nil
    }

    /// Non-ingredient sidebar/metadata lines OCR/captions mix in (servings, times, lone labels/numbers) so they never become "ingredients".
    private static func isMetadataLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let patterns = [
            #"^\d+$"#,                                                   // lone number ("2" under SERVES)
            #"^(time|serves|servings?)$"#,                               // lone label
            #"^(serves|servings?|yield)\b"#,                             // "Serves 2", "Yield: 4"
            #"^(prep(?:aration)?|cook(?:ing)?|total)\b.*\b(min|mins|minute|minutes|hour|hours|hr|hrs)\b"#  // "Prep 20 minutes"
        ]
        return patterns.contains {
            trimmed.range(of: $0, options: [.regularExpression, .caseInsensitive]) != nil
        }
    }

    // MARK: - Instruction line merging

    /// Joins OCR/column-wrapped lines into logical steps (one OCR observation per physical line would otherwise fragment a step): new step begins only when the previous line ended in .!? and this one starts uppercase, or it's an explicit numbered step.
    private static func mergeInstructionLines(_ lines: [String]) -> [String] {
        guard !lines.isEmpty else { return [] }
        var steps: [String] = []
        var current = lines[0]
        for line in lines.dropFirst() {
            if beginsNewStep(line, afterLine: current) {
                steps.append(current)
                current = line
            } else {
                // Lowercase-start or mid-sentence wrap: rejoin with a space.
                current = current + " " + line
            }
        }
        steps.append(current)
        return steps
    }

    private static func beginsNewStep(_ line: String, afterLine previous: String) -> Bool {
        if looksLikeNumberedStep(line) { return true }
        let prevEndsSentence = ".!?".contains(previous.last ?? " ")
        return prevEndsSentence && (line.first?.isUppercase ?? false)
    }

    /// Time in minutes after a label (pattern must capture the number in group 1): the regex only finds the duration's span
    /// ("2 hours", "1 hr 30 min", bare "45"); `TimeExtractor` does the unit maths.
    private static func extractMinutes(_ pattern: String, in text: String) -> Int? {
        let withUnit = pattern + #"(?:\s*(?:h(?:r|rs|our|ours)?|m(?:in|ins|inute|inutes)?)\b)?(?:\s*\d+\s*m(?:in|ins|inute|inutes)?\b)?"#
        guard let regex = try? NSRegularExpression(pattern: withUnit, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
              let numRange = Range(match.range(at: 1), in: text),
              let matchRange = Range(match.range, in: text) else { return nil }
        return TimeExtractor.extractMinutes(from: String(text[numRange.lowerBound..<matchRange.upperBound]))
    }

    private static func firstIntMatch(_ pattern: String, in text: String) -> Int? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              match.numberOfRanges > 1,
              let valueRange = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return Int(text[valueRange])
    }
}
