import Foundation

/// Line-level cleanup for pasted/OCR'd recipe text before `TextRecipeParser` sorts it: drops page furniture (print/pin
/// buttons, ratings, ads, hashtags, unit toggles), normalises keycap step numbers, and recognises the trailing
/// notes/nutrition sections so they can't leak into ingredients or steps.
enum RecipeTextCleanup {

    /// What a trailing section header starts: notes worth keeping, or data that's dropped (nutrition panels).
    enum TrailingSection: Equatable {
        case notes
        case nutrition
    }

    /// Whole-line page furniture copied along with a recipe from blogs, recipe cards and social captions.
    static func isBoilerplate(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return boilerplatePatterns.contains {
            trimmed.range(of: $0, options: [.regularExpression, .caseInsensitive]) != nil
        }
    }

    private static let boilerplatePatterns: [String] = [
        // Buttons and toggles: "Jump to Recipe", "Print", "US Customary", "Cook Mode"…
        #"^(jump to (recipe|video)|print( recipe)?|pin( recipe)?|save( recipe)?|share|email|rate( this)?( recipe)?"#
            + #"|advertisement|sponsored|cook mode|us customary|metric|imperial|i made it|watch the video"#
            + #"|scroll to continue|continue reading|skip to content)\W*$"#,
        #"^\d+(\.\d+)?\s*x(\s*\d+(\.\d+)?\s*x)+$"#,                                   // serving scaler "1x2x3x"
        #"^(rated\s+)?\d(\.\d+)?\s+(from\s+[\d,]+\s+(votes?|ratings?|reviews?)|out of 5\b).*$"#, // "4.89 from 212 votes"
        #"^\(?[\d,]+\s+(votes?|ratings?|reviews?|comments?)\)?$"#,                  // "(312 reviews)"
        #"^#\S+(\s+#\S+)*$"#,                                                       // hashtag-only line
        #"^(follow|tag)\s+@"#,                                                      // "Follow @x for more"
        #"did you make this recipe"#,
        #"^(full\s+)?(recipe\s+|link\s+)+in\s+(my\s+)?bio\b"#,                     // "Link in bio for the full recipe"
        #"^save this\b.*\b(later|recipe|post)\b"#,                                  // "Save this for later 📌"
        #"^(course|cuisine|keywords?|author|diet|calories)\s*:"#,                    // recipe-card metadata rows
        #"^(https?://|www\.)\S+$"#                                                  // bare source link
    ]

    /// "1️⃣ Heat the oil" → "1. Heat the oil", so keycap emoji steps read as numbered steps rather than amounts.
    static func normalizingKeycapNumber(_ line: String) -> String {
        line.replacingOccurrences(of: #"^(\d{1,2})\x{FE0F}?\x{20E3}\s*"#, with: "$1. ", options: .regularExpression)
    }

    /// The section a header line opens ("Notes", "Recipe Variations", "How to Store Burgers", "Nutrition Facts"), else nil.
    static func trailingSection(startedBy line: String) -> TrailingSection? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        // Headers are short labels; a sentence ending in "." is content, not a header.
        guard trimmed.split(separator: " ").count <= 6, !trimmed.hasSuffix(".") else { return nil }
        if trimmed.range(of: #"^nutrition(al)?\b"#, options: [.regularExpression, .caseInsensitive]) != nil {
            return .nutrition
        }
        let header = RecipeParser.normalizedHeader(trimmed)
        if notesHeaders.contains(header) { return .notes }
        if trimmed.range(of: #"^(how to store|storing|to store|make ahead)\b"#,
                         options: [.regularExpression, .caseInsensitive]) != nil {
            return .notes
        }
        return nil
    }

    /// Splits off trailing "Notes" / "Nutrition" style sections: notes are kept for the recipe's notes, nutrition
    /// panels are dropped. A later ingredient/method header resumes the recipe body.
    static func separatingTrailingSections(_ lines: [String]) -> (body: [String], notes: [String]) {
        var body: [String] = []
        var notes: [String] = []
        var trailing: TrailingSection?
        for line in lines {
            if RecipeParser.isHeader(line, in: RecipeParser.ingredientHeaderWords + RecipeParser.instructionHeaderWords) {
                trailing = nil
            } else if let section = trailingSection(startedBy: line) {
                trailing = section
                continue
            }
            switch trailing {
            case .notes: notes.append(line)
            case .nutrition: continue
            case nil: body.append(line)
            }
        }
        return (body, notes)
    }

    private static let notesHeaders: Set<String> = [
        "notes", "note", "recipe notes", "cook s notes", "cooks notes", "chef s notes", "tips", "recipe tips",
        "variations", "recipe variations", "storage", "storage notes", "storage instructions", "substitutions",
        "equipment", "faq", "faqs"
    ]
}
