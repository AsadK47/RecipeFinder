import ConfettiSwiftUI
import StoreKit
import SwiftUI

struct RecipeDetailView: View {
    // State read by both `body` and the view-building content in
    // `RecipeDetailView+Content.swift`, so it is `internal` rather than `private`.
    @State var recipe: RecipeModel
    @State var ingredientsState: [Bool]
    @State var instructionsState: [Bool]
    @State var prePrepState: [Bool]
    @State var expandedSections: Set<String> = ["Ingredients", "Pre-Prep", "Instructions", "Notes", "Nutrition"]
    @State private var addedIngredients: Set<String> = []
    @State var showAddedFeedback: String?
    @State private var confettiCounter = 0
    @State private var showEditSheet = false
    @State private var showAddToCollection = false
    @State private var showCookingMode = false
    // Internal (not private) so the edit-completion handler in
    // RecipeDetailView+Content can set it on a failed save.
    @State var showSaveError = false
    // Internal (not private) so the timer control in RecipeDetailView+Content can drive it.
    @State var showTimerSheet = false
    @State var editingIngredientIndex: Int?
    @State var editingQuantity: String = ""
    @State var editingUnit: String = ""
    @State var substitutingIngredientIndex: Int?
    @State private var showPostCookPhotoPrompt = false
    // Internal so RecipeDetailView+Content can trigger and track the source refresh.
    @State var isRefreshing = false
    @State var pendingRefreshDiff: RecipeDiff?
    @State var showRefreshSheet = false
    @State var refreshErrorMessage: String?
    @State var showRefreshUpToDate = false
    // Nutrition card: false = per-serving (invariant), true = whole-recipe totals.
    @State var nutritionShowsWholeRecipe = false
    // Internal so the relocated timer control (RecipeDetailView+Content) can read it.
    @Environment(\.recipeTimer) var recipeTimer
    @AppStorage("measurementSystem") var measurementSystem: MeasurementSystem = .metric
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    @Environment(\.requestReview) private var requestReview

    var hasPrePrep: Bool { !recipe.prePrepInstructions.isEmpty }
    var hasNotes: Bool { !recipe.notesForDisplay.isEmpty || recipe.importedFromURL != nil }

    /// Called after any change that's been persisted to Core Data (favourite,
    /// cook count, rating, post-cook photo…) so the parent list can re-sync its
    /// in-memory copy — otherwise navigating away and back shows stale data.
    var onRecipeChange: (() -> Void)?

