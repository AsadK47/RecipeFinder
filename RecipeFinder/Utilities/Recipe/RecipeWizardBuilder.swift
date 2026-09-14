import Foundation

/// Pure recipe-assembly logic extracted from `RecipeWizardView`.
///
/// Keeping validation and model construction here — rather than inline in the
/// view's `createRecipe` — makes the wizard's business rules testable without a
/// running UI.
enum RecipeWizardBuilder {

    /// Errors surfaced to the wizard's validation alert. The wording matches
    /// what the wizard has always shown so the extraction is behaviour-preserving.
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

    /// Non-empty ingredient rows converted to domain `Ingredient`s. A blank
    /// quantity falls back to `1.0`, matching the wizard's original behaviour.
    static func makeIngredients(from items: [RecipeWizardView.IngredientItem]) -> [Ingredient] {
        items
            .filter { !$0.name.isEmpty }
            .map { item in
                let quantity = Double(item.quantity) ?? 1.0
                return Ingredient(baseQuantity: quantity, unit: item.unit, name: item.name)
            }
    }

    /// Validates the wizard's inputs, throwing on the first failure. Ordered to
    /// match the wizard's original checks (name → servings → ingredients →
    /// instructions) so the same alert appears for the same input.
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
        tags: [String] = []
    ) -> RecipeModel {
        RecipeModel(
            id: recipeId,
            name: name,
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
            tags: tags
        )
    }
}
