import Foundation

/// Parses free-form recipe text (notes, captions, messages) into wizard prefill: S1 splits on loose section headers ("INGREDIENTS 👇", "Method:"), filling any missing section via S2 line classification (quantity/bullet/emoji = ingredient, numbered/imperative = instruction).
enum TextRecipeParser {

    static func parse(_ text: String) -> RecipeWizardView.PrefilledRecipeData? {
        let cleaned = text
            .components(separatedBy: .newlines)
            .map { RecipeTextCleanup.normalizingKeycapNumber($0.trimmingCharacters(in: .whitespaces)) }
            .filter { !$0.isEmpty && !RecipeTextCleanup.isBoilerplate($0) }
        let (lines, trailingNotes) = RecipeTextCleanup.separatingTrailingSections(cleaned)
        var noteLines = trailingNotes

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

        // Footnotes move to notes on the raw line first (before markers stripped) so a leading "*" footnote is recognisable.
        noteLines += (ingredients + instructions).filter(isAsideLine).map(stripListMarker)
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
            notes: noteLines.isEmpty ? nil : noteLines.joined(separator: "\n"),
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
        // "15 minute garlic pasta" is a title, not an amount: a count of minutes/ingredients/steps leads it.
        let isCountedTitle = cleaned.range(of: #"^\d+[\s-]*(minutes?|mins?|hours?|ingredients?|steps?|ways?)\b"#,
                                           options: [.regularExpression, .caseInsensitive]) != nil
        guard cleaned.count <= 80, isCountedTitle || !looksLikeIngredient(cleaned) else { return nil }

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
        let hasInstructionHeader = lines.contains { RecipeParser.isHeader($0, in: RecipeParser.instructionHeaderWords) }

        // Indices in `ingredientLines` of group headers kept as "For the sauce:" lines, so they're never mistaken for
        // a step sub-heading below.
        var groupHeaderIndices = Set<Int>()

        for line in lines {
            if RecipeParser.isHeader(line, in: RecipeParser.ingredientSectionHeaderWords) {
                current = .ingredients
                continue
            }
            if RecipeParser.isHeader(line, in: RecipeParser.ingredientSubsectionHeaderWords)
                || (current != .instructions && isIngredientGroupHeader(line)) {
                current = .ingredients
                groupHeaderIndices.insert(ingredientLines.count)
                ingredientLines.append(IngredientSections.headerLine(for: groupTitle(line)))
                continue
            }
            if RecipeParser.isHeader(line, in: RecipeParser.instructionHeaderWords) {
                current = .instructions
                continue
            }
            // No method header: the first real step ends the ingredient list, taking a step sub-heading
            // ("PREPARE THE DOUGH:") just above it along, instead of every step landing in ingredients.
            if current == .ingredients, !hasInstructionHeader, startsInstructions(line) {
                current = .instructions
                if let last = ingredientLines.last, isStepSubheading(last),
                   !groupHeaderIndices.contains(ingredientLines.count - 1) {
                    instructionLines.append(ingredientLines.removeLast())
                }
            }

            switch current {
            case .ingredients: ingredientLines.append(line)
            case .instructions: instructionLines.append(line)
            case nil: break
            }
        }

        let ingredients = droppingEmptyGroups(ingredientLines)
        guard !ingredients.isEmpty || !instructionLines.isEmpty else { return nil }
        return (ingredients, instructionLines)
    }

    /// "For the sauce" in sentence case, whatever the source's capitals, colon or emoji.
    private static func groupTitle(_ line: String) -> String {
        let words = RecipeParser.normalizedHeader(line)
        return words.prefix(1).uppercased() + words.dropFirst()
    }

    /// Header lines with no ingredient under them (back-to-back or at the end) dropped, so a group never comes out empty.
    private static func droppingEmptyGroups(_ lines: [String]) -> [String] {
        lines.enumerated().compactMap { index, line in
            guard IngredientSections.title(ofHeaderLine: line) != nil else { return line }
            let next = lines.indices.contains(index + 1) ? lines[index + 1] : nil
            return next.map { IngredientSections.title(ofHeaderLine: $0) == nil } == true ? line : nil
        }
    }

    private enum Section {
        case ingredients
        case instructions
    }

