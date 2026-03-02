import SwiftUI

struct RecipeWizardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) var appTheme
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    let onComplete: (RecipeModel) -> Void
    let prefilledData: PrefilledRecipeData?
    let editingRecipeId: UUID?  // For preserving recipe ID when editing
    
    // Struct for pre-filling wizard with imported data
    struct PrefilledRecipeData {
        let name: String?
        let description: String?
        let ingredients: [String]?
        let instructions: [String]?
        let prepTime: Int?
        let cookTime: Int?
        let servings: Int?
        let difficulty: String?
        let notes: String?
        let category: String?  // Add category support
        let isFavorite: Bool?  // Preserve favorite status
    }
    
    // Step tracking
    @State private var currentStep = 0
    private let totalSteps = 7
    
    // Step 1: Recipe Name
    @State private var recipeName = ""
    
    // Step 2: Basic Info (prep time, cook time, difficulty, category)
    @State private var prepTime = 15
    @State private var cookTime = 30
    @State private var difficulty = "Intermediate"
    @State private var category = "Main"
    
    // Step 3: Servings
    @State private var servings = 4
    
    // Step 4: Ingredients with quantities
    @State private var ingredientItems: [IngredientItem] = [IngredientItem()]
    
    // Step 5: Pre-prep instructions
    @State private var prePrepSteps: [String] = [""]
    
    // Step 6: Main instructions
    @State private var mainInstructions: [String] = [""]
    
    // Step 7: Notes
    @State private var notes = ""
    
    // Validation
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Initializer with optional prefilled data
    // SIMPLE LOGIC: Always start from step 0, whether creating or editing
    // Pre-filled data just populates the fields, that's it!
    init(prefilledData: PrefilledRecipeData? = nil, editingRecipeId: UUID? = nil, onComplete: @escaping (RecipeModel) -> Void) {
        self.prefilledData = prefilledData
        self.editingRecipeId = editingRecipeId
        self.onComplete = onComplete
    }
    
    let difficulties = ["Basic", "Intermediate", "Expert"]
    let categories = ["Breakfast", "Starter", "Main", "Side", "Soup", "Dessert", "Drink"]
    
    // Helper struct for ingredient input
    struct IngredientItem: Identifiable {
        let id = UUID()
        var quantity: String = ""
        var unit: String = ""
        var name: String = ""
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Section
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
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(AppTheme.cornerRadius12)
                                }
                                
                                Spacer()
                                
                                Text("Recipe Wizard")
                                    .font(.system(size: min(24, geometry.size.width * 0.06), weight: .bold))
                                    .adaptiveForegroundColor()
                                
                                Spacer()
                                
                                // Invisible button for balance
                                Button(action: {}) {
                                    Text("Cancel")
                                        .font(.body)
                                        .foregroundColor(.clear)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                }
                                .disabled(true)
                            }
                        }
                        .frame(height: 44)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Progress indicator
                    progressBar
                    
                    // Content
                    ScrollView {
                        VStack(spacing: AppTheme.spacing32) {
                            stepContent
                        }
                        .padding(.top, 16)
                        .padding(.horizontal, 20)
                    }
                    
                    // Navigation buttons
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
    }
    
    // Apply prefilled data from import
    private func applyPrefilledData() {
        guard let data = prefilledData else { return }
        
        // Pre-fill recipe name
        if let name = data.name, !name.isEmpty {
            recipeName = name
        }
        
        // Pre-fill category
        if let category = data.category, !category.isEmpty {
            self.category = category
        }
        
        // Pre-fill times
        if let prepTime = data.prepTime {
            self.prepTime = prepTime
        }
        if let cookTime = data.cookTime {
            self.cookTime = cookTime
        }
        
        // Pre-fill servings
        if let servings = data.servings {
            self.servings = servings
        }
        
        // Pre-fill difficulty
        if let difficulty = data.difficulty, !difficulty.isEmpty {
            // Normalize to match our options
            let normalized = difficulty.lowercased()
            if normalized.contains("easy") || normalized.contains("basic") || normalized.contains("beginner") {
                self.difficulty = "Basic"
            } else if normalized.contains("hard") || normalized.contains("expert") || normalized.contains("advanced") {
                self.difficulty = "Expert"
            } else {
                self.difficulty = "Intermediate"
            }
        }
        
        // Pre-fill ingredients (parse full ingredient strings from import)
        if let ingredients = data.ingredients, !ingredients.isEmpty {
            ingredientItems = ingredients.map { fullIngredient in
                return parseIngredientString(fullIngredient)
            }
            // Add one empty row for user to add more
            if !ingredients.isEmpty {
                ingredientItems.append(IngredientItem())
            }
        }
        
        // Pre-fill instructions
        if let instructions = data.instructions, !instructions.isEmpty {
            mainInstructions = instructions.isEmpty ? [""] : instructions
            // Add one empty step for user to add more
            if !instructions.isEmpty {
                mainInstructions.append("")
            }
        }
        
        // Pre-fill notes
        if let notes = data.notes, !notes.isEmpty {
            self.notes = notes
        }
    }
    
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                
                Rectangle()
                    .fill(Color.white)
                    .frame(width: geometry.size.width * CGFloat(currentStep + 1) / CGFloat(totalSteps))
            }
        }
        .frame(height: 4)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            recipeNameStep
        case 1:
            basicInfoStep
        case 2:
            servingsStep
        case 3:
            ingredientsStep
        case 4:
            prePrepStep
        case 5:
            instructionsStep
        case 6:
            notesStep
        default:
            EmptyView()
        }
    }
    
    // MARK: - Step 1: Recipe Name
    private var recipeNameStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
            stepHeader(
                title: "Let's start with a name",
                subtitle: "What would you like to call this recipe?",
                stepNumber: 1,
                illustration: "doc.text.fill"
            )
            
            cardContainer {
                VStack(spacing: AppTheme.spacing16) {
                    TextField("Recipe Name", text: $recipeName)
                        .font(.title2)
                        .padding()
                        .background(Color.white.opacity(AppTheme.dividerOpacity))
                        .cornerRadius(AppTheme.cornerRadius12)
                }
                .padding()
            }
        }
    }
    
    // MARK: - Step 2: Basic Info
    private var basicInfoStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
            stepHeader(
                title: "Tell us more",
                subtitle: "Add some details about your recipe",
                stepNumber: 2,
                illustration: "slider.horizontal.3"
            )
            
            cardContainer {
                VStack(spacing: AppTheme.spacing24) {
                    // Prep Time
                    VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                        Text("Prep Time")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Stepper("\(prepTime) minutes", value: $prepTime, in: 0...300, step: 5)
                                .font(.body)
                        }
                    }
                    
                    Divider()
                    
                    // Cook Time
                    VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                        Text("Cook Time")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Stepper("\(cookTime) minutes", value: $cookTime, in: 0...480, step: 5)
                                .font(.body)
                        }
                    }
                    
                    Divider()
                    
                    // Difficulty
                    VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                        Text("Difficulty")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Picker("Difficulty", selection: $difficulty) {
                            ForEach(difficulties, id: \.self) { diff in
                                Text(diff).tag(diff)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    Divider()
                    
                    // Category
                    VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                        Text("Category")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Picker("Category", selection: $category) {
                            ForEach(categories, id: \.self) { cat in
                                Text(cat).tag(cat)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Step 3: Servings
    private var servingsStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
            stepHeader(
                title: "How many servings?",
                subtitle: "This will help with ingredient quantities",
                stepNumber: 3,
                illustration: "person.2.fill"
            )
            
            cardContainer {
                VStack(spacing: AppTheme.spacing24) {
                    // Large display of servings
                    Text("\(servings)")
                        .font(.system(size: AppTheme.fontSize80, weight: .bold))
                        .foregroundColor(AppTheme.accentColor(for: appTheme))
                    
                    Text("servings")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    // Stepper
                    Stepper("Adjust servings", value: $servings, in: 1...20)
                        .labelsHidden()
                }
                .padding(AppTheme.spacing32)
            }
        }
    }
    
    // MARK: - Step 4: Ingredients
    private var ingredientsStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
            stepHeader(
                title: "Ingredients",
                subtitle: "Add your ingredients with quantities",
                stepNumber: 4,
                illustration: "cart.fill"
            )
            
            cardContainer {
                VStack(spacing: AppTheme.spacing16) {
                    ForEach(Array(ingredientItems.enumerated()), id: \.offset) { index, _ in
                        HStack(spacing: AppTheme.spacing12) {
                            // Combined Quantity field (amount + unit)
                            VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                                Text("Quantity")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                HStack(spacing: AppTheme.spacing4) {
                                    TextField("Qty", text: $ingredientItems[index].quantity)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 50)
                                    TextField("Unit", text: $ingredientItems[index].unit)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 60)
                                }
                            }
                            
                            // Ingredient Name
                            VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                                Text("Ingredient")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                TextField("Ingredient Name", text: $ingredientItems[index].name)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            // Delete button
                            if ingredientItems.count > 1 {
                                Button(action: {
                                    HapticManager.shared.light()
                                    ingredientItems.remove(at: index)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.system(size: AppTheme.fontSize24))
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        
                        if index < ingredientItems.count - 1 {
                            Divider()
                        }
                    }
                    
                    Button(action: {
                        HapticManager.shared.light()
                        ingredientItems.append(IngredientItem())
                    }) {
                        Label("Add Ingredient", systemImage: "plus.circle.fill")
                            .foregroundColor(AppTheme.accentColor(for: appTheme))
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Step 5: Pre-prep Instructions
    private var prePrepStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
            stepHeader(
                title: "Pre-prep Instructions",
                subtitle: "Any prep work before cooking? (Optional)",
                stepNumber: 5,
                illustration: "list.bullet.clipboard.fill"
            )
            
            cardContainer {
                VStack(spacing: AppTheme.spacing12) {
                    ForEach(Array(prePrepSteps.enumerated()), id: \.offset) { index, _ in
                        VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                            HStack {
                                Text("Step \(index + 1)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                if prePrepSteps.count > 1 {
                                    Button(action: {
                                        HapticManager.shared.light()
                                        prePrepSteps.remove(at: index)
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            
                            TextField("Describe the pre-prep step", text: $prePrepSteps[index], axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(2...5)
                        }
                        
                        if index < prePrepSteps.count - 1 {
                            Divider()
                        }
                    }
                    
                    Button(action: {
                        HapticManager.shared.light()
                        prePrepSteps.append("")
                    }) {
                        Label("Add Pre-prep Step", systemImage: "plus.circle.fill")
                            .foregroundColor(AppTheme.accentColor(for: appTheme))
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Step 6: Main Instructions
    private var instructionsStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
            stepHeader(
                title: "Cooking Instructions",
                subtitle: "Walk us through the cooking process",
                stepNumber: 6,
                illustration: "flame.fill"
            )
            
            cardContainer {
                VStack(spacing: AppTheme.spacing12) {
                    ForEach(Array(mainInstructions.enumerated()), id: \.offset) { index, _ in
                        VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                            HStack {
                                Text("Step \(index + 1)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                if mainInstructions.count > 1 {
                                    Button(action: {
                                        HapticManager.shared.light()
                                        mainInstructions.remove(at: index)
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            
                            TextField("Describe this cooking step", text: $mainInstructions[index], axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(2...5)
                        }
                        
                        if index < mainInstructions.count - 1 {
                            Divider()
                        }
                    }
                    
                    Button(action: {
                        HapticManager.shared.light()
                        mainInstructions.append("")
                    }) {
                        Label("Add Cooking Step", systemImage: "plus.circle.fill")
                            .foregroundColor(AppTheme.accentColor(for: appTheme))
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Step 7: Notes
    private var notesStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
            stepHeader(
                title: "Final Notes",
                subtitle: prefilledData?.notes != nil && !notes.isEmpty ? "Review notes or add your own" : "Any tips, variations, or additional notes? (Optional)",
                stepNumber: 7,
                illustration: "note.text"
            )
            
            cardContainer {
                VStack(spacing: AppTheme.spacing24) {
                    // Show a preview label if there are existing notes from import/edit
                    if prefilledData?.notes != nil && !notes.isEmpty {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("Pre-filled notes from recipe")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.bottom, 8)
                    }
                    
                    // Notes text editor with better styling
                    ZStack(alignment: .topLeading) {
                        if notes.isEmpty {
                            VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                                Text("Add your notes here...")
                                    .foregroundColor(.secondary.opacity(0.5))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 8)
                                
                                Text("Try adding:")
                                    .font(.caption)
                                    .foregroundColor(.secondary.opacity(0.4))
                                    .padding(.horizontal, 4)
                                
                                Text("• Substitution ideas")
                                    .font(.caption)
                                    .foregroundColor(.secondary.opacity(0.4))
                                    .padding(.horizontal, 4)
                                Text("• Storage tips")
                                    .font(.caption)
                                    .foregroundColor(.secondary.opacity(0.4))
                                    .padding(.horizontal, 4)
                                Text("• Serving suggestions")
                                    .font(.caption)
                                    .foregroundColor(.secondary.opacity(0.4))
                                    .padding(.horizontal, 4)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .allowsHitTesting(false)
                        }
                        
                        TextField("", text: $notes, axis: .vertical)
                            .textFieldStyle(.plain)
                            .lineLimit(8...15)
                            .padding(AppTheme.spacing4)
                    }
                    .padding(AppTheme.spacing8)
                    .background(Color(.systemGray6))
                    .cornerRadius(AppTheme.cornerRadius8)
                    
                    // Quick add buttons for common note types (always show)
                    VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                        Text("Quick Add:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppTheme.spacing8) {
                                quickNoteButton(icon: "leaf.fill", text: "Make it healthier", template: "💚 Healthier Option:\n• ")
                                quickNoteButton(icon: "carrot.fill", text: "Make it vegan", template: "🌱 Vegan Version:\n• ")
                                quickNoteButton(icon: "clock.fill", text: "Save time", template: "⏰ Time-Saving Tip:\n• ")
                                quickNoteButton(icon: "arrow.triangle.swap", text: "Substitutions", template: "🔄 Substitutions:\n• ")
                                quickNoteButton(icon: "snowflake", text: "Storage", template: "❄️ Storage:\n• ")
                                quickNoteButton(icon: "star.fill", text: "Pro tip", template: "✨ Pro Tip:\n• ")
                            }
                        }
                    }
                }
                
                Divider()
                    
                    // Summary
                    VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                        Text("Recipe Summary")
                            .font(.headline)
                        
                        summaryRow(icon: "fork.knife", label: "Name", value: recipeName.isEmpty ? "—" : recipeName)
                        summaryRow(icon: "tag", label: "Category", value: category)
                        summaryRow(icon: "chart.bar", label: "Difficulty", value: difficulty)
                        summaryRow(icon: "person.2", label: "Servings", value: "\(servings)")
                        summaryRow(icon: "clock", label: "Prep Time", value: "\(prepTime) min")
                        summaryRow(icon: "flame", label: "Cook Time", value: "\(cookTime) min")
                        summaryRow(icon: "list.bullet", label: "Ingredients", value: "\(ingredientItems.filter { !$0.name.isEmpty }.count)")
                        summaryRow(icon: "list.number", label: "Pre-prep Steps", value: "\(prePrepSteps.filter { !$0.isEmpty }.count)")
                        summaryRow(icon: "list.number", label: "Cooking Steps", value: "\(mainInstructions.filter { !$0.isEmpty }.count)")
                    }
                .padding()
            }
        }
    }
    
    // Quick note button helper
    private func quickNoteButton(icon: String, text: String, template: String) -> some View {
        Button(action: {
            HapticManager.shared.light()
            if !notes.isEmpty {
                notes += "\n\n"
            }
            notes += template
        }) {
            HStack(spacing: AppTheme.spacing4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(text)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray5))
            .cornerRadius(AppTheme.cornerRadius16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Views
    private func stepHeader(title: String, subtitle: String, stepNumber: Int, illustration: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            // Step indicator
            Text("Step \(stepNumber) of \(totalSteps)")
                .font(.caption)
                .fontWeight(.medium)
                .adaptiveForegroundColor(opacity: 0.8)
            
            // Title with icon overlay
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .adaptiveForegroundColor()
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .adaptiveForegroundColor(opacity: 0.9)
                }
                
                Spacer()
            }
            .overlay(alignment: .topTrailing) {
                // Icon positioned absolutely, doesn't affect layout
                Image(systemName: illustration)
                    .font(.system(size: AppTheme.fontSize42, weight: .medium))
                    .adaptiveForegroundColor(opacity: 0.6)
            }
        }
    }
    
    private func summaryRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: AppTheme.spacing12) {
            Image(systemName: icon)
                .adaptiveForegroundColor()
                .frame(width: 20)
            
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
    
    private func cardContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        Group {
            if cardStyle == .solid {
                content()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color(white: AppTheme.cardDarkOpacity) : .white)
                    )
            } else {
                content()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
            }
        }
    }
    
    // MARK: - Navigation
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
                    .background(Color.white.opacity(0.3))
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
            return !recipeName.trimmingCharacters(in: .whitespaces).isEmpty
        case 1:
            return true // Basic info always valid with defaults
        case 2:
            return servings > 0
        case 3:
            return ingredientItems.contains { !$0.name.isEmpty }
        case 4:
            return true // Pre-prep is optional
        case 5:
            return mainInstructions.contains { !$0.isEmpty }
        case 6:
            return true // Notes are optional
        default:
            return false
        }
    }
    
    // MARK: - Recipe Creation
    private func createRecipe() {
        // Validate recipe name
        do {
            try Validator.validateRecipeName(recipeName)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            HapticManager.shared.error()
            return
        }
        
        // Validate servings
        do {
            try Validator.validateServings(servings)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            HapticManager.shared.error()
            return
        }
        
        // Convert ingredient items to Ingredient objects
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
        
        // Ensure at least one ingredient
        guard !ingredients.isEmpty else {
            errorMessage = "Please add at least one ingredient"
            showError = true
            HapticManager.shared.error()
            return
        }
        
        // Filter out empty steps
        let filteredPrePrep = prePrepSteps.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let filteredInstructions = mainInstructions.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        // Ensure at least one instruction
        guard !filteredInstructions.isEmpty else {
            errorMessage = "Please add at least one cooking instruction"
            showError = true
            HapticManager.shared.error()
            return
        }
        
        // Determine if we're creating a new recipe or updating an existing one
        let recipeId = editingRecipeId ?? UUID()
        let isFavorite = prefilledData?.isFavorite ?? false
        
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
            imageName: nil,
            isFavorite: isFavorite
        )
        
        HapticManager.shared.success()
        onComplete(recipe)
        dismiss()
    }
    
    // Parse ingredient string like "1 tbsp Sunflower oil" or "600 g Chicken breast, Cut into cubes"
    private func parseIngredientString(_ fullIngredient: String) -> IngredientItem {
        let trimmed = fullIngredient.trimmingCharacters(in: .whitespaces)
        
        // Pattern: [quantity] [unit] [name][, notes]
        // Try to extract quantity (number or fraction at start)
        let quantityPattern = #"^([\d\./\-]+)\s+"#
        var quantity = ""
        var remaining = trimmed
        
        if let regex = try? NSRegularExpression(pattern: quantityPattern, options: []) {
            let nsString = trimmed as NSString
            if let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(location: 0, length: nsString.length)) {
                let quantityRange = match.range(at: 1)
                quantity = nsString.substring(with: quantityRange)
                remaining = nsString.substring(from: match.range.location + match.range.length)
            }
        }
        
        // Try to extract unit (common cooking units) - must be followed by a space or end of string
        let unitPattern = #"^(tbsp|tsp|cup|cups|ml|l|liter|liters|g|kg|oz|lb|lbs|cloves|clove|pieces|piece|pinch|dash)(\s+|$)"#
        var unit = ""
        
        if let regex = try? NSRegularExpression(pattern: unitPattern, options: .caseInsensitive) {
            let nsString = remaining as NSString
            if let match = regex.firstMatch(in: remaining, options: [], range: NSRange(location: 0, length: nsString.length)) {
                let unitRange = match.range(at: 1)
                unit = nsString.substring(with: unitRange)
                // Move past the unit and any following space
                let afterUnit = match.range.location + match.range.length
                remaining = nsString.substring(from: afterUnit)
            }
        }
        
        // The rest is the name (and optional notes after comma)
        var name = remaining.trimmingCharacters(in: .whitespaces)
        
        // Remove notes if present (after comma)
        if let commaIndex = name.firstIndex(of: ",") {
            name = String(name[..<commaIndex])
        }
        
        name = name.trimmingCharacters(in: .whitespaces)
        
        // If we didn't find quantity/unit, treat entire string as name
        if quantity.isEmpty && unit.isEmpty && name.isEmpty {
            name = trimmed
        }
        
        return IngredientItem(quantity: quantity, unit: unit, name: name)
    }
}

#Preview {
    RecipeWizardView(prefilledData: nil) { _ in }
        .environment(\.appTheme, AppTheme.ThemeType.teal)
}
