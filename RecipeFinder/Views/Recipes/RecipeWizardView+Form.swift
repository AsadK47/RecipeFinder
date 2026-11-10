import SwiftUI

/// The editor's form: prefill from an import/edit, and the section views. Split out of `RecipeWizardView` to keep it small.
extension RecipeWizardView {
    func applyPrefilledData() {
        guard let data = prefilledData else { return }

        if let name = data.name, !name.isEmpty {
            recipeName = name
        }

        if let category = data.category, !category.isEmpty {
            self.category = category
        }

        // Unknown times stay 0 (unset) — keeping the 15 + 30 min defaults invented a "45 minutes" the source never said.
        self.prepTime = data.prepTime ?? 0
        self.cookTime = data.cookTime ?? 0

        if let servings = data.servings {
            self.servings = servings
        }

        if let difficulty = data.difficulty, !difficulty.isEmpty {
            self.difficulty = RecipeWizardBuilder.normalizeDifficulty(difficulty)
        }

        if let ingredients = data.ingredients, !ingredients.isEmpty {
            ingredientItems = ingredients.map { line in
                let parsed = WizardIngredientParser.parse(line)
                return IngredientItem(quantity: parsed.quantity, unit: parsed.unit, name: parsed.name)
            }
            ingredientItems.append(IngredientItem())
        }

        if let instructions = data.instructions, !instructions.isEmpty {
            mainInstructions = .steps(from: instructions)
            mainInstructions.append(EditableStep())
        }

        if let prePrep = data.prePrepInstructions, !prePrep.isEmpty {
            prePrepSteps = .steps(from: prePrep)
        }

        if let notes = data.notes, !notes.isEmpty {
            self.notes = notes
        }

        if let tags = data.tags, !tags.isEmpty {
            self.recipeTags = tags
        }

        if let cuisine = data.cuisine, !cuisine.isEmpty {
            self.recipeCuisine = cuisine
        }

        if let imageReference = data.imageURL, !imageReference.isEmpty {
            existingImageReference = imageReference
        }

        if let galleryURLs = data.galleryImageURLs, !galleryURLs.isEmpty {
            existingGalleryReferences = galleryURLs
        }
    }

    private func shouldShow(_ section: Section) -> Bool {
        Section.shown(for: focus).contains(section)
    }

    /// True when the import couldn't read any of `fields` and the low-confidence banner is up.
    private func needsCheck(_ fields: ImportQuality.Field...) -> Bool {
        guard let importQuality else { return false }
        return !importQuality.missing.isDisjoint(with: fields)
    }

    @ViewBuilder
    var sections: some View {
        if importQuality != nil {
            ImportQualityBanner()
        }

        if shouldShow(.basics) {
            RecipeNameStepView(
                recipeName: $recipeName,
                selectedRecipeImage: $selectedRecipeImage,
                existingImageReference: $existingImageReference,
                selectedGalleryImages: $selectedGalleryImages,
                existingGalleryReferences: $existingGalleryReferences,
                onPickPhoto: {
                    HapticManager.shared.light()
                    showPhotoPicker = true
                },
                onAddGalleryPhoto: {
                    HapticManager.shared.light()
                    showGalleryPhotoPicker = true
                }
            )
            .importHighlight(needsCheck(.name))
        }

        if shouldShow(.details) {
            BasicInfoStepView(
                prepTime: $prepTime,
                cookTime: $cookTime,
                difficulty: $difficulty,
                category: $category,
                servings: $servings,
                difficulties: difficulties,
                categories: categories
            )
            .importHighlight(needsCheck(.times))
        }

        if shouldShow(.ingredients) {
            IngredientsStepView(
                ingredientItems: $ingredientItems
            )
            .importHighlight(needsCheck(.ingredients, .amounts))
        }

        if shouldShow(.prePrep) {
            EditableStepsStepView(
                steps: $prePrepSteps,
                title: "Pre-prep Instructions",
                subtitle: "Any prep work before cooking? (Optional)",
                illustration: "list.bullet.clipboard.fill",
                fieldPlaceholder: "Describe the pre-prep step",
                addButtonTitle: "Add Pre-prep Step"
            )
        }

        if shouldShow(.instructions) {
            EditableStepsStepView(
                steps: $mainInstructions,
                title: "Cooking Instructions",
                subtitle: "Walk us through the cooking process",
                illustration: "flame.fill",
                fieldPlaceholder: "Describe this cooking step",
                addButtonTitle: "Add Cooking Step"
            )
            .importHighlight(needsCheck(.steps))
        }

        if shouldShow(.notes) {
            NotesStepView(
                notes: $notes,
                tags: $recipeTags,
                cuisine: $recipeCuisine,
                hasPrefilledNotes: prefilledData?.notes != nil,
                summary: recipeSummary
            )
        }
    }

    private var recipeSummary: WizardRecipeSummary {
        WizardRecipeSummary(
            name: recipeName,
            category: category,
            difficulty: difficulty,
            servings: servings,
            prepTime: prepTime,
            cookTime: cookTime,
            ingredientCount: ingredientItems.filter { !$0.name.isEmpty }.count,
            prePrepStepCount: prePrepSteps.nonEmptyTexts.count,
            cookingStepCount: mainInstructions.nonEmptyTexts.count
        )
    }
}
