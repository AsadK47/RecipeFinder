import ConfettiSwiftUI
import StoreKit
import SwiftUI

struct RecipeDetailView: View {
    // State is `internal` (not private) so RecipeDetailView+Content can read it.
    @State var recipe: RecipeModel
    // Cached displayable gallery images; recomputed only when the recipe changes.
    @State var galleryImageNames: [String]
    @State var ingredientsState: [Bool]
    @State var instructionsState: [Bool]
    @State var prePrepState: [Bool]
    @State var expandedSections: Set<String> = ["Ingredients", "Pre-Prep", "Instructions", "Notes", "Nutrition"]
    @State private var addedIngredients: Set<String> = []
    @State var showAddedFeedback: String?
    @State private var confettiCounter = 0
    @State private var showAddToCollection = false
    @State var showCookingMode = false
    @State var shopSheetRecipe: RecipeModel?
    @State var saveError: String?
    static let saveErrorMessage = "Your changes couldn't be saved. Please try again."
    @State var showTimerSheet = false
    @State var substitutingIngredientIndex: Int?
    // The post-cook "Made it" sheet's shared state (see `MadeItPresenting`); this screen presents it.
    @Environment(\.madeItPresenter) private var madeItPresenter
    @State private var showPhotoManager = false
    @State var photoViewer: PhotoViewerSource?
    // Drives the editor sheet; `section` deep-links to those fields (nil = full editor). Presented via `.sheet(item:)` so content rebuilds from the target — avoids the stale-first-render race of `.sheet(isPresented:)` + separate state.
    @State var editTarget: EditTarget?
    @State var pendingRefreshDiff: RecipeDiff?
    @State var amountEstimateTarget: AmountEstimateTarget?
    let amountEstimator: IngredientAmountEstimating = makeIngredientAmountEstimator()
    @State private var pendingDelete: RecipeModel?
    // Nutrition card: false = per-serving, true = whole-recipe totals.
    @State var nutritionShowsWholeRecipe = false
    @Environment(\.recipeTimer) var recipeTimer
    @Environment(\.recipeStore) var recipeStore
    @Environment(\.cookingStreak) var cookingStreak
    @AppStorage("measurementSystem") var measurementSystem: MeasurementSystem = .metric
    @Environment(\.requestReview) private var requestReview
    @Environment(\.dismiss) private var dismiss

    var hasPrePrep: Bool { !recipe.prePrepInstructions.isEmpty }
    var hasNotes: Bool { !recipe.notesForDisplay.isEmpty || recipe.importedFromURL != nil }

    // Identifiable editor target; a nil section means the full (unfocused) editor. Stable `id` so `.sheet(item:)` treats "edit details" and "edit all" as distinct presentations.
    struct EditTarget: Identifiable {
        let section: RecipeWizardView.Section?
        var id: String { section.map(String.init(describing:)) ?? "__all__" }
    }