    init(recipe: RecipeModel, onRecipeChange: (() -> Void)? = nil) {
        _recipe = State(initialValue: recipe)
        self.onRecipeChange = onRecipeChange

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

                        if recipe.nutritionInfo != nil {
                            nutritionSection
                        }
                    }
                    .padding(.bottom, AppTheme.spacing100)
                    .frame(width: geometry.size.width)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Couldn't Save Changes", isPresented: $showSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your changes couldn't be saved. Please try again.")
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                RecipeDetailToolbar(
                    recipe: recipe,
                    onEdit: { showEditSheet = true },
                    onToggleFavorite: toggleFavorite,
                    onAddToCollection: { showAddToCollection = true },
                    onStartCooking: { showCookingMode = true },
                    onPrint: { RecipePrintFormatter.present(for: recipe) }
                )
            }
        }
        .sheet(isPresented: $showEditSheet) {
            editRecipeSheet
        }
        .sheet(isPresented: $showAddToCollection) {
            AddToCollectionSheet(recipe: recipe)
        }
        .sheet(isPresented: $showTimerSheet) {
            CookTimerView()
        }
        .sheet(isPresented: $showPostCookPhotoPrompt) {
            PostCookPhotoSheet { image in
                addCookPhoto(image)
            }
        }
        .sheet(isPresented: $showRefreshSheet) {
            if let diff = pendingRefreshDiff, let url = recipe.importedFromURL {
                RecipeRefreshSheet(diff: diff, sourceURL: url) { updated in
                    applyRefresh(updated)
                }
            }
        }
        .alert("Recipe Up to Date", isPresented: $showRefreshUpToDate) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your saved recipe already matches the source.")
        }
        .alert("Couldn't Refresh Recipe", isPresented: Binding(
            get: { refreshErrorMessage != nil },
            set: { if !$0 { refreshErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { refreshErrorMessage = nil }
        } message: {
            Text(refreshErrorMessage ?? "")
        }
        .fullScreenCover(isPresented: $showCookingMode) {
            CookingModeView(recipe: recipe, onFinish: recordCook)
        }
        .toast($showAddedFeedback)
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
        .task(id: recipe.id) {
            guard (recipe.imageName ?? "").isEmpty else { return }
            if let url = await UnsplashClient().fetchImageURL(for: recipe.name) {
                recipe.imageName = url.absoluteString
                PersistenceController.shared.updateRecipe(recipe)
            }
        }
        .task {
            await silentRefreshFromSource()
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

        showAddedFeedback = "\(normalizedName) added to Groceries"

        DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.animationDelayFeedback) {
            withAnimation {
                _ = addedIngredients.remove(ingredient.name)
            }
        }
    }

    func addAllIngredientsToShoppingList() {
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

        showAddedFeedback = "\(addedCount == 1 ? "1 ingredient" : "\(addedCount) ingredients") added to Groceries"

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

        let originalIngredient = recipe.ingredients[index]
        let newIngredient = Ingredient(
            id: originalIngredient.id,
            baseQuantity: quantity,
            unit: editingUnit,
            name: originalIngredient.name
        )

        recipe.ingredients[index] = newIngredient
        editingIngredientIndex = nil

        guard PersistenceController.shared.updateRecipe(recipe) else {
            // Persist failed — undo the in-memory edit and tell the user rather
            // than showing a change that won't survive relaunch.
            recipe.ingredients[index] = originalIngredient
            showSaveError = true
            return
        }

        HapticManager.shared.success()
    }

    private func toggleFavorite() {
        HapticManager.shared.light()
        recipe.isFavorite.toggle()

        PersistenceController.shared.toggleFavorite(withId: recipe.id)

        onRecipeChange?()
    }

    func recordCook() {
        HapticManager.shared.success()
        recipe.cookCount += 1
        recipe.lastCookedAt = Date()
        PersistenceController.shared.recordCook(withId: recipe.id)
        onRecipeChange?()
        // Third cook of any recipe = genuine fan; ask for a review exactly once.
        if recipe.cookCount == 3 { requestReview() }
        // Delay lets any active fullScreenCover (CookingModeView) dismiss before the sheet appears.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showPostCookPhotoPrompt = true
        }
    }

    private func addCookPhoto(_ image: UIImage) {
        let store = RecipeImageStore()
        let newPaths = store.persistGallery([image], recipeId: recipe.id, startingIndex: recipe.photoNames.count)
        guard !newPaths.isEmpty else { return }
        recipe.photoNames.append(contentsOf: newPaths)
        guard PersistenceController.shared.saveRecipeModel(recipe) else {
            recipe.photoNames.removeLast(newPaths.count)
            showSaveError = true
            return
        }
        HapticManager.shared.success()
        onRecipeChange?()
    }

    func updateRating(_ newRating: Int) {
        HapticManager.shared.selection()
        recipe.rating = newRating
        PersistenceController.shared.updateRating(withId: recipe.id, rating: newRating)
        onRecipeChange?()
    }

    /// Auto-triggered on every open; silently discards network errors so browsing
    /// isn't interrupted. Only shows the diff sheet when there are actual changes.
    func silentRefreshFromSource() async {
        guard let url = recipe.importedFromURL else { return }
        let importer = RecipeImporter()
        await importer.importRecipe(from: url)
        guard let data = importer.extractedData else { return }
        let upstream = RecipeImportBuilder().build(from: data)
        let diff = RecipeDiff.compute(stored: recipe, upstream: upstream)
        if diff.hasChanges {
            pendingRefreshDiff = diff
            showRefreshSheet = true
        }
    }

    func refreshFromSource() async {
        guard let url = recipe.importedFromURL else { return }
        isRefreshing = true
        refreshErrorMessage = nil

        let importer = RecipeImporter()
        await importer.importRecipe(from: url)

        isRefreshing = false

        if let data = importer.extractedData {
            let upstream = RecipeImportBuilder().build(from: data)
            let diff = RecipeDiff.compute(stored: recipe, upstream: upstream)
            if diff.hasChanges {
                pendingRefreshDiff = diff
                showRefreshSheet = true
            } else {
                showRefreshUpToDate = true
            }
        } else if let errorMsg = importer.errorMessage {
            refreshErrorMessage = errorMsg
        }
    }

    func applyRefresh(_ updated: RecipeModel) {
        let previous = recipe
        recipe = updated
        guard PersistenceController.shared.saveRecipeModel(updated) else {
            recipe = previous
            showSaveError = true
            return
        }
        HapticManager.shared.success()
    }
}
