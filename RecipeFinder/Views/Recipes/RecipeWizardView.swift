import SwiftUI

struct RecipeWizardView: View {
    @Environment(\.dismiss) var dismiss

    let onComplete: (RecipeModel) -> Void
    let prefilledData: PrefilledRecipeData?
    let editingRecipeId: UUID?
    /// When set, shows ONLY this section (focused edit); when nil, shows all sections as one form (create/full edit). Same save path — modular views of one canonical editor.
    let focus: Section?

    /// The modular sections of the editor, in display order.
    enum Section: Hashable, CaseIterable {
        case basics, details, ingredients, prePrep, instructions, notes

        /// Screen title when the editor is focused on just this section.
        var title: String {
            switch self {
            case .basics: "Name & Photo"
            case .details: "Details"
            case .ingredients: "Ingredients"
            case .prePrep: "Pre-prep"
            case .instructions: "Instructions"
            case .notes: "Notes"
            }
        }

        /// Sections to render: all (in order) when unfocused, else just the focused one. Pure so it's unit-tested.
        static func shown(for focus: Section?) -> [Section] {
            guard let focus else { return allCases }
            return [focus]
        }
    }

    /// The editor's navigation title. Pure so it's unit-tested independently of the view.
    static func editorTitle(focus: Section?, isEditing: Bool) -> String {
        if let focus { return focus.title }
        return isEditing ? "Edit Recipe" : "New Recipe"
    }

    @State var recipeName = ""

    @State private var prepTime = 15
    /// Set only for a new import the reader struggled with; drives the banner + section highlights (Import 2/5).
    @State private var importQuality: ImportQuality.Assessment?
    @State private var cookTime = 30
    @State private var difficulty = "Intermediate"
    @State private var category = "Main"

    @State var servings = 4

    @State var ingredientItems: [IngredientItem] = [IngredientItem()]
    @FocusState private var focusedIngredientID: UUID?

    @State private var prePrepSteps: [EditableStep] = [EditableStep()]

    @State var mainInstructions: [EditableStep] = [EditableStep()]

    @State private var notes = ""
    @State private var recipeTags: [String] = []
    @State private var recipeCuisine = ""

    @State private var errorMessage: String?
    @AppStorage("hasSeenWizardIntro") private var hasSeenWizardIntro = false
    @State private var showIntro = false
    @State private var showPhotoPicker = false
    @State private var selectedRecipeImage: UIImage?
    @State private var existingImageReference: String?
    @State private var selectedGalleryImages: [UIImage] = []
    @State private var existingGalleryReferences: [String] = []
    @State private var showGalleryPhotoPicker = false
    @State private var pendingGalleryImage: UIImage?

    private let imageStore = RecipeImageStore()

    init(
        prefilledData: PrefilledRecipeData? = nil,
        editingRecipeId: UUID? = nil,
        focus: Section? = nil,
        onComplete: @escaping (RecipeModel) -> Void
    ) {
        self.prefilledData = prefilledData
        self.editingRecipeId = editingRecipeId
        self.focus = focus
        self.onComplete = onComplete
    }

    let difficulties = ["Basic", "Intermediate", "Expert"]
    let categories = ["Breakfast", "Starter", "Main", "Side", "Soup", "Dessert", "Drink"]

