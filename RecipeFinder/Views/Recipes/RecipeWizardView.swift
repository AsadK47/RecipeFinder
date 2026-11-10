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

    // 0 = not set. Defaults of 15 + 30 used to be saved on every manual recipe as if the cook had entered them.
    @State var prepTime = 0
    /// Set only for a new import the reader struggled with; drives the banner + section highlights (Import 2/5).
    @State var importQuality: ImportQuality.Assessment?
    @State var cookTime = 0
    @State var difficulty = "Intermediate"
    @State var category = "Main"

    @State var servings = 4

    @State var ingredientItems: [IngredientItem] = [IngredientItem()]

    @State var prePrepSteps: [EditableStep] = [EditableStep()]

    @State var mainInstructions: [EditableStep] = [EditableStep()]

    @State var notes = ""
    @State var recipeTags: [String] = []
    @State var recipeCuisine = ""

    @State private var errorMessage: String?
    @AppStorage("hasSeenWizardIntro") private var hasSeenWizardIntro = false
    @State private var showIntro = false
    @State var showPhotoPicker = false
    @State var selectedRecipeImage: UIImage?
    @State var existingImageReference: String?
    @State var selectedGalleryImages: [UIImage] = []
    @State var existingGalleryReferences: [String] = []
    @State var showGalleryPhotoPicker = false
    @State private var pendingGalleryImage: UIImage?
    /// The form as first shown (after any prefill); Cancel/swipe-down only asks before discarding if it changed.
    @State private var initialDraft: RecipeWizardBuilder.Draft?
    @State private var showDiscardConfirm = false

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
            if initialDraft == nil { initialDraft = currentDraft }
            // First full create-flow only — not focused edits or updates.
            if focus == nil, editingRecipeId == nil, !hasSeenWizardIntro {
                showIntro = true
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    HapticManager.shared.selection()
                    if hasUnsavedChanges { showDiscardConfirm = true } else { dismiss() }
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
        // Swipe-down can't silently throw away typing; Cancel asks first instead.
        .interactiveDismissDisabled(hasUnsavedChanges)
        .confirmationDialog("Discard this recipe?", isPresented: $showDiscardConfirm, titleVisibility: .visible) {
            Button("Discard Changes", role: .destructive) { dismiss() }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("Your changes haven't been saved.")
        }
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


    private var currentDraft: RecipeWizardBuilder.Draft {
        RecipeWizardBuilder.Draft(
            name: recipeName, prepTime: prepTime, cookTime: cookTime, difficulty: difficulty, category: category,
            servings: servings, ingredientItems: ingredientItems, prePrepSteps: prePrepSteps,
            mainInstructions: mainInstructions, notes: notes, tags: recipeTags, cuisine: recipeCuisine,
            imageReference: existingImageReference, galleryReferences: existingGalleryReferences
        )
    }

    private var hasUnsavedChanges: Bool {
        selectedRecipeImage != nil || !selectedGalleryImages.isEmpty
            || initialDraft.map { $0 != currentDraft } ?? false
    }

    private var navigationTitleText: String {
        Self.editorTitle(focus: focus, isEditing: editingRecipeId != nil)
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
            recipeId: recipeId
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
}

#Preview {
    RecipeWizardView(prefilledData: nil) { _ in }
}
