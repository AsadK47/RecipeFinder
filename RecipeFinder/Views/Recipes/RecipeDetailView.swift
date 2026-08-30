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
    @StateObject private var recipeTimer = RecipeTimerManager.shared
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
                RecipeDetailToolbar(
                    recipe: recipe,
                    recipeTimer: recipeTimer,
                    colorScheme: colorScheme,
                    onSetTimer: { showTimerSheet = true },
                    onEdit: { showEditSheet = true },
                    onAddAllToShopping: addAllIngredientsToShoppingList,
                    onToggleFavorite: toggleFavorite
                )
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
                    .padding(.top, AppTheme.spacing8)
            }

            Text(recipe.name)
                .font(.system(size: AppTheme.fontSize34, weight: .bold))
                .adaptiveForegroundColor()
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, recipe.imageName?.isEmpty == false ? 0 : AppTheme.spacing8)
                .padding(.bottom, AppTheme.spacing20)
        }
        .padding(.horizontal, AppTheme.spacing20)
    }

    private var recipeInfoCardsView: some View {
        VStack(spacing: AppTheme.spacing16) {
            timeInfoCard
            detailsInfoCard
            RecipeServingsCard(recipe: $recipe)
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

    private var ingredientsSection: some View {
        RecipeIngredientsSection(
            recipe: recipe,
            ingredientsState: ingredientsState,
            measurementSystem: measurementSystem,
            isExpanded: expandedSections.contains("Ingredients"),
            colorScheme: colorScheme,
            onToggleSection: { toggleSection("Ingredients") },
            onToggleMeasurement: toggleMeasurementSystem,
            onToggleIngredient: { index in
                HapticManager.shared.light()
                ingredientsState[index].toggle()
                checkForCompletion()
            },
            onAddToShopping: { index in
                addIngredientToShoppingList(recipe.ingredients[index])
            },
            isInShoppingList: { isIngredientInShoppingList($0) },
            onEditIngredient: { index in startEditingIngredient(at: index) }
        )
        .sheet(item: Binding(
            get: { editingIngredientIndex.map { EditingIngredient(index: $0) } },
            set: { editingIngredientIndex = $0?.index }
        )) { editingItem in
            IngredientEditSheet(
                ingredientName: recipe.ingredients[editingItem.index].name,
                editingQuantity: $editingQuantity,
                editingUnit: $editingUnit,
                onCancel: { editingIngredientIndex = nil },
                onSave: { saveIngredientEdit(at: editingItem.index) }
            )
        }
    }

    private struct EditingIngredient: Identifiable {
        let index: Int
        var id: Int { index }
    }

    private var prePrepSection: some View {
        RecipeChecklistSection(
            title: "Pre-Prep",
            icon: "list.clipboard",
            isExpanded: expandedSections.contains("Pre-Prep"),
            colorScheme: colorScheme,
            onToggle: { toggleSection("Pre-Prep") }
        ) {
            VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                ForEach(recipe.prePrepInstructions.indices, id: \.self) { index in
                    RecipeInstructionRow(
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
        RecipeChecklistSection(
            title: "Instructions",
            icon: "text.alignleft",
            isExpanded: expandedSections.contains("Instructions"),
            colorScheme: colorScheme,
            onToggle: { toggleSection("Instructions") }
        ) {
            VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                ForEach(recipe.instructions.indices, id: \.self) { index in
                    RecipeInstructionRow(
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
        RecipeChecklistSection(
            title: "Notes",
            icon: "note.text",
            isExpanded: expandedSections.contains("Notes"),
            colorScheme: colorScheme,
            onToggle: { toggleSection("Notes") }
        ) {
            Text(RecipeNotesFormatter.attributedString(from: recipe.notes))
                .font(.subheadline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var editRecipeSheet: some View {
        RecipeWizardView(
            prefilledData: RecipeWizardView.PrefilledRecipeData(
                name: recipe.name,
                description: nil,
                ingredients: recipe.ingredients.map { "\(String(format: "%g", $0.baseQuantity)) \($0.unit) \($0.name)" },
                instructions: recipe.instructions,
                prePrepInstructions: recipe.prePrepInstructions,
                prepTime: TimeExtractor.extractMinutes(from: recipe.prepTime),
                cookTime: TimeExtractor.extractMinutes(from: recipe.cookingTime),
                servings: recipe.baseServings,
                difficulty: recipe.difficulty,
                notes: recipe.notes.isEmpty ? nil : recipe.notes,
                category: recipe.category,
                isFavorite: recipe.isFavorite,
                imageURL: recipe.imageName
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

    private func addIngredientToShoppingList(_ ingredient: Ingredient) {
        HapticManager.shared.light()

        let normalizedName = IngredientNormalizer.normalize(ingredient.mainIngredientName)

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

    private func addAllIngredientsToShoppingList() {
        guard !recipe.ingredients.isEmpty else { return }

        HapticManager.shared.success()

        var addedCount = 0
        for ingredient in recipe.ingredients {
            let normalizedName = IngredientNormalizer.normalize(ingredient.mainIngredientName)
            guard !normalizedName.isEmpty else { continue }

            ShoppingListManager.shared.addItem(name: normalizedName, quantity: 1, category: nil)
            addedIngredients.insert(ingredient.name)
            addedCount += 1
        }

        guard addedCount > 0 else { return }

        showAddedFeedback = addedCount == 1 ? "1 ingredient" : "\(addedCount) ingredients"

        DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.animationDelayXLong) {
            withAnimation(.easeOut(duration: AppTheme.animationDuration08)) {
                showAddedFeedback = nil
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.animationDelayFeedback) {
            withAnimation {
                recipe.ingredients.forEach { ingredient in
                    _ = addedIngredients.remove(ingredient.name)
                }
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

    private func toggleFavorite() {
        HapticManager.shared.light()
        recipe.isFavorite.toggle()

        PersistenceController.shared.toggleFavorite(withId: recipe.id)

        onFavoriteToggle?()
    }
}
