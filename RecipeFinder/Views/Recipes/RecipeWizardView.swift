import SwiftUI

struct RecipeWizardView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.appTheme) var appTheme
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted

    let onComplete: (RecipeModel) -> Void
    let prefilledData: PrefilledRecipeData?
    let editingRecipeId: UUID?

    // Non-private members below are read by the navigation chrome living in
    // RecipeWizardView+Chrome.swift; the rest of the wizard's state stays private.
    @State var currentStep = 0
    let totalSteps = 6

    @State var recipeName = ""

    @State private var prepTime = 15
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

    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showPhotoPicker = false
    @State private var selectedRecipeImage: UIImage?
    @State private var existingImageReference: String?
    @State private var selectedGalleryImages: [UIImage] = []
    @State private var existingGalleryReferences: [String] = []
    @State private var showGalleryPhotoPicker = false
    @State private var pendingGalleryImage: UIImage?

    private let imageStore = RecipeImageStore()

    init(prefilledData: PrefilledRecipeData? = nil, editingRecipeId: UUID? = nil, onComplete: @escaping (RecipeModel) -> Void) {
        self.prefilledData = prefilledData
        self.editingRecipeId = editingRecipeId
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
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    VStack(spacing: AppTheme.spacing12) {
                        headerBar
                    }
                    .padding(.horizontal, AppTheme.spacing20)
                    .padding(.top, AppTheme.spacing16)

                    progressBar

                    ScrollView {
                        VStack(spacing: AppTheme.spacing32) {
                            stepContent
                        }
                        .padding(.top, AppTheme.spacing16)
                        .padding(.horizontal, AppTheme.spacing20)
                    }

                    navigationButtons
                }
            }
            .onAppear {
                applyPrefilledData()
            }
        }
        .alert("Validation Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showPhotoPicker) {
            ImagePicker(image: $selectedRecipeImage) {
                HapticManager.shared.light()
            }
        }
        .sheet(isPresented: $showGalleryPhotoPicker) {
            ImagePicker(image: $pendingGalleryImage) {
                HapticManager.shared.light()
            }
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

        if let prepTime = data.prepTime {
            self.prepTime = prepTime
        }
        if let cookTime = data.cookTime {
            self.cookTime = cookTime
        }

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

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            RecipeNameStepView(
                recipeName: $recipeName,
                selectedRecipeImage: $selectedRecipeImage,
                existingImageReference: $existingImageReference,
                selectedGalleryImages: $selectedGalleryImages,
                existingGalleryReferences: $existingGalleryReferences,
                cardStyle: cardStyle,
                colorScheme: colorScheme,
                totalSteps: totalSteps,
                onPickPhoto: {
                    HapticManager.shared.light()
                    showPhotoPicker = true
                },
                onAddGalleryPhoto: {
                    HapticManager.shared.light()
                    showGalleryPhotoPicker = true
                }
            )
        case 1:
            BasicInfoStepView(
                prepTime: $prepTime,
                cookTime: $cookTime,
                difficulty: $difficulty,
                category: $category,
                servings: $servings,
                difficulties: difficulties,
                categories: categories,
                appTheme: appTheme,
                cardStyle: cardStyle,
                colorScheme: colorScheme,
                totalSteps: totalSteps
            )
        case 2:
            IngredientsStepView(
                ingredientItems: $ingredientItems,
                focusedIngredientID: $focusedIngredientID,
                cookingUnitGroups: cookingUnitGroups,
                appTheme: appTheme,
                cardStyle: cardStyle,
                colorScheme: colorScheme,
                totalSteps: totalSteps
            )
        case 3:
            EditableStepsStepView(
                steps: $prePrepSteps,
                title: "Pre-prep Instructions",
                subtitle: "Any prep work before cooking? (Optional)",
                stepNumber: 4,
                illustration: "list.bullet.clipboard.fill",
                fieldPlaceholder: "Describe the pre-prep step",
                addButtonTitle: "Add Pre-prep Step",
                appTheme: appTheme,
                cardStyle: cardStyle,
                colorScheme: colorScheme,
                totalSteps: totalSteps
            )
        case 4:
            EditableStepsStepView(
                steps: $mainInstructions,
                title: "Cooking Instructions",
                subtitle: "Walk us through the cooking process",
                stepNumber: 5,
                illustration: "flame.fill",
                fieldPlaceholder: "Describe this cooking step",
                addButtonTitle: "Add Cooking Step",
                appTheme: appTheme,
                cardStyle: cardStyle,
                colorScheme: colorScheme,
                totalSteps: totalSteps
            )
        case 5:
            NotesStepView(
                notes: $notes,
                tags: $recipeTags,
                cuisine: $recipeCuisine,
                hasPrefilledNotes: prefilledData?.notes != nil,
                summary: recipeSummary,
                cardStyle: cardStyle,
                colorScheme: colorScheme,
                totalSteps: totalSteps
            )
        default:
            EmptyView()
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
            showError = true
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

        let cuisineValue = recipeCuisine.trimmingCharacters(in: .whitespacesAndNewlines)
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
            photoNames: allPhotoNames
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
        .environment(\.appTheme, AppTheme.ThemeType.teal)
}
