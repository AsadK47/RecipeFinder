import Foundation

/// Parses free-form recipe text — pasted notes, social media captions,
/// shared messages — into wizard prefill data for the user to review.
///
/// Two strategies, tried in order:
/// 1. Section headers ("Ingredients", "Instructions"/"Method"/"Directions"/
///    "Steps") split the text explicitly. Headers are matched loosely so
///    caption styling like "INGREDIENTS 👇" or "what you need" still counts.
///    If only one section is found via headers, the other is filled by
///    strategy 2 (see supplement step).
/// 2. Without headers, each line is classified: quantity-, bullet-, or
///    emoji-led lines are ingredients; numbered or imperative ("Melt the
///    butter…") lines are instructions.
enum TextRecipeParser {

    static func parse(_ text: String) -> RecipeWizardView.PrefilledRecipeData? {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard lines.count >= 3 else { return nil }

        let servings = firstIntMatch(#"(?:serves|servings?|yield)\s*:?\s*(\d+)"#, in: text)
        // "time" is optional so a sidebar "Prep 20 minutes" / "Cook 30 mins" still
        // resolves (many printed recipes omit the word "time").
        let prepTime = firstIntMatch(#"prep(?:aration)?(?:\s*time)?\s*:?\s*(\d+)"#, in: text)
        let cookTime = firstIntMatch(#"cook(?:ing)?(?:\s*time)?\s*:?\s*(\d+)"#, in: text)

        var ingredients: [String]
        var instructions: [String]

        if let sections = splitBySectionHeaders(lines) {
            ingredients = sections.ingredients
            instructions = mergeInstructionLines(sections.instructions)
            // Supplement: if only one section was found via headers, fill the
            // other via line classification (e.g. ingredients listed under a
            // recognised header but method is unnumbered prose, or vice versa).
            if ingredients.isEmpty || instructions.isEmpty {
                let classified = classifyLines(lines)
                if ingredients.isEmpty { ingredients = classified.ingredients }
                if instructions.isEmpty { instructions = mergeInstructionLines(classified.instructions) }
            }
        } else {
            (ingredients, instructions) = classifyLines(lines)
            instructions = mergeInstructionLines(instructions)
        }

        // Drop footnotes/notes on the raw line first (before list markers are
        // stripped) so a leading "*" footnote is still recognisable.
        ingredients = ingredients.filter { !isAsideLine($0) }.map(stripListMarker).filter { !$0.isEmpty && !isMetadataLine($0) }
        // isMetadataLine is intentionally NOT applied to instructions: after merging,
        // a step that starts with "Prep the tin…" and later mentions "10 minutes"
        // would be incorrectly discarded by the Prep-time pattern.
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
        guard let first = lines.first(where: { !isSectionHeader($0) && !isMetadataLine($0) }) else {
            return nil
        }
        // Strip decorative emoji/symbols around the name before judging it.
        var cleaned = stripTrailingBullets(stripLeadingBullets(first))
            .replacingOccurrences(of: #"^(recipe\s*:?\s*)"#, with: "", options: [.regularExpression, .caseInsensitive])
            .trimmingCharacters(in: .whitespaces)
        // Titles are short; a long first line is prose, and quantity lines are ingredients.
        guard cleaned.count <= 80, !looksLikeIngredient(cleaned) else { return nil }
        cleaned = cleaned.trimmingCharacters(in: .whitespaces)
        return cleaned.isEmpty ? nil : cleaned
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

    /// Loose header match: reduce the line to just its letters/spaces (dropping
    /// emoji, colons, `#`, bullets) and compare to the keyword, so "INGREDIENTS
    /// 👇" and "Method:" both match while "Ingredients you'll need for the base"
    /// (a longer phrase) does not.
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

        // Skip the title line when classifying.
        for line in lines.dropFirst() where !isMetadataLine(line) {
            let stripped = stripListMarker(line)
            guard !stripped.isEmpty else { continue }

            // Numbered steps ("1. Preheat…", "Step 2: …") take priority because
            // they start with a digit and would otherwise match looksLikeIngredient.
            // Everything else that isn't a structural ingredient defaults to an
            // instruction — no finite verb whitelist needed.
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
        // Quantity-led ("2 cups flour", "½ tsp salt"), bulleted ("- flour"),
        // or emoji-led ("🧄 garlic, minced").
        line.range(of: #"^[-•*]?\s*(\d|[¼½¾⅓⅔⅛⅜⅝⅞⅕⅖⅗⅘⅙⅚])"#, options: .regularExpression) != nil
            || line.range(of: #"^[-•*]\s+\S"#, options: .regularExpression) != nil
            || startsWithBullet(line)
    }

    private static func looksLikeNumberedStep(_ line: String) -> Bool {
        // "1. Preheat…", "2) Mix…", "Step 3: …"
        line.range(of: #"^(step\s+\d+|\d+[\.\)])\s*"#, options: [.regularExpression, .caseInsensitive]) != nil
    }

    // MARK: - Cleanup

    private static func stripListMarker(_ line: String) -> String {
        let withoutNumber = line.replacingOccurrences(
            of: #"^(step\s+\d+\s*[:\.\)]?|\d+[\.\)])\s*"#,
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

    /// A leading decoration — dash/star bullet or an emoji — never a letter,
    /// digit, or fraction (those are recipe content we must keep).
    private static func isBulletCharacter(_ c: Character) -> Bool {
        if c.isLetter || c.isNumber { return false }
        if "-•*▪◦‣·▫●○▶►➤➥➢".contains(c) { return true }
        // Emoji, but not low-codepoint symbols like fractions or punctuation.
        return c.unicodeScalars.contains { $0.properties.isEmoji && ($0.value > 0x238C || $0.properties.isEmojiPresentation) }
    }

    /// True for footnotes / asides that shouldn't be an ingredient or a step:
    /// a "Note:"/"Tip:" line, or a "*"-glued footnote ("*on the rocks: ...").
    /// A spaced "* " bullet ("* 2 eggs") is a real ingredient and is NOT matched —
    /// footnotes glue the asterisk to their text, bullets don't.
    private static func isAsideLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.range(of: #"^(note|notes|tip|tips)\b\s*[:.\-]"#, options: [.regularExpression, .caseInsensitive]) != nil
            || trimmed.range(of: #"^\*[^\s*]"#, options: .regularExpression) != nil
    }

    /// True for non-ingredient sidebar/metadata lines that OCR and captions mix in
    /// with the ingredient list — servings, times, and lone labels/numbers — so
    /// they never become "ingredients".
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

    /// Joins OCR/column-wrapped instruction lines into logical steps.
    /// Vision OCR on a printed page produces one physical line per observation;
    /// without merging, a single instruction like "Heat a wok…add the oil,
    /// garlic…" becomes a dozen fragmented pseudo-steps. The merge rule:
    /// a new step only begins when the previous line ended with sentence-closing
    /// punctuation (.!?) AND the current line starts with an uppercase letter, OR
    /// when the current line looks like an explicit numbered step.
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