    let cookingUnitGroups: [(group: String, units: [String])] = [
        ("Volume – Metric",   ["ml", "cl", "dl", "l"]),
        ("Volume – Imperial", ["tsp", "tbsp", "fl oz", "cup", "pt", "qt", "gal"]),
        ("Weight – Metric",   ["g", "kg"]),
        ("Weight – Imperial", ["oz", "lb"]),
        ("Count & Other",     ["piece", "whole", "slice", "clove", "can", "jar",
                               "package", "bunch", "sprig", "leaf", "sheet",
                               "pinch", "dash", "drop", "handful"]),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacing32) {
                sections
            }
            .padding(.top, AppTheme.spacing16)
            .padding(.horizontal, AppTheme.spacing20)
            .padding(.bottom, AppTheme.spacing32)
        }
        .onAppear {
            applyPrefilledData()
            if editingRecipeId == nil, let data = prefilledData {
                let assessment = ImportQuality.assess(data)
                importQuality = assessment.isLow ? assessment : nil
            }
            // First full create-flow only — not focused edits or updates.
            if focus == nil, editingRecipeId == nil, !hasSeenWizardIntro {
                showIntro = true
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    HapticManager.shared.selection()
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(editingRecipeId != nil ? "Update" : "Save") {
                    createRecipe()
                }
                .fontWeight(.semibold)
            }
        }
        .sheetScaffold(navigationTitleText)
        .sheet(isPresented: $showIntro) {
            WizardIntroSheet {
                hasSeenWizardIntro = true
                showIntro = false
            }
        }
        .errorAlert("Validation Error", message: $errorMessage)
        .photoSourcePicker(isPresented: $showPhotoPicker) { image in
            selectedRecipeImage = image
        }
        .photoSourcePicker(isPresented: $showGalleryPhotoPicker) { image in
            pendingGalleryImage = image
        }
        .onChange(of: selectedRecipeImage) { _, newImage in
            if newImage != nil {
                existingImageReference = nil
            }
        }
        .onChange(of: pendingGalleryImage) { _, newImage in
            if let newImage {
                selectedGalleryImages.append(newImage)
                pendingGalleryImage = nil
            }
        }
    }

    private func applyPrefilledData() {
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
            ingredientItems = ingredients.map { fullIngredient in
                return parseIngredientString(fullIngredient)
            }
            if !ingredients.isEmpty {
                ingredientItems.append(IngredientItem())
            }
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

    private var navigationTitleText: String {
        Self.editorTitle(focus: focus, isEditing: editingRecipeId != nil)
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
    private var sections: some View {
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
                ingredientItems: $ingredientItems,
                focusedIngredientID: $focusedIngredientID,
                cookingUnitGroups: cookingUnitGroups
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

    func createRecipe() {
        do {
            try RecipeWizardBuilder.validate(
                name: recipeName,
                servings: servings,
                ingredientItems: ingredientItems,
                mainInstructions: mainInstructions
            )
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.shared.error()
            return
        }

        let recipeId = editingRecipeId ?? UUID()
        let imageReference = imageStore.resolveReference(
            recipeId: recipeId,
            selectedImage: selectedRecipeImage,
            existingReference: existingImageReference,
            previousReference: prefilledData?.imageURL
        )

        let newGalleryPaths = imageStore.persistGallery(
            selectedGalleryImages,
            recipeId: recipeId,
            startingIndex: existingGalleryReferences.count
        )
        let allPhotoNames = existingGalleryReferences + newGalleryPaths

        let cuisineValue = recipeCuisine.trimmed
        let recipe = RecipeWizardBuilder.assemble(
            recipeId: recipeId,
            name: recipeName,
            category: category,
            difficulty: difficulty,
            prepTime: prepTime,
            cookTime: cookTime,
            servings: servings,
            ingredientItems: ingredientItems,
            prePrepSteps: prePrepSteps,
            mainInstructions: mainInstructions,
            notes: notes,
            imageReference: imageReference,
            isFavorite: prefilledData?.isFavorite ?? false,
            tags: recipeTags,
            cuisine: cuisineValue.isEmpty ? nil : cuisineValue,
            photoNames: allPhotoNames,
            sourceText: prefilledData?.sourceText
        )

        HapticManager.shared.success()
        onComplete(recipe)
        dismiss()
    }

    private func parseIngredientString(_ fullIngredient: String) -> IngredientItem {
        let parsed = WizardIngredientParser.parse(fullIngredient)
        return IngredientItem(quantity: parsed.quantity, unit: parsed.unit, name: parsed.name)
    }
}

#Preview {
    RecipeWizardView(prefilledData: nil) { _ in }
}
