import Foundation

/// Pure recipe-assembly logic extracted from `RecipeWizardView` so validation/construction is testable without a running UI.
enum RecipeWizardBuilder {

    /// Validation-alert errors; wording matches the wizard's originals so the extraction is behaviour-preserving.
    enum BuilderError: LocalizedError {
        case missingIngredients
        case missingInstructions

        var errorDescription: String? {
            switch self {
            case .missingIngredients:
                return "Please add at least one ingredient"
            case .missingInstructions:
                return "Please add at least one cooking instruction"
            }
        }
    }

    /// What the user has entered, compared by content only (row ids and blank rows ignored), so the wizard can tell
    /// whether Cancel would throw away real edits.
    struct Draft: Equatable {
        let name: String
        let prepTime: Int
        let cookTime: Int
        let difficulty: String
        let category: String
        let servings: Int
        let ingredients: [[String]]
        let prePrep: [String]
        let steps: [String]
        let notes: String
        let tags: [String]
        let cuisine: String
        let imageReference: String?
        let galleryReferences: [String]

        init(
            name: String, prepTime: Int, cookTime: Int, difficulty: String, category: String, servings: Int,
            ingredientItems: [RecipeWizardView.IngredientItem], prePrepSteps: [EditableStep],
            mainInstructions: [EditableStep], notes: String, tags: [String], cuisine: String,
            imageReference: String?, galleryReferences: [String]
        ) {
            self.name = name.trimmed
            self.prepTime = prepTime
            self.cookTime = cookTime
            self.difficulty = difficulty
            self.category = category
            self.servings = servings
            self.ingredients = ingredientItems
                .map { [$0.quantity.trimmed, $0.unit.trimmed, $0.name.trimmed] }
                .filter { $0.contains { !$0.isEmpty } }
            self.prePrep = prePrepSteps.nonEmptyTexts
            self.steps = mainInstructions.nonEmptyTexts
            self.notes = notes.trimmed
            self.tags = tags
            self.cuisine = cuisine.trimmed
            self.imageReference = imageReference
            self.galleryReferences = galleryReferences
        }
    }

    /// Maps a free-text difficulty label onto one of the wizard's three levels.
    static func normalizeDifficulty(_ raw: String) -> String {
        let normalized = raw.lowercased()
        if normalized.contains("easy") || normalized.contains("basic") || normalized.contains("beginner") {
            return "Basic"
        } else if normalized.contains("hard") || normalized.contains("expert") || normalized.contains("advanced") {
            return "Expert"
        } else {
            return "Intermediate"
        }
    }

    /// Non-blank ingredient rows as domain `Ingredient`s, trimmed. A blank amount stays 0 ("no amount", shown as a
    /// plain line) — the same rule as `IngredientLineParser`; it used to become a made-up 1 ("1 salt").
    /// Fractions ("1/2", "1 1/2", "⅓") and decimal commas ("1,5") parse; an amount in words ("a few") isn't lost —
    /// it's kept at the front of the name with amount 0.
    static func makeIngredients(from items: [RecipeWizardView.IngredientItem]) -> [Ingredient] {
        items.compactMap { item in
            var name = item.name.trimmed
            guard !name.isEmpty else { return nil }
            let text = item.quantity.trimmed
            var quantity = 0.0
            if startsWithNumber(text) {
                quantity = parseAmount(text)
            } else if !text.isEmpty {
                name = "\(text) \(name)"
            }
            return Ingredient(baseQuantity: quantity, unit: item.unit.trimmed, name: name)
        }
    }

