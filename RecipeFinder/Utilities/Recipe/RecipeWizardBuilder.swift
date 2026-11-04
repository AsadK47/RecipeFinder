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

    /// Non-empty ingredient rows as domain `Ingredient`s; blank quantity falls back to 1.0, matching the wizard's original behaviour.
    static func makeIngredients(from items: [RecipeWizardView.IngredientItem]) -> [Ingredient] {
        items
            .filter { !$0.name.isEmpty }
            .map { item in
                let quantity = Double(item.quantity) ?? 1.0
                return Ingredient(baseQuantity: quantity, unit: item.unit, name: item.name)
            }
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
        photoNames: [String] = []
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
            tags: tags,
            cuisine: cuisine,
            photoNames: photoNames
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
        return merged
    }
}
