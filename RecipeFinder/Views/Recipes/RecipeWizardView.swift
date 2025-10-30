import SwiftUI

struct RecipeWizardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) var appTheme
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    let onComplete: (RecipeModel) -> Void
    let prefilledData: PrefilledRecipeData?
    
    // Struct for pre-filling wizard with imported data
    struct PrefilledRecipeData {
        let name: String?
        let ingredients: [String]?
        let instructions: [String]?
        let notes: String?
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
    
    // Initializer with optional prefilled data
    init(prefilledData: PrefilledRecipeData? = nil, onComplete: @escaping (RecipeModel) -> Void) {
        self.prefilledData = prefilledData
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
                    // Progress indicator
                    progressBar
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 20) {
                            stepContent
                        }
                        .padding()
                    }
                    
                    // Navigation buttons
                    navigationButtons
                }
            }
            .navigationTitle("Recipe Wizard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        HapticManager.shared.selection()
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onAppear {
                applyPrefilledData()
            }
        }
    }
    
    // Apply prefilled data from import
    private func applyPrefilledData() {
        guard let data = prefilledData else { return }
        
        // Pre-fill recipe name
        if let name = data.name, !name.isEmpty {
            recipeName = name
        }
        
        // Pre-fill ingredients (USDA-matched ingredients from import)
        if let ingredients = data.ingredients, !ingredients.isEmpty {
            ingredientItems = ingredients.map { ingredientName in
                IngredientItem(quantity: "1", unit: "", name: ingredientName)
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
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "Let's start with a name",
                subtitle: "What would you like to call this recipe?",
                stepNumber: 1
            )
            
            cardContainer {
                VStack(spacing: 16) {
                    TextField("Recipe Name", text: $recipeName)
                        .font(.title2)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                }
                .padding()
            }
        }
    }
    
    // MARK: - Step 2: Basic Info
    private var basicInfoStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "Basic Information",
                subtitle: "Tell us about the cooking times and details",
                stepNumber: 2
            )
            
            cardContainer {
                VStack(spacing: 20) {
                    // Prep Time
                    VStack(alignment: .leading, spacing: 8) {
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
                    VStack(alignment: .leading, spacing: 8) {
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
                    VStack(alignment: .leading, spacing: 8) {
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
                    VStack(alignment: .leading, spacing: 8) {
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
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "How many servings?",
                subtitle: "This will help with ingredient quantities",
                stepNumber: 3
            )
            
            cardContainer {
                VStack(spacing: 20) {
                    // Large display of servings
                    Text("\(servings)")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(AppTheme.accentColor(for: appTheme))
                    
                    Text("servings")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    // Stepper
                    Stepper("Adjust servings", value: $servings, in: 1...20)
                        .labelsHidden()
                }
                .padding(30)
            }
        }
    }
    
    // MARK: - Step 4: Ingredients
    private var ingredientsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "Ingredients",
                subtitle: "Add your ingredients with quantities",
                stepNumber: 4
            )
            
            cardContainer {
                VStack(spacing: 16) {
                    ForEach(Array(ingredientItems.enumerated()), id: \.offset) { index, _ in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Ingredient \(index + 1)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                if ingredientItems.count > 1 {
                                    Button(action: {
                                        HapticManager.shared.light()
                                        ingredientItems.remove(at: index)
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            
                            HStack(spacing: 8) {
                                // Quantity
                                TextField("Qty", text: $ingredientItems[index].quantity)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 60)
                                
                                // Unit
                                TextField("Unit", text: $ingredientItems[index].unit)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)
                                
                                // Name
                                TextField("Name", text: $ingredientItems[index].name)
                                    .textFieldStyle(.roundedBorder)
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
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "Pre-prep Instructions",
                subtitle: "Any prep work before cooking? (Optional)",
                stepNumber: 5
            )
            
            cardContainer {
                VStack(spacing: 12) {
                    ForEach(Array(prePrepSteps.enumerated()), id: \.offset) { index, _ in
                        VStack(alignment: .leading, spacing: 4) {
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
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "Cooking Instructions",
                subtitle: "Walk us through the cooking process",
                stepNumber: 6
            )
            
            cardContainer {
                VStack(spacing: 12) {
                    ForEach(Array(mainInstructions.enumerated()), id: \.offset) { index, _ in
                        VStack(alignment: .leading, spacing: 4) {
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
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "Final Notes",
                subtitle: "Any tips, variations, or additional notes? (Optional)",
                stepNumber: 7
            )
            
            cardContainer {
                VStack(spacing: 20) {
                    TextField("Add any notes, tips, or variations here...", text: $notes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(5...10)
                    
                    Divider()
                    
                    // Summary
                    VStack(alignment: .leading, spacing: 12) {
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
                }
                .padding()
            }
        }
    }
    
    // MARK: - Helper Views
    private func stepHeader(title: String, subtitle: String, stepNumber: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Step \(stepNumber) of \(totalSteps)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
            }
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
        }
    }
    
    private func summaryRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.accentColor(for: appTheme))
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
                            .fill(colorScheme == .dark ? Color(white: 0.15) : .white)
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
        HStack(spacing: 16) {
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
                    .foregroundColor(.white)
                    .cornerRadius(12)
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
                    Text(currentStep < totalSteps - 1 ? "Next" : "Create Recipe")
                    if currentStep < totalSteps - 1 {
                        Image(systemName: "chevron.right")
                    } else {
                        Image(systemName: "checkmark")
                    }
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canProceed ? Color.white : Color.white.opacity(0.5))
                .foregroundColor(canProceed ? AppTheme.accentColor(for: appTheme) : .white)
                .cornerRadius(12)
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
        
        // Filter out empty steps
        let filteredPrePrep = prePrepSteps.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let filteredInstructions = mainInstructions.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        let recipe = RecipeModel(
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
            isFavorite: false
        )
        
        HapticManager.shared.success()
        onComplete(recipe)
        dismiss()
    }
}

#Preview {
    RecipeWizardView(prefilledData: nil) { _ in }
        .environment(\.appTheme, .teal)
}