    init(recipe: RecipeModel) {
        _recipe = State(initialValue: recipe)
        _galleryImageNames = State(initialValue: RecipeDetailView.galleryNames(for: recipe))

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
                        primaryActionsRow
                        recipeInfoCardsView
                        ingredientsSection

                        if hasPrePrep {
                            prePrepSection
                        }

                        instructionsSection

                        if hasNotes {
                            notesSection
                        }

                        // Cook history + rating comes after the recipe content (you rate/log a cook
                        // once you've read the ingredients and instructions), but before nutrition.
                        cookHistoryCard
                            .padding(.horizontal, AppTheme.spacing20)
                            .padding(.top, AppTheme.spacing16)

                        if recipe.nutritionInfo != nil {
                            nutritionSection
                        }
                    }
                    .padding(.bottom, AppTheme.spacing100)
                    .frame(width: geometry.size.width)
                }

                NavigationBarScrollFade()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .errorAlert("Couldn't Save Changes", message: $saveError)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                RecipeDetailToolbar(
                    recipe: recipe,
                    onEdit: { beginEdit() },
                    onToggleFavorite: toggleFavorite,
                    onAddToCollection: { showAddToCollection = true },
                    onManagePhotos: { showPhotoManager = true },
                    onPrint: { RecipePrintFormatter.present(for: recipe) },
                    onReimport: recipe.canReimportFromOriginal ? { reimportFromOriginal() } : nil,
                    onDelete: { pendingDelete = recipe }
                )
            }
        }
        .recipeDeleteFlow(pending: $pendingDelete) { _ in dismiss() }
        .sheet(item: $editTarget) { target in
            editRecipeSheet(focus: target.section)
        }
        .sheet(item: $shopSheetRecipe) { shopRecipe in
            ShopIngredientsSheet(recipe: shopRecipe, measurementSystem: measurementSystem,
                                 onAdd: addIngredientsToShoppingList)
        }
        .sheet(isPresented: $showAddToCollection) {
            AddToCollectionSheet(recipe: recipe)
        }
        .sheet(isPresented: $showTimerSheet) {
            CookTimerView()
        }
        .sheet(isPresented: $showPhotoManager) {
            RecipePhotoManagerSheet(recipe: $recipe)
        }
        .sheet(item: $pendingRefreshDiff) { diff in
            RecipeRefreshSheet(diff: diff, sourceURL: recipe.importedFromURL) { updated in
                applyRefresh(updated)
            }
        }
        .sheet(item: Binding(
            get: { madeItPresenter.request(for: recipe.id) },
            set: { if $0 == nil { madeItPresenter.dismiss() } }
        ), onDismiss: { madeItPresenter.didDismiss() }) { request in
            MadeItSheet(summary: request.summary, onRate: request.onRate, onPhotoSelected: request.onPhotoSelected)
        }
        .fullScreenCover(isPresented: $showCookingMode, onDismiss: {
            // Present only once the cover is gone — a sheet can't present over a dismissing cover.
            madeItPresenter.presentHeld()
        }) {
            CookingModeView(recipe: recipe, onFinish: recordCook)
        }
        .toast($showAddedFeedback)
        .confettiCannon(trigger: $confettiCounter, num: AppTheme.confettiCount, radius: AppTheme.confettiRadius)
        .onChange(of: instructionsState) { _, newValue in
            checkForCompletion(newValue)
        }
        .onChange(of: recipe) { oldRecipe, newRecipe in
            galleryImageNames = RecipeDetailView.galleryNames(for: newRecipe)
            // Ticks follow their item, not their row: after an edit removes "Chicken", "Butter" stays ticked.
            ingredientsState = ChecklistState.remap(
                ingredientsState,
                from: oldRecipe.ingredients.map(ChecklistState.key),
                to: newRecipe.ingredients.map(ChecklistState.key)
            )
            instructionsState = ChecklistState.remap(
                instructionsState, from: oldRecipe.instructions, to: newRecipe.instructions
            )
            prePrepState = ChecklistState.remap(
                prePrepState, from: oldRecipe.prePrepInstructions, to: newRecipe.prePrepInstructions
            )
        }
        .onChange(of: recipeStore.recipes) { _, newRecipes in
            // Reflect edits made to this recipe elsewhere (favourite/cook/rating/edit on another screen, or the
            // list beside us in iPad split view). Guard on inequality so our own writes don't loop. Deletion is
            // left as-is — navigation owns dismissal.
            if let fresh = newRecipes.first(where: { $0.id == recipe.id }), fresh != recipe {
                recipe = fresh
            }
        }
        .task(id: recipe.id) {
            // Re-read the persisted copy first, then refresh — so the diff runs against saved state, not the stale navigation snapshot (avoids the two-task race).
            if let fresh = PersistenceController.shared.fetchRecipe(withId: recipe.id) {
                recipe = fresh
            }
            await silentRefreshFromSource()
        }
    }

    func toggleSection(_ section: String) {
        withAnimation(.appSpring) {
            if expandedSections.contains(section) {
                expandedSections.remove(section)
            } else {
                expandedSections.insert(section)
            }
        }
    }

    func toggleMeasurementSystem() {
        withAnimation(.appSpring) {
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

        guard let item = RecipeShoppingList.item(from: ingredient, scaleFactor: recipe.scaleFactor) else { return }

        ShoppingListManager.shared.addItem(name: item.name, quantity: item.quantity, unit: item.unit, category: nil)

        addedIngredients.insert(ingredient.name)

        showAddedFeedback = "\(item.name) added to Groceries"

        DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.animationDelayFeedback) {
            withAnimation {
                _ = addedIngredients.remove(ingredient.name)
            }
        }
    }

    /// Opens the pre-ticked "Add to Groceries" sheet (Shop button and the ingredients header's cart button).
    func addAllIngredientsToShoppingList() {
        guard !recipe.ingredients.isEmpty else { return }
        shopSheetRecipe = recipe
    }

    /// Adds the ingredients confirmed in the shop sheet.
    func addIngredientsToShoppingList(_ ingredients: [Ingredient]) {
        guard !ingredients.isEmpty else { return }

        HapticManager.shared.success()

        var addedCount = 0
        for ingredient in ingredients {
            guard let item = RecipeShoppingList.item(from: ingredient, scaleFactor: recipe.scaleFactor) else { continue }

            ShoppingListManager.shared.addItem(name: item.name, quantity: item.quantity, unit: item.unit, category: nil)
            addedIngredients.insert(ingredient.name)
            addedCount += 1
        }

        guard addedCount > 0 else { return }

        showAddedFeedback = "\(addedCount == 1 ? "1 ingredient" : "\(addedCount) ingredients") added to Groceries"

        DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.animationDelayFeedback) {
            withAnimation {
                ingredients.forEach { ingredient in
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

    private func toggleFavorite() {
        HapticManager.shared.light()
        recipe.isFavorite.toggle()

        PersistenceController.shared.toggleFavorite(withId: recipe.id)
        recipeStore.sync(recipe)
    }

    func recordCook() {
        // One cook a day: Made it is disabled once cooked today, and finishing cooking mode again mustn't add another.
        guard !recipe.wasCookedToday() else { return }
        recipe.cookCount += 1
        recipe.lastCookedAt = Date()
        Task { await PersistenceController.shared.recordCook(withId: recipe.id) }
        recipeStore.sync(recipe)

        // Cooking is the rewarded action — celebrate every cook, not just the week's first.
        confettiCounter += 1
        HapticManager.shared.celebrate()

        // Feed the weekly cooking-streak habit loop; the Made it sheet shows the resulting streak.
        _ = cookingStreak.recordCookToday()

        // Cooking is now the main path to badges: volume (10/25/50/100), streak, cuisines, and mastery all
        // key off this choke point.
        let totalCooks = refreshCookingBadges().recipesCooked
        // Third cook = genuine fan; ask for a review exactly once.
        if ReviewPrompt.shouldRequestReview(afterCookCount: recipe.cookCount) { requestReview() }

        // One celebratory sheet replaces the scattered toast / photo prompt / scroll-down rating.
        let summary = MadeItSummary(
            cookNumber: totalCooks,
            streakWeeks: cookingStreak.streak.currentWeeks,
            rating: recipe.rating,
            milestone: BadgeType.nextCookingMilestone(totalCooks: totalCooks)
        )
        let request = MadeItPresenter.Request(
            recipeId: recipe.id, summary: summary, onRate: updateRating, onPhotoSelected: addCookPhoto
        )
        if showCookingMode {
            madeItPresenter.hold(request)
        } else {
            madeItPresenter.present(request)
        }
    }

    private func addCookPhoto(_ image: UIImage) {
        let store = RecipeImageStore()
        let newPaths = store.persistGallery([image], recipeId: recipe.id)
        // Surface the failure (e.g. disk full) instead of dropping the photo.
        guard !newPaths.isEmpty else {
            saveError = Self.saveErrorMessage
            return
        }
        recipe.photoNames.append(contentsOf: newPaths)
        guard recipeStore.save(recipe) else {
            recipe.photoNames.removeLast(newPaths.count)
            saveError = Self.saveErrorMessage
            return
        }
        HapticManager.shared.success()
        refreshCookingBadges()   // first cook photo → "Food Stylist"
    }

    func updateRating(_ newRating: Int) {
        HapticManager.shared.selection()
        recipe.rating = newRating
        Task { await PersistenceController.shared.updateRating(withId: recipe.id, rating: newRating) }
        recipeStore.sync(recipe)
        refreshCookingBadges()   // rating 10 recipes → "Critic"
    }

    /// Re-evaluate cooking/collection badges from the current library + streak. Safe after any action that
    /// changes a metric (cook, cook photo, rating); unlocking is idempotent.
    @discardableResult
    private func refreshCookingBadges() -> BadgeMetrics {
        let metrics = BadgeMetrics.from(recipes: recipeStore.recipes, streakWeeks: cookingStreak.streak.currentWeeks)
        BadgeManager.shared.checkAndUnlockBadges(metrics: metrics)
        return metrics
    }

    // Auto-runs on open; discards network errors silently, shows diff sheet only on real changes.
    func silentRefreshFromSource() async {
        guard recipe.shouldAutoRefreshFromSource, let url = recipe.importedFromURL else { return }
        let importer = RecipeImporter()
        await importer.importRecipe(from: url)
        guard let data = importer.extractedData else { return }
        let upstream = RecipeImportBuilder().build(from: data)
        let diff = RecipeDiff.compute(stored: recipe, upstream: upstream)
        if diff.hasChanges {
            pendingRefreshDiff = diff
        }
    }

    /// Re-parses the saved original import text with today's parser and offers the per-field accept sheet.
    func reimportFromOriginal() {
        guard let text = recipe.sourceText else { return }
        Task {
            guard let prefill = await RecipeTextImportRouter().prefill(for: text) else {
                showAddedFeedback = "Couldn't read a recipe from the original text"
                return
            }
            let diff = RecipeDiff.reimport(stored: recipe, prefill: prefill)
            if diff.hasChanges {
                pendingRefreshDiff = diff
            } else {
                showAddedFeedback = "Already matches the original"
            }
        }
    }

    func beginAmountEstimate() {
        guard let request = AmountEstimateRequest(
            recipeName: recipe.name, servings: recipe.baseServings,
            ingredients: recipe.ingredients, steps: recipe.instructions
        ) else { return }
        HapticManager.shared.light()
        amountEstimateTarget = AmountEstimateTarget(request: request, ingredients: recipe.ingredients)
    }

    func applyEstimatedAmounts(_ ingredients: [Ingredient]) {
        var updated = recipe
        updated.ingredients = ingredients
        applyRefresh(updated)
    }

    func applyRefresh(_ updated: RecipeModel) {
        let previous = recipe
        recipe = updated
        guard recipeStore.save(updated) else {
            recipe = previous
            saveError = Self.saveErrorMessage
            return
        }
        HapticManager.shared.success()
    }
}
