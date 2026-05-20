import ConfettiSwiftUI
import SwiftUI

struct RecipeDetailView: View {
    @State private var recipe: RecipeModel
    @State private var ingredientsState: [Bool]
    @State private var instructionsState: [Bool]
    @State private var prePrepState: [Bool]
    @State private var expandedSections: Set<String> = ["Ingredients", "Pre-Prep", "Instructions", "Notes"]
    @State private var addedIngredients: Set<String> = []
    @State private var showAddedFeedback: String?
    @State private var confettiCounter = 0
    @State private var showEditSheet = false
    @State private var showTimerSheet = false
    @State private var editingIngredientIndex: Int?
    @State private var editingQuantity: String = ""
    @State private var editingUnit: String = ""
    @AppStorage("hasSeenSwipeHint") private var hasSeenSwipeHint = false
    @AppStorage("measurementSystem") private var measurementSystem: MeasurementSystem = .metric
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    
    private var hasPrePrep: Bool { !recipe.prePrepInstructions.isEmpty }
    private var hasNotes: Bool { !recipe.notes.isEmpty }
    
    var onFavoriteToggle: (() -> Void)?
    
    init(recipe: RecipeModel, onFavoriteToggle: (() -> Void)? = nil) {
        _recipe = State(initialValue: recipe)
        self.onFavoriteToggle = onFavoriteToggle
        
        _ingredientsState = State(initialValue: Array(repeating: false, count: recipe.ingredients.count))
        _instructionsState = State(initialValue: Array(repeating: false, count: recipe.instructions.count))
        _prePrepState = State(initialValue: Array(repeating: false, count: recipe.prePrepInstructions.count))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundView
                
                ScrollView([.vertical], showsIndicators: true) {
                    VStack(spacing: 0) {
                        recipeTitleView
                        recipeInfoCardsView
                        ingredientsSection
                        
                        if hasPrePrep {
                            prePrepSection
                        }
                        
                        instructionsSection
                        
                        if hasNotes {
                            notesSection
                        }
                    }
                    .padding(.bottom, AppTheme.spacing100)
                    .frame(width: geometry.size.width)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                toolbarButtons
            }
        }
        .sheet(isPresented: $showEditSheet) {
            editRecipeSheet
        }
        .sheet(isPresented: $showTimerSheet) {
            CookTimerView()
        }
        .overlay(alignment: .bottom) {
            feedbackOverlay
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showAddedFeedback)
        .confettiCannon(trigger: $confettiCounter, num: AppTheme.confettiCount, radius: AppTheme.confettiRadius)
        .onChange(of: instructionsState) { _, newValue in
            checkForCompletion(newValue)
        }
        .onChange(of: recipe) { _, newRecipe in
            if ingredientsState.count != newRecipe.ingredients.count {
                ingredientsState = Array(repeating: false, count: newRecipe.ingredients.count)
            }
            if instructionsState.count != newRecipe.instructions.count {
                instructionsState = Array(repeating: false, count: newRecipe.instructions.count)
            }
            if prePrepState.count != newRecipe.prePrepInstructions.count {
                prePrepState = Array(repeating: false, count: newRecipe.prePrepInstructions.count)
            }
        }
    }
    
    private var backgroundView: some View {
        AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
            .ignoresSafeArea()
    }
    
    private var recipeTitleView: some View {
        VStack(spacing: AppTheme.spacing12) {
            if let imageName = recipe.imageName, !imageName.isEmpty {
                RecipeImageView(imageName: imageName, height: 220)
                    .padding(.horizontal, AppTheme.spacing20)
                    .padding(.top, AppTheme.spacing8)
            }

            Text(recipe.name)
                .font(.system(size: AppTheme.fontSize34, weight: .bold))
                .adaptiveForegroundColor()
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, AppTheme.spacing20)
                .padding(.top, recipe.imageName?.isEmpty == false ? 0 : AppTheme.spacing8)
                .padding(.bottom, AppTheme.spacing20)
        }
    }
    
    private var recipeInfoCardsView: some View {
        VStack(spacing: AppTheme.spacing16) {
            timeInfoCard
            detailsInfoCard
            servingsCard
        }
        .padding(.horizontal, AppTheme.spacing20)
    }
    
    private var timeInfoCard: some View {
        GlassCard {
            InfoPairView(
                label1: "Prep time", value1: recipe.prepTime, icon1: "clock",
                label2: "Cook time", value2: recipe.cookingTime, icon2: "flame"
            )
            .padding()
        }
    }
    
    private var detailsInfoCard: some View {
        GlassCard {
            InfoPairView(
                label1: "Difficulty", value1: recipe.difficulty, icon1: "chart.bar",
                label2: "Category", value2: recipe.category, icon2: "fork.knife"
            )
            .padding()
        }
    }
    
    private var servingsCard: some View {
        GlassCard {
            VStack(spacing: AppTheme.spacing16) {
                HStack {
                    servingsDisplay
                    
                    Divider()
                        .frame(height: AppTheme.height60)
                        .padding(.horizontal)
                    
                    servingsControls
                }
                
                Divider()
                    .background(Color.white.opacity(AppTheme.shadowDarkOpacity))
                
                quickScaleButtons
            }
            .padding()
        }
    }
    
    private var servingsDisplay: some View {
        VStack(spacing: AppTheme.spacing8) {
            Image(systemName: "person.2.fill")
                .font(.title2)
                .foregroundColor(.cyan)
                .accessibilityHidden(true)
            Text("Servings")
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
            
            HStack(spacing: AppTheme.spacing4) {
                Text("\(recipe.currentServings)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                if recipe.currentServings != recipe.baseServings {
                    Text("(\(String(format: "%.1fx", recipe.scaleFactor)))")
                        .font(.caption)
                        .foregroundColor(AppTheme.accentColor)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Current servings: \(recipe.currentServings)")
            .accessibilityValue(recipe.currentServings != recipe.baseServings ? "Scaled \(String(format: "%.1f", recipe.scaleFactor)) times from base" : "Base servings")
        }
        .frame(maxWidth: .infinity)
    }
    
    private var servingsControls: some View {
        HStack(spacing: AppTheme.spacing12) {
            servingsButton(icon: "minus", action: decreaseServings, isEnabled: recipe.currentServings > 1)
            servingsButton(icon: "plus", action: increaseServings, isEnabled: true)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var quickScaleButtons: some View {
        HStack(spacing: AppTheme.spacing8) {
            quickScaleButton(label: "½x", multiplier: 0.5)
            quickScaleButton(label: "1x", multiplier: 1.0)
            quickScaleButton(label: "2x", multiplier: 2.0)
            quickScaleButton(label: "3x", multiplier: 3.0)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func quickScaleButton(label: String, multiplier: Double) -> some View {
        let targetServings = Int(Double(recipe.baseServings) * multiplier)
        let isActive = recipe.currentServings == targetServings
        
        return Button(action: {
            HapticManager.shared.light()
            withAnimation(.spring(response: 0.3)) {
                recipe.updateServings(to: targetServings)
            }
        }) {
            Text(label)
                .font(.subheadline)
                .fontWeight(isActive ? .bold : .medium)
                .foregroundColor(isActive ? .white : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.height36)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius8)
                        .fill(isActive ? AppTheme.accentColor : Color.white.opacity(0.15))
                )
        }
        .accessibilityLabel("Scale to \(label)")
        .accessibilityValue(isActive ? "Active" : "Inactive")
        .accessibilityHint("Sets servings to \(targetServings)")
        .accessibilityAddTraits(.isButton)
    }
    
    private func servingsButton(icon: String, action: @escaping () -> Void, isEnabled: Bool) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: AppTheme.fontSize18, weight: .semibold))
                .adaptiveForegroundColor()
                .frame(width: AppTheme.buttonHeight, height: AppTheme.height44)
                .background(Circle().fill(isEnabled ? AppTheme.accentColor : Color.gray))
        }
        .disabled(!isEnabled)
        .accessibilityLabel(icon == "minus" ? "Decrease servings" : "Increase servings")
        .accessibilityHint(icon == "minus" ? "Reduces serving size by one" : "Increases serving size by one")
        .accessibilityAddTraits(.isButton)
    }
    
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            ingredientsSectionHeader
            
            if expandedSections.contains("Ingredients") {
                ingredientsList
                    .transition(.asymmetric(
                        insertion: .scale(scale: AppTheme.transitionScaleDown).combined(with: .opacity),
                        removal: .scale(scale: AppTheme.transitionScaleDown).combined(with: .opacity)
                    ))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppTheme.spacing20)
    }
    
    private var ingredientsSectionHeader: some View {
        HStack(spacing: AppTheme.spacing8) {
            Button(action: { toggleSection("Ingredients") }) {
                HStack(spacing: AppTheme.spacing8) {
                    Image(systemName: "leaf.fill")
                        .adaptiveForegroundColor()
                        .font(.title3)
                    Text("Ingredients")
                        .font(.title2)
                        .fontWeight(.bold)
                        .adaptiveForegroundColor()
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            measurementToggle
            chevronButton(for: "Ingredients")
        }
        .padding(.top, AppTheme.spacing24)
    }
    
    private var measurementToggle: some View {
        Button(action: toggleMeasurementSystem) {
            HStack(spacing: AppTheme.spacing6) {
                Image(systemName: measurementSystem.icon)
                    .font(.caption)
                Text(measurementSystem.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .adaptiveForegroundColor()
            .padding(.horizontal, AppTheme.spacing12)
            .padding(.vertical, AppTheme.spacing6)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius8)
                    .fill(colorScheme == .dark ? Color.white.opacity(AppTheme.overlayLightOpacity) : Color.black.opacity(AppTheme.dividerOpacity))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Measurement system")
        .accessibilityValue(measurementSystem.rawValue)
        .accessibilityHint("Double tap to switch between metric and imperial units")
    }
    
    private func chevronButton(for section: String) -> some View {
        Button(action: { toggleSection(section) }) {
            Image(systemName: "chevron.down")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.adaptiveHighEmphasis(for: colorScheme))
                .rotationEffect(.degrees(expandedSections.contains(section) ? 0 : -90))
                .animation(.spring(response: 0.3), value: expandedSections.contains(section))
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(expandedSections.contains(section) ? "Collapse \(section)" : "Expand \(section)")
        .accessibilityHint("Double tap to \(expandedSections.contains(section) ? "collapse" : "expand") \(section) section")
        .accessibilityAddTraits(.isButton)
    }
    
    private var ingredientsList: some View {
        GlassCard {
            VStack(spacing: AppTheme.spacing16) {
                if !hasSeenSwipeHint {
                    HStack(spacing: AppTheme.spacing8) {
                        Image(systemName: "hand.draw")
                            .font(.system(size: AppTheme.fontSize16))
                            .foregroundColor(AppTheme.accentColor)
                        
                        Text("Swipe left to add to shopping list")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                hasSeenSwipeHint = true
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: AppTheme.fontSize16))
                                .foregroundColor(.secondary.opacity(AppTheme.glassLightOpacity))
                        }                        .accessibilityLabel("Dismiss hint")
                        .accessibilityHint("Closes swipe instruction banner")                    }
                    .padding(.horizontal, AppTheme.spacing12)
                    .padding(.vertical, AppTheme.spacing8)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius8)
                            .fill(AppTheme.accentColor.opacity(0.1))
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                ForEach(recipe.ingredients.indices, id: \.self) { index in
                    IngredientRowView(
                        ingredient: recipe.ingredients[index],
                        isChecked: ingredientsState[index],
                        toggle: { 
                            HapticManager.shared.light()
                            ingredientsState[index].toggle()
                            checkForCompletion()
                        },
                        scaleFactor: recipe.scaleFactor,
                        measurementSystem: measurementSystem,
                        onAddToShopping: {
                            addIngredientToShoppingList(recipe.ingredients[index])
                        },
                        isInShoppingList: isIngredientInShoppingList(recipe.ingredients[index]),
                        onTapQuantity: {
                            startEditingIngredient(at: index)
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppTheme.spacing24)
        }
        .sheet(item: Binding(
            get: { editingIngredientIndex.map { EditingIngredient(index: $0) } },
            set: { editingIngredientIndex = $0?.index }
        )) { editingItem in
            ingredientEditSheet(for: editingItem.index)
        }
    }
    
    private struct EditingIngredient: Identifiable {
        let index: Int
        var id: Int { index }
    }
    
    private var prePrepSection: some View {
        collapsibleSection(title: "Pre-Prep", icon: "list.clipboard") {
            VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                ForEach(recipe.prePrepInstructions.indices, id: \.self) { index in
                    instructionRow(
                        text: recipe.prePrepInstructions[index],
                        isChecked: prePrepState[index],
                        toggle: { 
                            HapticManager.shared.light()
                            prePrepState[index].toggle()
                            checkForCompletion()
                        }
                    )
                }
            }
        }
    }
    
    private var instructionsSection: some View {
        collapsibleSection(title: "Instructions", icon: "text.alignleft") {
            VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                ForEach(recipe.instructions.indices, id: \.self) { index in
                    instructionRow(
                        text: recipe.instructions[index],
                        isChecked: instructionsState[index],
                        toggle: { 
                            HapticManager.shared.light()
                            instructionsState[index].toggle()
                            checkForCompletion()
                        }
                    )
                }
            }
        }
    }
    
    private var notesSection: some View {
        collapsibleSection(title: "Notes", icon: "note.text") {
            Text(recipe.notes)
                .font(.subheadline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var toolbarButtons: some View {
        HStack(spacing: AppTheme.spacing16) {
            Button(action: { showTimerSheet = true }) {
                Image(systemName: "timer")
                    .font(.title3)
                    .adaptiveForegroundColor()
            }
            
            Button(action: { showEditSheet = true }) {
                Image(systemName: "pencil")
                    .font(.title3)
                    .adaptiveForegroundColor()
            }
            
            Button(action: toggleFavorite) {
                Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundColor(recipe.isFavorite ? .red : .white)
            }
        }
    }
    
    private var editRecipeSheet: some View {
        RecipeWizardView(
            prefilledData: RecipeWizardView.PrefilledRecipeData(
                name: recipe.name,
                description: nil,
                ingredients: recipe.ingredients.map { "\(String(format: "%g", $0.baseQuantity)) \($0.unit) \($0.name)" },
                instructions: recipe.instructions,
                prepTime: TimeExtractor.extractMinutes(from: recipe.prepTime),
                cookTime: TimeExtractor.extractMinutes(from: recipe.cookingTime),
                servings: recipe.baseServings,
                difficulty: recipe.difficulty,
                notes: recipe.notes.isEmpty ? nil : recipe.notes,
                category: recipe.category,
                isFavorite: recipe.isFavorite,
                imageURL: recipe.imageName?.hasPrefix("http") == true ? recipe.imageName : nil
            ),
            editingRecipeId: recipe.id,
            onComplete: { updatedRecipe in
                recipe = updatedRecipe
                PersistenceController.shared.saveRecipeModel(updatedRecipe)
                HapticManager.shared.success()
            }
        )
    }
    
    @ViewBuilder
    private var feedbackOverlay: some View {
        if let feedback = showAddedFeedback {
            HStack(spacing: AppTheme.spacing12) {
                Image(systemName: "basket.fill")
                    .adaptiveForegroundColor()
                Text("\(feedback) added to shopping list")
                    .font(.subheadline)
                    .adaptiveForegroundColor()
            }
            .padding(.horizontal, AppTheme.spacing20)
            .padding(.vertical, AppTheme.spacing12)
            .background(
                Capsule()
                    .fill(AppTheme.accentColor)
                    .shadow(color: .black.opacity(AppTheme.overlayLightOpacity), radius: 8, y: 4)
            )
            .padding(.bottom, AppTheme.spacing20)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .opacity(showAddedFeedback != nil ? 1 : 0)
        }
    }
    
    private func toggleSection(_ section: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if expandedSections.contains(section) {
                expandedSections.remove(section)
            } else {
                expandedSections.insert(section)
            }
        }
    }
    
    private func toggleMeasurementSystem() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            measurementSystem = measurementSystem == .metric ? .imperial : .metric
            HapticManager.shared.selection()
        }
    }
    
    private func decreaseServings() {
        if recipe.currentServings > 1 {
            HapticManager.shared.light()
            withAnimation(.spring(response: 0.3)) {
                recipe.currentServings -= 1
            }
        }
    }
    
    private func increaseServings() {
        HapticManager.shared.light()
        withAnimation(.spring(response: 0.3)) {
            recipe.currentServings += 1
        }
    }
    
    private func checkForCompletion(_ instructionsState: [Bool]) {
        let allIngredientsChecked = ingredientsState.allSatisfy({ $0 })
        let allPrePrepChecked = hasPrePrep ? prePrepState.allSatisfy({ $0 }) : true
        let allInstructionsChecked = instructionsState.allSatisfy({ $0 })
        
        if allIngredientsChecked && allPrePrepChecked && allInstructionsChecked {
            HapticManager.shared.success()
            confettiCounter += 1
        }
    }
    
    private func checkForCompletion() {
        checkForCompletion(instructionsState)
    }
    
    private func collapsibleSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        let isExpanded = expandedSections.contains(title)
        
        return VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Button(
                action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        if isExpanded {
                            expandedSections.remove(title)
                        } else {
                            expandedSections.insert(title)
                        }
                    }
                },
                label: {
                    HStack(spacing: AppTheme.spacing8) {
                        Image(systemName: icon)
                            .adaptiveForegroundColor()
                            .font(.title3)
                        Text(title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .adaptiveForegroundColor()
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.adaptiveHighEmphasis(for: colorScheme))
                            .rotationEffect(.degrees(isExpanded ? 0 : -90))
                            .animation(.spring(response: 0.3), value: isExpanded)
                    }
                    .padding(.top, AppTheme.spacing24)
                }
            )
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                GlassCard {
                    content()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppTheme.spacing24)
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: AppTheme.transitionScaleDown).combined(with: .opacity),
                    removal: .scale(scale: AppTheme.transitionScaleDown).combined(with: .opacity)
                ))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppTheme.spacing20)
    }
    
    private func instructionRow(text: String, isChecked: Bool, toggle: @escaping () -> Void) -> some View {
        Button(action: toggle, label: {
            HStack(alignment: .center, spacing: AppTheme.spacing12) {
                Text(text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .strikethrough(isChecked, color: .primary)
                    .opacity(isChecked ? 0.5 : 1.0)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: AppTheme.fontSize22))
                    .foregroundColor(isChecked ? .green : .gray.opacity(AppTheme.lowEmphasisOpacity))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        })
        .buttonStyle(.plain)
    }
    
    private func addIngredientToShoppingList(_ ingredient: Ingredient) {
        HapticManager.shared.light()
        
        let normalizedName = IngredientNormalizer.normalize(ingredient.name)
        
        ShoppingListManager.shared.addItem(name: normalizedName, quantity: 1, category: nil)
        
        addedIngredients.insert(ingredient.name)
        
        showAddedFeedback = normalizedName
        
        DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.animationDelayXLong) {
            withAnimation(.easeOut(duration: AppTheme.animationDuration08)) {
                showAddedFeedback = nil
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.animationDelayFeedback) {
            withAnimation {
                _ = addedIngredients.remove(ingredient.name)
            }
        }
    }
    
    private func isIngredientInShoppingList(_ ingredient: Ingredient) -> Bool {
        if addedIngredients.contains(ingredient.name) {
            return true
        }
        return false
    }
    
    private func startEditingIngredient(at index: Int) {
        HapticManager.shared.light()
        let ingredient = recipe.ingredients[index]
        editingQuantity = String(format: "%.2f", ingredient.baseQuantity)
        editingUnit = ingredient.unit
        editingIngredientIndex = index
    }
    
    private func saveIngredientEdit(at index: Int) {
        guard let quantity = Double(editingQuantity), quantity > 0 else {
            editingIngredientIndex = nil
            return
        }
        
        let updatedIngredient = recipe.ingredients[index]
        let newIngredient = Ingredient(
            id: updatedIngredient.id,
            baseQuantity: quantity,
            unit: editingUnit,
            name: updatedIngredient.name
        )
        
        recipe.ingredients[index] = newIngredient
        
        PersistenceController.shared.updateRecipe(recipe)
        
        editingIngredientIndex = nil
        HapticManager.shared.success()
    }
    
    private let cookingUnits: [(group: String, units: [String])] = [
        ("Volume – Metric",   ["ml", "cl", "dl", "l"]),
        ("Volume – Imperial", ["tsp", "tbsp", "fl oz", "cup", "pt", "qt", "gal"]),
        ("Weight – Metric",   ["g", "kg"]),
        ("Weight – Imperial", ["oz", "lb"]),
        ("Count & Other",     ["piece", "whole", "slice", "clove", "can", "jar",
                               "package", "bunch", "sprig", "leaf", "sheet",
                               "pinch", "dash", "drop", "handful"]),
    ]

    private var allUnits: [String] {
        cookingUnits.flatMap { $0.units }
    }

    private func groupLabel(for unit: String) -> String {
        cookingUnits.first { $0.units.contains(unit) }?.group ?? "Other"
    }

    private func ingredientEditSheet(for index: Int) -> some View {
        NavigationStack {
            Form {
                Section {
                    Text(recipe.ingredients[index].name)
                        .font(.headline)
                } header: {
                    Text("Ingredient")
                }

                Section {
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0", text: $editingQuantity)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: AppTheme.width80)
                    }

                    Picker("Unit", selection: $editingUnit) {
                        Text("none").tag("")
                        ForEach(cookingUnits, id: \.group) { group in
                            Section(group.group) {
                                ForEach(group.units, id: \.self) { unit in
                                    Text(unit).tag(unit)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Quantity")
                } footer: {
                    if !editingUnit.isEmpty {
                        Text("Group: \(groupLabel(for: editingUnit))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        editingIngredientIndex = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveIngredientEdit(at: index)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func toggleFavorite() {
        HapticManager.shared.light()
        recipe.isFavorite.toggle()
        
        PersistenceController.shared.toggleFavorite(withId: recipe.id)
        
        onFavoriteToggle?()
    }
}
