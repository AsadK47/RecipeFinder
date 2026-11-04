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
    @State private var showCookingMode = false
    @State var showSaveError = false
    @State var showTimerSheet = false
    @State var substitutingIngredientIndex: Int?
    @State private var showPostCookPhotoPrompt = false
    @State private var showPhotoManager = false
    @State var photoViewer: PhotoViewerSource?
    // Drives the editor sheet; `section` deep-links to those fields (nil = full editor). Presented via `.sheet(item:)` so content rebuilds from the target — avoids the stale-first-render race of `.sheet(isPresented:)` + separate state.
    @State var editTarget: EditTarget?
    @State var pendingRefreshDiff: RecipeDiff?
    // Nutrition card: false = per-serving, true = whole-recipe totals.
    @State var nutritionShowsWholeRecipe = false
    @Environment(\.recipeTimer) var recipeTimer
    @Environment(\.recipeStore) var recipeStore
    @Environment(\.cookingStreak) var cookingStreak
    @AppStorage("measurementSystem") var measurementSystem: MeasurementSystem = .metric
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.requestReview) private var requestReview

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
                    onEdit: { beginEdit() },
                    onToggleFavorite: toggleFavorite,
                    onAddToCollection: { showAddToCollection = true },
                    onStartCooking: { showCookingMode = true },
                    onManagePhotos: { showPhotoManager = true },
                    onPrint: { RecipePrintFormatter.present(for: recipe) }
                )
            }
        }
        .sheet(item: $editTarget) { target in
            editRecipeSheet(focus: target.section)
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
        .sheet(isPresented: $showPhotoManager) {
            RecipePhotoManagerSheet(recipe: $recipe)
        }
        .sheet(item: $pendingRefreshDiff) { diff in
            if let url = recipe.importedFromURL {
                RecipeRefreshSheet(diff: diff, sourceURL: url) { updated in
                    applyRefresh(updated)
                }
            }
        }
        .fullScreenCover(isPresented: $showCookingMode) {
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

        guard let item = RecipeShoppingList.item(from: ingredient) else { return }

        ShoppingListManager.shared.addItem(name: item.name, quantity: item.quantity, unit: item.unit, category: nil)

        addedIngredients.insert(ingredient.name)

        showAddedFeedback = "\(item.name) added to Groceries"

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
            guard let item = RecipeShoppingList.item(from: ingredient) else { continue }

            ShoppingListManager.shared.addItem(name: item.name, quantity: item.quantity, unit: item.unit, category: nil)
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

    private func toggleFavorite() {
        HapticManager.shared.light()
        recipe.isFavorite.toggle()

        PersistenceController.shared.toggleFavorite(withId: recipe.id)
        recipeStore.sync(recipe)
    }

    func recordCook() {
        recipe.cookCount += 1
        recipe.lastCookedAt = Date()
        Task { await PersistenceController.shared.recordCook(withId: recipe.id) }
        recipeStore.sync(recipe)

        // Cooking is the rewarded action — celebrate every cook, not just the week's first.
        confettiCounter += 1
        HapticManager.shared.celebrate()

        // Feed the weekly cooking-streak habit loop; the toast is the milestone when this cook EXTENDS it.
        if cookingStreak.recordCookToday() {
            let weeks = cookingStreak.streak.currentWeeks
            showAddedFeedback = weeks <= 1 ? "🔥 Cooking streak started!" : "🔥 \(weeks)-week cooking streak!"
        }

        // Cooking is now the main path to badges: volume (10/25/50/100), streak, cuisines, and mastery all
        // key off this choke point.
        refreshCookingBadges()
        // Third cook = genuine fan; ask for a review exactly once.
        if ReviewPrompt.shouldRequestReview(afterCookCount: recipe.cookCount) { requestReview() }
        // Delay lets any active fullScreenCover dismiss before the sheet appears.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showPostCookPhotoPrompt = true
        }
    }

    private func addCookPhoto(_ image: UIImage) {
        let store = RecipeImageStore()
        let newPaths = store.persistGallery([image], recipeId: recipe.id, startingIndex: recipe.photoNames.count)
        // Surface the failure (e.g. disk full) instead of dropping the photo.
        guard !newPaths.isEmpty else {
            showSaveError = true
            return
        }
        recipe.photoNames.append(contentsOf: newPaths)
        guard recipeStore.save(recipe) else {
            recipe.photoNames.removeLast(newPaths.count)
            showSaveError = true
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
    private func refreshCookingBadges() {
        let metrics = BadgeMetrics.from(recipes: recipeStore.recipes, streakWeeks: cookingStreak.streak.currentWeeks)
        BadgeManager.shared.checkAndUnlockBadges(metrics: metrics)
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

    func applyRefresh(_ updated: RecipeModel) {
        let previous = recipe
        recipe = updated
        guard recipeStore.save(updated) else {
            recipe = previous
            showSaveError = true
            return
        }
        HapticManager.shared.success()
    }
}
