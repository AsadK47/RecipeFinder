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
    @State private var editingIngredientIndex: Int?
    @State private var editingQuantity: String = ""
    @State private var editingUnit: String = ""
    @AppStorage("measurementSystem") private var measurementSystem: MeasurementSystem = .metric
    @AppStorage("hasSeenServingEditWarning") private var hasSeenServingEditWarning: Bool = false
    @State private var showServingEditWarning = false
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    
    // Performance: Pre-compute expensive checks
    private let hasPrePrep: Bool
    private let hasNotes: Bool
    private let notesSentences: [Substring]
    
    // Callback to refresh recipes list when favorite is toggled
    var onFavoriteToggle: (() -> Void)?
    
    init(recipe: RecipeModel, onFavoriteToggle: (() -> Void)? = nil) {
        _recipe = State(initialValue: recipe)
        self.onFavoriteToggle = onFavoriteToggle
        
        // Pre-compute state arrays
        _ingredientsState = State(initialValue: Array(repeating: false, count: recipe.ingredients.count))
        _instructionsState = State(initialValue: Array(repeating: false, count: recipe.instructions.count))
        _prePrepState = State(initialValue: Array(repeating: false, count: recipe.prePrepInstructions.count))
        
        // Pre-compute expensive checks
        self.hasPrePrep = !recipe.prePrepInstructions.isEmpty
        self.hasNotes = !recipe.notes.isEmpty
        self.notesSentences = recipe.notes.split(separator: ".")
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundView
                
                ScrollView(.vertical, showsIndicators: true) {
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
                    .padding(.bottom, 100)
                    .frame(width: geometry.size.width)
                }
                .scrollBounceBehavior(.basedOnSize, axes: .vertical)
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
        .alert("💡 Tip: Edit Recipe Instead", isPresented: $showServingEditWarning) {
            Button("Got It!", role: .cancel) {
                HapticManager.shared.light()
            }
        } message: {
            Text("You're adjusting servings on-the-fly! This is fine for quick changes, but for permanent adjustments, consider editing the recipe itself. This way your changes are saved for next time. 👨‍🍳")
        }
        .overlay(alignment: .bottom) {
            feedbackOverlay
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showAddedFeedback)
        .confettiCannon(trigger: $confettiCounter, num: 50, radius: 500.0)
        .onChange(of: instructionsState) { _, newValue in
            checkForCompletion(newValue)
        }
    }
    
    // MARK: - View Components
    
    private var backgroundView: some View {
        AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
            .ignoresSafeArea()
    }
    
    private var recipeTitleView: some View {
        Text(recipe.name)
            .font(.system(size: 28, weight: .bold))
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 20)
    }
    
    private var recipeInfoCardsView: some View {
        VStack(spacing: 16) {
            timeInfoCard
            detailsInfoCard
            servingsCard
        }
        .padding(.horizontal, 20)
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
            HStack {
                servingsDisplay
                
                Divider()
                    .frame(height: 60)
                    .padding(.horizontal)
                
                servingsControls
            }
            .padding()
        }
    }
    
    private var servingsDisplay: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.2.fill")
                .font(.title2)
                .foregroundColor(.cyan)
            Text("Servings")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(recipe.currentServings)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var servingsControls: some View {
        HStack(spacing: 12) {
            servingsButton(icon: "minus", action: decreaseServings)
            servingsButton(icon: "plus", action: increaseServings)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func servingsButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Circle().fill(AppTheme.accentColor))
        }
    }
    
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ingredientsSectionHeader
            
            if expandedSections.contains("Ingredients") {
                ingredientsList
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }
    
    private var ingredientsSectionHeader: some View {
        HStack(spacing: 8) {
            Button(action: { toggleSection("Ingredients") }) {
                HStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .font(.title3)
                    Text("Ingredients")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            measurementToggle
            chevronButton(for: "Ingredients")
        }
        .padding(.top, 24)
    }
    
    private var measurementToggle: some View {
        Button(action: toggleMeasurementSystem) {
            HStack(spacing: 6) {
                Image(systemName: measurementSystem.icon)
                    .font(.caption)
                Text(measurementSystem.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func chevronButton(for section: String) -> some View {
        Button(action: { toggleSection(section) }) {
            Image(systemName: "chevron.down")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.6))
                .rotationEffect(.degrees(expandedSections.contains(section) ? 0 : -90))
                .animation(.spring(response: 0.3), value: expandedSections.contains(section))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var ingredientsList: some View {
        GlassCard {
            VStack(spacing: 16) {
                ForEach(recipe.ingredients.indices, id: \.self) { index in
                    IngredientRowView(
                        ingredient: recipe.ingredients[index],
                        isChecked: ingredientsState[index],
                        toggle: { 
                            HapticManager.shared.light()
                            ingredientsState[index].toggle()
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
            .padding(20)
        }
        .sheet(item: Binding(
            get: { editingIngredientIndex.map { EditingIngredient(index: $0) } },
            set: { editingIngredientIndex = $0?.index }
        )) { editingItem in
            ingredientEditSheet(for: editingItem.index)
        }
    }
    
    private struct EditingIngredient: Identifiable {
        let id = UUID()
        let index: Int
    }
    
    private var prePrepSection: some View {
        collapsibleSection(title: "Pre-Prep", icon: "list.clipboard") {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(recipe.prePrepInstructions.indices, id: \.self) { index in
                    instructionRow(
                        number: index + 1,
                        text: recipe.prePrepInstructions[index],
                        isChecked: prePrepState[index],
                        toggle: { 
                            HapticManager.shared.light()
                            prePrepState[index].toggle()
                        }
                    )
                }
            }
        }
    }
    
    private var instructionsSection: some View {
        collapsibleSection(title: "Instructions", icon: "text.alignleft") {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(recipe.instructions.indices, id: \.self) { index in
                    instructionRow(
                        number: index + 1,
                        text: recipe.instructions[index],
                        isChecked: instructionsState[index],
                        toggle: { 
                            HapticManager.shared.light()
                            instructionsState[index].toggle()
                        }
                    )
                }
            }
        }
    }
    
    private var notesSection: some View {
        collapsibleSection(title: "Notes", icon: "note.text") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(notesSentences, id: \.self) { sentence in
                    let trimmed = sentence.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundColor(.orange)
                                .padding(.top, 6)
                            Text(trimmed)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
    }
    
    private var toolbarButtons: some View {
        HStack(spacing: 16) {
            Button(action: { showEditSheet = true }) {
                Image(systemName: "pencil")
                    .font(.title3)
                    .foregroundColor(.white)
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
                ingredients: recipe.ingredients.map { "\($0.baseQuantity) \($0.unit) \($0.name)" },
                instructions: recipe.instructions,
                prepTime: TimeExtractor.extractMinutes(from: recipe.prepTime),
                cookTime: TimeExtractor.extractMinutes(from: recipe.cookingTime),
                servings: recipe.baseServings,
                difficulty: recipe.difficulty,
                notes: recipe.notes.isEmpty ? nil : recipe.notes,
                category: recipe.category,
                isFavorite: recipe.isFavorite
            ),
            autoFillMode: true,
            editingRecipeId: recipe.id,
            onComplete: { updatedRecipe in
                recipe = updatedRecipe
                // Update in Core Data
                PersistenceController.shared.saveRecipeModel(updatedRecipe)
                HapticManager.shared.success()
            }
        )
    }
    
    @ViewBuilder
    private var feedbackOverlay: some View {
        if let feedback = showAddedFeedback {
            HStack(spacing: 12) {
                Image(systemName: "basket.fill")
                    .foregroundColor(.white)
                Text("\(feedback) added to shopping list")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(AppTheme.accentColor)
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            )
            .padding(.bottom, 20)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .opacity(showAddedFeedback != nil ? 1 : 0)
        }
    }
    
    // MARK: - Helper Methods
    
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
            showWarningIfNeeded()
            HapticManager.shared.light()
            recipe.currentServings -= 1
        }
    }
    
    private func increaseServings() {
        showWarningIfNeeded()
        HapticManager.shared.light()
        recipe.currentServings += 1
    }
    
    private func checkForCompletion(_ newValue: [Bool]) {
        if !recipe.instructions.isEmpty && newValue.allSatisfy({ $0 }) {
            HapticManager.shared.success()
            confettiCounter += 1
        }
    }
    
    // MARK: - Collapsible Section
    
    private func collapsibleSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        let isExpanded = expandedSections.contains(title)
        
        return VStack(alignment: .leading, spacing: 12) {
            // Tappable header
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
                    HStack(spacing: 8) {
                        Image(systemName: icon)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .font(.title3)
                        Text(title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        Spacer()
                        
                        // Chevron indicator
                        Image(systemName: "chevron.down")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.6))
                            .rotationEffect(.degrees(isExpanded ? 0 : -90))
                            .animation(.spring(response: 0.3), value: isExpanded)
                    }
                    .padding(.top, 24)
                }
            )
            .buttonStyle(PlainButtonStyle())
            
            // Collapsible content
            if isExpanded {
                GlassCard {
                    content()
                        .frame(maxWidth: .infinity, alignment: .leading) // Force full width
                        .padding(20)
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                ))
            }
        }
        .frame(maxWidth: .infinity) // Ensure container fills width
        .padding(.horizontal, 20)
    }
    
    // MARK: - Instruction Row
    
    private func instructionRow(number: Int, text: String, isChecked: Bool, toggle: @escaping () -> Void) -> some View {
        Button(action: toggle, label: {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accentColor)
                        .frame(width: 32, height: 32)
                    
                    Text("\(number)")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .strikethrough(isChecked, color: .primary)
                    .opacity(isChecked ? 0.5 : 1.0)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isChecked ? .green : .gray.opacity(0.3))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        })
        .buttonStyle(.plain)
    }
    
    // MARK: - Shopping List Management
    
    private func addIngredientToShoppingList(_ ingredient: Ingredient) {
        // Haptic feedback
        HapticManager.shared.light()
        
        // Normalize ingredient name to USDA standard (e.g., "beef slices" -> "Beef Steak")
        let normalizedName = IngredientNormalizer.normalize(ingredient.name)
        
        // Add only the ingredient name (no measurements)
        ShoppingListManager.shared.addItem(name: normalizedName, quantity: 1, category: nil)
        
        // Mark as added immediately for UI update
        addedIngredients.insert(ingredient.name)
        
        // Show feedback with normalized name
        showAddedFeedback = normalizedName
        
        // Keep basket purple and start fading after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.8)) {
                showAddedFeedback = nil
            }
        }
        
        // Clear the added state after 2 seconds (basket returns to normal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                _ = addedIngredients.remove(ingredient.name)
            }
        }
    }
    
    private func isIngredientInShoppingList(_ ingredient: Ingredient) -> Bool {
        // Check if recently added (basket stays purple temporarily)
        if addedIngredients.contains(ingredient.name) {
            return true
        }
        // Don't check actual shopping list - let user add multiple times if needed
        return false
    }
    
    // MARK: - Ingredient Editing
    
    private func startEditingIngredient(at index: Int) {
        HapticManager.shared.light()
        let ingredient = recipe.ingredients[index]
        editingQuantity = String(format: "%.2f", ingredient.baseQuantity)
        editingUnit = ingredient.unit
        editingIngredientIndex = index
    }
    
    private func saveIngredientEdit(at index: Int) {
        guard let quantity = Double(editingQuantity), quantity > 0 else {
            // Invalid input - just close
            editingIngredientIndex = nil
            return
        }
        
        // Create updated ingredient
        var updatedIngredient = recipe.ingredients[index]
        // Since baseQuantity is let, we need to create a new Ingredient
        let newIngredient = Ingredient(
            id: updatedIngredient.id,
            baseQuantity: quantity,
            unit: editingUnit,
            name: updatedIngredient.name
        )
        
        // Update recipe
        recipe.ingredients[index] = newIngredient
        
        // Update in Core Data
        PersistenceController.shared.updateRecipe(recipe)
        
        // Close sheet
        editingIngredientIndex = nil
        HapticManager.shared.success()
    }
    
    private func ingredientEditSheet(for index: Int) -> some View {
        NavigationStack {
            Form {
                Section("Edit Quantity") {
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("Quantity", text: $editingQuantity)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Unit")
                        Spacer()
                        TextField("ml, g, cups, etc.", text: $editingUnit)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 150)
                    }
                }
                
                Section {
                    Text("Ingredient: \(recipe.ingredients[index].name)")
                        .foregroundColor(.secondary)
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
                }
            }
        }
    }
    
    // MARK: - Favorites
    
    private func toggleFavorite() {
        HapticManager.shared.light()
        recipe.isFavorite.toggle()
        
        // Update in Core Data
        PersistenceController.shared.toggleFavorite(withId: recipe.id)
        
        // Trigger callback if provided
        onFavoriteToggle?()
    }
    
    // Show one-time warning about editing servings
    private func showWarningIfNeeded() {
        if !hasSeenServingEditWarning {
            showServingEditWarning = true
            hasSeenServingEditWarning = true
        }
    }
}