    /// The amount field's number: unicode fractions, "1 1/2", and a European decimal comma ("1,5" → 1.5).
    static func parseAmount(_ text: String) -> Double {
        let decimalPoint = text.replacingOccurrences(of: #"^(\d*),(\d+)"#, with: "$1.$2", options: .regularExpression)
        let normalised = IngredientLineParser.normaliseUnicodeFractions(decimalPoint)
        let leadingZero = normalised.hasPrefix(".") ? "0" + normalised : normalised
        return IngredientLineParser.parseQuantity(leadingZero)
    }

    /// Digits, ".5", ",5" or a unicode fraction ("½") — anything else in the amount field is words ("a few").
    static func startsWithNumber(_ text: String) -> Bool {
        // The fraction normaliser pads with spaces ("½" → " 1/2 "), so trim before looking at the first character.
        guard let first = IngredientLineParser.normaliseUnicodeFractions(text).trimmed.first else { return false }
        return first.isNumber || first == "." || first == ","
    }

    /// Validates inputs, throwing on first failure in the wizard's original order (name → servings → ingredients → instructions) so the same alert appears.
    static func validate(
        name: String,
        servings: Int,
        ingredientItems: [RecipeWizardView.IngredientItem],
        mainInstructions: [EditableStep]
    ) throws {
        try Validator.validateRecipeName(name)
        try Validator.validateServings(servings)
        guard !makeIngredients(from: ingredientItems).isEmpty else {
            throw BuilderError.missingIngredients
        }
        guard !mainInstructions.nonEmptyTexts.isEmpty else {
            throw BuilderError.missingInstructions
        }
    }

    /// Builds the final recipe from validated inputs. Call `validate` first.
    static func assemble(
        recipeId: UUID,
        name: String,
        category: String,
        difficulty: String,
        prepTime: Int,
        cookTime: Int,
        servings: Int,
        ingredientItems: [RecipeWizardView.IngredientItem],
        prePrepSteps: [EditableStep],
        mainInstructions: [EditableStep],
        notes: String,
        imageReference: String?,
        isFavorite: Bool,
        tags: [String] = [],
        cuisine: String? = nil,
        photoNames: [String] = [],
        sourceText: String? = nil
    ) -> RecipeModel {
        RecipeModel(
            id: recipeId,
            name: name.trimmed,
            category: category,
            difficulty: difficulty,
            prepTime: "\(prepTime) minutes",
            cookingTime: "\(cookTime) minutes",
            baseServings: servings,
            currentServings: servings,
            ingredients: makeIngredients(from: ingredientItems),
            prePrepInstructions: prePrepSteps.nonEmptyTexts,
            instructions: mainInstructions.nonEmptyTexts,
            notes: notes,
            imageName: imageReference,
            isFavorite: isFavorite,
            tags: tags,
            cuisine: cuisine,
            photoNames: photoNames,
            sourceText: sourceText
        )
    }

    /// An edit only covers the wizard's fields; carry over everything else from the stored recipe. Without this, editing
    /// reset rating + dietary info and flipped bundled recipes to "user" ones (re-enabling source re-checks and badges).
    static func mergeEdit(_ edited: RecipeModel, onto stored: RecipeModel) -> RecipeModel {
        var merged = edited
        merged.isSampleRecipe = stored.isSampleRecipe
        merged.rating = stored.rating
        merged.dietaryInfo = stored.dietaryInfo
        merged.cookCount = stored.cookCount
        merged.lastCookedAt = stored.lastCookedAt
        merged.sourceText = edited.sourceText ?? stored.sourceText
        return merged
    }
}

/// Manual entry as one text area: one ingredient per line, parsed by the same `IngredientLineParser` imports use,
/// so typing, pasting and importing produce identical rows.
enum IngredientTextBlock {
    /// Rows for each non-blank line, in order.
    static func items(from text: String) -> [RecipeWizardView.IngredientItem] {
        text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { line in
                let parsed = IngredientLineParser.parse(line)
                return RecipeWizardView.IngredientItem(quantity: parsed.quantityText, unit: parsed.unit, name: parsed.name)
            }
    }

    /// The text area's contents for existing rows ("200 g flour"); rows without a name are dropped.
    static func text(from items: [RecipeWizardView.IngredientItem]) -> String {
        items.compactMap { item in
            let name = item.name.trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { return nil }
            return [item.quantity.trimmingCharacters(in: .whitespaces), item.unit, name]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }
        .joined(separator: "\n")
    }
}

/// Steps as one text area: one step per line; blank lines and pasted numbering ("1.", "2)", "Step 3:") are dropped.
enum StepTextBlock {
    static func steps(from text: String) -> [String] {
        text.components(separatedBy: .newlines)
            .map { line in
                line.trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: #"^(?:step\s*)?\d+\s*(?:[.)](?!\d)|:)\s*"#, with: "",
                                          options: [.regularExpression, .caseInsensitive])
                    .trimmingCharacters(in: .whitespaces)
            }
            .filter { !$0.isEmpty }
    }

    static func text(from steps: [String]) -> String {
        steps.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }.joined(separator: "\n")
    }
}
