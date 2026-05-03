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
        let prepTime: Int?
        let cookTime: Int?
        let servings: Int?
        let difficulty: String?
        let notes: String?
        let category: String?
        let isFavorite: Bool?
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
    
    @State private var prePrepSteps: [String] = [""]
    
    @State private var mainInstructions: [String] = [""]
    
    @State private var notes = ""
    
    @State private var showError = false
    @State private var errorMessage = ""
    
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
                    
                    progressBar
                    
                    ScrollView {
                        VStack(spacing: AppTheme.spacing32) {
                            stepContent
                        }
                        .padding(.top, 16)
                        .padding(.horizontal, 20)
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
            mainInstructions = instructions.isEmpty ? [""] : instructions
            if !instructions.isEmpty {
                mainInstructions.append("")
            }
        }
        
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
            ingredientsStep
        case 3:
            prePrepStep
        case 4:
            instructionsStep
        case 5:
            notesStep
        default:
            EmptyView()
        }
    }
    
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

                    Divider()

                    VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                        Text("Servings")
                            .font(.headline)
                            .foregroundColor(.primary)

                        HStack {
                            Stepper(
                                value: $servings, in: 1...20,
                                label: {
                                    HStack(spacing: AppTheme.spacing8) {
                                        Text("\(servings)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(AppTheme.accentColor(for: appTheme))
                                            .frame(minWidth: 32)
                                        Text(servings == 1 ? "serving" : "servings")
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            )
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private var ingredientsStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
            stepHeader(
                title: "Ingredients",
                subtitle: "Add your ingredients with quantities",
                stepNumber: 3,
                illustration: "cart.fill"
            )
            
            cardContainer {
                VStack(spacing: AppTheme.spacing12) {
                    ForEach(Array(ingredientItems.enumerated()), id: \.offset) { index, _ in
                        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                            HStack(spacing: AppTheme.spacing8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Ingredient")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    TextField("e.g. Chicken breast", text: $ingredientItems[index].name)
                                        .textFieldStyle(.roundedBorder)
                                }

                                if ingredientItems.count > 1 {
                                    Button(action: {
                                        HapticManager.shared.light()
                                        ingredientItems.remove(at: index)
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: AppTheme.fontSize22))
                                    }
                                    .padding(.top, 14)
                                }
                            }

                            HStack(alignment: .top, spacing: AppTheme.spacing8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Amount")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    TextField("0", text: $ingredientItems[index].quantity)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 70)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Unit")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Picker("", selection: $ingredientItems[index].unit) {
                                        Text("none").tag("")
                                        ForEach(cookingUnitGroups, id: \.group) { group in
                                            Section(group.group) {
                                                ForEach(group.units, id: \.self) { unit in
                                                    Text(unit).tag(unit)
                                                }
                                            }
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .labelsHidden()
                                    .frame(maxWidth: .infinity, minHeight: 34, alignment: .leading)
                                    .padding(.horizontal, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color(.systemGray6))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color(.systemGray4), lineWidth: 0.5)
                                    )
                                }
                            }
                        }
                        .padding(.vertical, 4)

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
    
    private var prePrepStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
            stepHeader(
                title: "Pre-prep Instructions",
                subtitle: "Any prep work before cooking? (Optional)",
                stepNumber: 4,
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
    
    private var instructionsStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
            stepHeader(
                title: "Cooking Instructions",
                subtitle: "Walk us through the cooking process",
                stepNumber: 5,
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
    
    private var notesStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
            stepHeader(
                title: "Final Notes",
                subtitle: prefilledData?.notes != nil && !notes.isEmpty ? "Review notes or add your own" : "Any tips, variations, or additional notes? (Optional)",
                stepNumber: 6,
                illustration: "note.text"
            )
            
            cardContainer {
                VStack(spacing: AppTheme.spacing24) {
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
    
    private func stepHeader(title: String, subtitle: String, stepNumber: Int, illustration: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("Step \(stepNumber) of \(totalSteps)")
                .font(.caption)
                .fontWeight(.medium)
                .adaptiveForegroundColor(opacity: 0.8)
            
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
            return servings > 0
        case 2:
            return ingredientItems.contains { !$0.name.isEmpty }
        case 3:
            return true
        case 4:
            return mainInstructions.contains { !$0.isEmpty }
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
        
        let filteredPrePrep = prePrepSteps.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let filteredInstructions = mainInstructions.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        guard !filteredInstructions.isEmpty else {
            errorMessage = "Please add at least one cooking instruction"
            showError = true
            HapticManager.shared.error()
            return
        }
        
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
    
    private func parseIngredientString(_ fullIngredient: String) -> IngredientItem {
        let trimmed = fullIngredient.trimmingCharacters(in: .whitespaces)
        
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
        
        let unitPattern = #"^(tbsp|tsp|cup|cups|ml|l|liter|liters|g|kg|oz|lb|lbs|cloves|clove|pieces|piece|pinch|dash)(\s+|$)"#
        var unit = ""
        
        if let regex = try? NSRegularExpression(pattern: unitPattern, options: .caseInsensitive) {
            let nsString = remaining as NSString
            if let match = regex.firstMatch(in: remaining, options: [], range: NSRange(location: 0, length: nsString.length)) {
                let unitRange = match.range(at: 1)
                unit = nsString.substring(with: unitRange)
                let afterUnit = match.range.location + match.range.length
                remaining = nsString.substring(from: afterUnit)
            }
        }
        
        var name = remaining.trimmingCharacters(in: .whitespaces)
        
        if let commaIndex = name.firstIndex(of: ",") {
            name = String(name[..<commaIndex])
        }
        
        name = name.trimmingCharacters(in: .whitespaces)
        
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