    /// Cookbook group headers outside the fixed vocabulary: "FOR THE CHICKEN", "To make the glaze:".
    private static func isIngredientGroupHeader(_ line: String) -> Bool {
        line.split(separator: " ").count <= 6
            && line.range(of: #"^(for|to make) the [^\d:.]{2,30}:?$"#, options: [.regularExpression, .caseInsensitive]) != nil
    }

    /// A line that can only be a method step: a numbered step that isn't an amount, or a full sentence with no amount.
    private static func startsInstructions(_ line: String) -> Bool {
        if looksLikeNumberedStep(line) { return !looksLikeIngredient(stripListMarker(line)) }
        let words = line.split(separator: " ").count
        return !looksLikeIngredient(line) && words >= 6 && ".!?".contains(line.last ?? " ")
    }

    /// A short label ending in ":" or in ALL CAPS ("ASSEMBLY:", "PREPARE THE DOUGH:") with no amount in it.
    private static func isStepSubheading(_ line: String) -> Bool {
        guard line.split(separator: " ").count <= 6, !line.contains(where: \.isNumber) else { return false }
        return line.hasSuffix(":") || (line == line.uppercased() && line.contains(where: \.isLetter))
    }

    private static func isSectionHeader(_ line: String) -> Bool {
        RecipeParser.isHeader(line, in: RecipeParser.ingredientHeaderWords + RecipeParser.instructionHeaderWords)
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
        if RecipeParser.listMarkerCharacters.contains(c) { return true }
        // Emoji, but not low-codepoint symbols like fractions or punctuation.
        return c.unicodeScalars.contains { $0.properties.isEmoji && ($0.value > 0x238C || $0.properties.isEmojiPresentation) }
    }

    /// Footnotes/asides that aren't ingredient or step: a "Note:"/"Tip:" line or a "*"-glued footnote; a spaced "* " bullet ("* 2 eggs") is real content and is NOT matched.
    private static func isAsideLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.range(of: #"^(note|notes|tip|tips)\b\s*[:.\-]"#, options: [.regularExpression, .caseInsensitive]) != nil
            || trimmed.range(of: #"^\*[^\s*]"#, options: .regularExpression) != nil
            // "* To slice the mint…" / "** If whole cumin…": a starred full sentence is a footnote, not a "* 2 eggs" bullet.
            || (trimmed.range(of: #"^\*{1,3}\s*[A-Za-z]"#, options: .regularExpression) != nil
                && trimmed.split(separator: " ").count >= 6 && ".!?".contains(trimmed.last ?? " "))
    }

    /// Non-ingredient sidebar/metadata lines OCR/captions mix in (servings, times, lone labels/numbers) so they never become "ingredients".
    private static func isMetadataLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let patterns = [
            #"^\d+$"#,                                                   // lone number ("2" under SERVES)
            #"^(time|serves|servings?)$"#,                               // lone label
            #"^(serves|servings?|yield)\b"#,                             // "Serves 2", "Yield: 4"
            #"^(prep(?:aration)?|cook(?:ing)?|total)\b.*\b"# + "(\(RecipeParser.minutesUnitPattern)|\(RecipeParser.hoursUnitPattern))" + #"\b"#  // "Prep 20 minutes"
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
        if looksLikeNumberedStep(line) || startsWithBullet(line) { return true }
        let prevEndsSentence = ".!?".contains(previous.last ?? " ")
        return prevEndsSentence && (line.first?.isUppercase ?? false)
    }

    /// Time in minutes after a label (pattern must capture the number in group 1): the regex only finds the duration's span
    /// ("2 hours", "1 hr 30 min", bare "45"); `TimeExtractor` does the unit maths.
    private static func extractMinutes(_ pattern: String, in text: String) -> Int? {
        // Single letters allowed here ("2h 30m") — the trailing \b stops "m" matching into "medium".
        let hours = "(?:\(RecipeParser.hoursUnitPattern)|h)", minutes = "(?:\(RecipeParser.minutesUnitPattern)|m)"
        let withUnit = pattern + #"(?:\s*(?:"# + hours + "|" + minutes + #")\b)?(?:\s*\d+\s*"# + minutes + #"\b)?"#
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
