import SwiftUI

struct RecipeWizardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) var appTheme
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    let onComplete: (RecipeModel) -> Void
    let prefilledData: PrefilledRecipeData?
    let editingRecipeId: UUID?
    
    struct PrefilledRecipeData {
        let name: String?
        let description: String?
        let ingredients: [String]?
        let instructions: [String]?
        var prePrepInstructions: [String]? = nil
        let prepTime: Int?
        let cookTime: Int?
        let servings: Int?
        let difficulty: String?
        let notes: String?
        let category: String?
        let isFavorite: Bool?
        let imageURL: String?
    }
    
    @State private var currentStep = 0
    private let totalSteps = 6
    
    @State private var recipeName = ""
    
    @State private var prepTime = 15
    @State private var cookTime = 30
    @State private var difficulty = "Intermediate"
    @State private var category = "Main"
    
    @State private var servings = 4
    
    @State private var ingredientItems: [IngredientItem] = [IngredientItem()]
    @FocusState private var focusedIngredientID: UUID?
    
    @State private var prePrepSteps: [EditableStep] = [EditableStep()]
    
    @State private var mainInstructions: [EditableStep] = [EditableStep()]
    
    @State private var notes = ""
    
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showPhotoPicker = false
    @State private var selectedRecipeImage: UIImage?
    @State private var existingImageReference: String?
    
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
    
    struct IngredientItem: Identifiable {
        let id = UUID()
        var quantity: String = ""
        var unit: String = ""
        var name: String = ""
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    VStack(spacing: AppTheme.spacing12) {
                        GeometryReader { geometry in
                            HStack {
                                Button(action: {
                                    HapticManager.shared.selection()
                                    dismiss()
                                }) {
                                    Text("Cancel")
                                        .font(.body)
                                        .adaptiveForegroundColor()
                                        .padding(.horizontal, AppTheme.spacing16)
                                        .padding(.vertical, AppTheme.spacing8)
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(AppTheme.cornerRadius12)
                                }
                                
                                Spacer()
                                
                                Text("Recipe Wizard")
                                    .font(.system(size: min(24, geometry.size.width * 0.06), weight: .bold))
                                    .adaptiveForegroundColor()
                                
                                Spacer()
                                
                                Button(action: {}) {
                                    Text("Cancel")
                                        .font(.body)
                                        .foregroundColor(.clear)
                                        .padding(.horizontal, AppTheme.spacing16)
                                        .padding(.vertical, AppTheme.spacing8)
                                }
                                .disabled(true)
                            }
                        }
                        .frame(height: AppTheme.height44)
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
        .onChange(of: selectedRecipeImage) { _, newImage in
            if newImage != nil {
                existingImageReference = nil
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
            let normalized = difficulty.lowercased()
            if normalized.contains("easy") || normalized.contains("basic") || normalized.contains("beginner") {
                self.difficulty = "Basic"
            } else if normalized.contains("hard") || normalized.contains("expert") || normalized.contains("advanced") {
                self.difficulty = "Expert"
            } else {
                self.difficulty = "Intermediate"
            }
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

        if let imageReference = data.imageURL, !imageReference.isEmpty {
            existingImageReference = imageReference
        }
    }
    
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(AppTheme.shadowDarkOpacity))
                
                Rectangle()
                    .fill(Color.white)
                    .frame(width: geometry.size.width * CGFloat(currentStep + 1) / CGFloat(totalSteps))
            }
        }
        .frame(height: AppTheme.height4)
        .padding(.horizontal, AppTheme.spacing20)
        .padding(.top, AppTheme.spacing8)
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            RecipeNameStepView(
                recipeName: $recipeName,
                selectedRecipeImage: $selectedRecipeImage,
                existingImageReference: $existingImageReference,
                cardStyle: cardStyle,
                colorScheme: colorScheme,
                totalSteps: totalSteps,
                onPickPhoto: {
                    HapticManager.shared.light()
                    showPhotoPicker = true
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
    
    private var navigationButtons: some View {
        HStack(spacing: AppTheme.spacing16) {
            if currentStep > 0 {
                Button(action: {
                    HapticManager.shared.selection()
                    withAnimation {
                        currentStep -= 1
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(AppTheme.shadowDarkOpacity))
                    .adaptiveForegroundColor()
                    .cornerRadius(AppTheme.cornerRadius12)
                }
            }
            
            Button(action: {
                HapticManager.shared.selection()
                if currentStep < totalSteps - 1 {
                    withAnimation {
                        currentStep += 1
                    }
                } else {
                    createRecipe()
                }
            }) {
                HStack {
                    Text(currentStep < totalSteps - 1 ? "Next" : (editingRecipeId != nil ? "Update Recipe" : "Create Recipe"))
                    if currentStep < totalSteps - 1 {
                        Image(systemName: "chevron.right")
                    } else {
                        Image(systemName: "checkmark")
                    }
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canProceed ? Color.white : Color.white.opacity(AppTheme.glassLightOpacity))
                .foregroundColor(canProceed ? AppTheme.accentColor(for: appTheme) : .white)
                .cornerRadius(AppTheme.cornerRadius12)
            }
            .disabled(!canProceed)
        }
        .padding()
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0:
            do {
                try Validator.validateRecipeName(recipeName)
                return true
            } catch {
                return false
            }
        case 1:
            return servings > 0
        case 2:
            return ingredientItems.contains { !$0.name.isEmpty }
        case 3:
            return true
        case 4:
            return mainInstructions.contains { !$0.text.isEmpty }
        case 5:
            return true
        default:
            return false
        }
    }

    private func createRecipe() {
        do {
            try Validator.validateRecipeName(recipeName)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            HapticManager.shared.error()
            return
        }
        
        do {
            try Validator.validateServings(servings)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            HapticManager.shared.error()
            return
        }
        
        let ingredients = ingredientItems
            .filter { !$0.name.isEmpty }
            .map { item in
                let quantity = Double(item.quantity) ?? 1.0
                return Ingredient(
                    baseQuantity: quantity,
                    unit: item.unit,
                    name: item.name
                )
            }
        
        guard !ingredients.isEmpty else {
            errorMessage = "Please add at least one ingredient"
            showError = true
            HapticManager.shared.error()
            return
        }
        
        let filteredPrePrep = prePrepSteps.nonEmptyTexts
        let filteredInstructions = mainInstructions.nonEmptyTexts
        
        guard !filteredInstructions.isEmpty else {
            errorMessage = "Please add at least one cooking instruction"
            showError = true
            HapticManager.shared.error()
            return
        }
        
        let recipeId = editingRecipeId ?? UUID()
        let isFavorite = prefilledData?.isFavorite ?? false
        let previousImageReference = prefilledData?.imageURL
        let imageReference = resolveImageReference(for: recipeId, previousReference: previousImageReference)
        
        let recipe = RecipeModel(
            id: recipeId,
            name: recipeName,
            category: category,
            difficulty: difficulty,
            prepTime: "\(prepTime) minutes",
            cookingTime: "\(cookTime) minutes",
            baseServings: servings,
            currentServings: servings,
            ingredients: ingredients,
            prePrepInstructions: filteredPrePrep,
            instructions: filteredInstructions,
            notes: notes,
            imageName: imageReference,
            isFavorite: isFavorite
        )
        
        HapticManager.shared.success()
        onComplete(recipe)
        dismiss()
    }

    private func resolveImageReference(for recipeId: UUID, previousReference: String?) -> String? {
        if let selectedRecipeImage {
            return persistRecipeImage(selectedRecipeImage, recipeId: recipeId) ?? previousReference
        }

        if existingImageReference?.isEmpty == false {
            return existingImageReference
        }

        if let previousReference, isLocalImageReference(previousReference) {
            try? FileManager.default.removeItem(atPath: previousReference)
        }

        return nil
    }

    private func persistRecipeImage(_ image: UIImage, recipeId: UUID) -> String? {
        guard let imageData = image.jpegData(compressionQuality: AppTheme.jpegCompressionQuality) else {
            return nil
        }

        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let imageDirectory = documentsURL.appendingPathComponent("RecipeImages", isDirectory: true)
        let imageURL = imageDirectory.appendingPathComponent("\(recipeId.uuidString).jpg")

        do {
            try fileManager.createDirectory(at: imageDirectory, withIntermediateDirectories: true)
            try imageData.write(to: imageURL, options: .atomic)
            return imageURL.path
        } catch {
            return nil
        }
    }

    private func isLocalImageReference(_ reference: String) -> Bool {
        guard !reference.isEmpty, !reference.hasPrefix("http") else { return false }
        return FileManager.default.fileExists(atPath: reference)
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
