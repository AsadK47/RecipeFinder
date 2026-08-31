import ConfettiSwiftUI
import SwiftUI

struct RecipeDetailView: View {
    // State read by both `body` and the view-building content in
    // `RecipeDetailView+Content.swift`, so it is `internal` rather than `private`.
    @State var recipe: RecipeModel
    @State var ingredientsState: [Bool]
    @State var instructionsState: [Bool]
    @State var prePrepState: [Bool]
    @State var expandedSections: Set<String> = ["Ingredients", "Pre-Prep", "Instructions", "Notes"]
    @State private var addedIngredients: Set<String> = []
    @State var showAddedFeedback: String?
    @State private var confettiCounter = 0
    @State private var showEditSheet = false
    @State private var showTimerSheet = false
    @State var editingIngredientIndex: Int?
    @State var editingQuantity: String = ""
    @State var editingUnit: String = ""
    @StateObject private var recipeTimer = RecipeTimerManager.shared
    @AppStorage("measurementSystem") var measurementSystem: MeasurementSystem = .metric
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme

    var hasPrePrep: Bool { !recipe.prePrepInstructions.isEmpty }
    var hasNotes: Bool { !recipe.notes.isEmpty }

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

    func toggleSection(_ section: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if expandedSections.contains(section) {
                expandedSections.remove(section)
            } else {
                expandedSections.insert(section)
            }
        }
    }

    func toggleMeasurementSystem() {
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

    func checkForCompletion() {
        checkForCompletion(instructionsState)
    }

    func addIngredientToShoppingList(_ ingredient: Ingredient) {
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

    func isIngredientInShoppingList(_ ingredient: Ingredient) -> Bool {
        if addedIngredients.contains(ingredient.name) {
            return true
        }
        return false
    }

    func startEditingIngredient(at index: Int) {
        HapticManager.shared.light()
        let ingredient = recipe.ingredients[index]
        editingQuantity = String(format: "%.2f", ingredient.baseQuantity)
        editingUnit = ingredient.unit
        editingIngredientIndex = index
    }

    func saveIngredientEdit(at index: Int) {
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
