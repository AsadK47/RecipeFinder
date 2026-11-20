import ConfettiSwiftUI
import StoreKit
import SwiftUI

struct RecipeDetailView: View {
    // State is `internal` (not private) so RecipeDetailView+Content can read it.
    @State var recipe: RecipeModel
    // Cached displayable gallery images; recomputed only when the recipe changes.
    @State var galleryImageNames: [String]
    @State var ingredientTicks: IngredientTicks
    @State var instructionsState: [Bool]
    @State var prePrepState: [Bool]
    @State var expandedSections: Set<String> = ["Ingredients", "Pre-Prep", "Instructions", "Notes", "Nutrition"]
    @State var addedIngredients: Set<String> = []
    @State var showAddedFeedback: String?
    @State private var confettiCounter = 0
    @State private var showAddToCollection = false
    @State var showCookingMode = false
    private let startsCooking: Bool
    // One-shot: coming back to this screen later must not reopen cooking mode.
    @State private var didAutoStartCooking = false
    @State var shopSheetRecipe: RecipeModel?
    @State var saveError: String?
    static let saveErrorMessage = "Your changes couldn't be saved. Please try again."
    @State var showTimerSheet = false
    @State var substitutingIngredientIndex: Int?
    // The post-cook "Made it" sheet's shared state (see `MadeItPresenting`); this screen presents it.
    @Environment(\.madeItPresenter) var madeItPresenter
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
    @Environment(\.recipeStore) var recipeStore
    @Environment(\.cookingStreak) var cookingStreak
    @Environment(\.mealPlanning) var mealPlanning
    @AppStorage("measurementSystem") var measurementSystem: MeasurementSystem = .metric
    // Once the cook has ticked an ingredient, the first circle stops pulsing (it replaces the old hint text).
    @AppStorage("hasTickedIngredient") var hasTickedIngredient = false
    @AppStorage("ingredientPulseCount") var ingredientPulseCount = 0
    // Decided once per screen visit, so collapsing/expanding the section can't use up the pulse cap.
    @State var pulsesFirstIngredient = false
    @State private var didCountPulseVisit = false
    @Environment(\.requestReview) var requestReview
    @Environment(\.dismiss) private var dismiss

    var hasPrePrep: Bool { !recipe.prePrepInstructions.isEmpty }
    var hasNotes: Bool { !recipe.notesForDisplay.isEmpty || recipe.importedFromURL != nil }

    // Identifiable editor target; a nil section means the full (unfocused) editor. Stable `id` so `.sheet(item:)` treats "edit details" and "edit all" as distinct presentations.
    struct EditTarget: Identifiable {
        let section: RecipeWizardView.Section?
        var id: String { section.map(String.init(describing:)) ?? "__all__" }
    }

    /// `startsCooking` opens cooking mode as soon as the screen appears (Today's "Cook this").
    init(recipe: RecipeModel, startsCooking: Bool = false) {
        _recipe = State(initialValue: recipe)
        self.startsCooking = startsCooking
        _galleryImageNames = State(initialValue: RecipeDetailView.galleryNames(for: recipe))

        _ingredientTicks = State(initialValue: IngredientTicks(count: recipe.ingredients.count))
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
            ingredientTicks.remap(from: oldRecipe.ingredients, to: newRecipe.ingredients)
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
        .task(id: ingredientTicks.settleDeadline) {
            await settleIngredientTicks()
        }
        .onAppear {
            countPulseVisit()
            guard startsCooking, !didAutoStartCooking else { return }
            didAutoStartCooking = true
            showCookingMode = true
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

    /// Every ingredient, prep step and method step ticked. A recipe with no method steps never counts as
    /// complete here — otherwise ticking its ingredients would throw confetti beside "start cooking?".
    nonisolated static func isRecipeComplete(ingredients: [Bool], prePrep: [Bool], instructions: [Bool]) -> Bool {
        !instructions.isEmpty && ingredients.allSatisfy { $0 } && prePrep.allSatisfy { $0 }
            && instructions.allSatisfy { $0 }
    }

    private func checkForCompletion(_ instructionsState: [Bool]) {
        let complete = Self.isRecipeComplete(ingredients: ingredientTicks.ticked,
                                             prePrep: hasPrePrep ? prePrepState : [], instructions: instructionsState)
        if complete {
            HapticManager.shared.success()
            confettiCounter += 1
        }
    }

    /// Ticks an ingredient in place with one haptic; the row moves into "Got it" once tapping pauses.
    func toggleIngredient(_ index: Int) {
        guard ingredientTicks.ticked.indices.contains(index) else { return }
        ingredientTicks.toggle(index, at: .now)
        hasTickedIngredient = true
        let complete = Self.isRecipeComplete(ingredients: ingredientTicks.ticked,
                                             prePrep: hasPrePrep ? prePrepState : [], instructions: instructionsState)
        if complete {
            checkForCompletion()  // its success haptic + confetti stand in for the tick's
        } else if ingredientTicks.isAllSet {
            HapticManager.shared.success()
        } else {
            HapticManager.shared.light()
        }
    }

    private func settleIngredientTicks() async {
        guard let deadline = ingredientTicks.settleDeadline else { return }
        do {
            try await Task.sleep(until: deadline, clock: .continuous)
        } catch {
            return  // another tap moved the deadline; that task settles instead
        }
        withAnimation(.appSpring) { ingredientTicks.settleIfDue(at: .now) }
        if ingredientTicks.isAllSet {
            AccessibilityNotification.Announcement("All set — start cooking?").post()
        }
    }

    private func countPulseVisit() {
        guard !didCountPulseVisit else { return }
        didCountPulseVisit = true
        let index = IngredientChecklist.pulseIndex(count: recipe.ingredients.count,
                                                   hasTickedBefore: hasTickedIngredient,
                                                   timesPulsed: ingredientPulseCount)
        pulsesFirstIngredient = index != nil
        if pulsesFirstIngredient { ingredientPulseCount += 1 }
    }

    func checkForCompletion() {
        checkForCompletion(instructionsState)
    }

    private func toggleFavorite() {
        HapticManager.shared.light()
        recipe.isFavorite.toggle()

        PersistenceController.shared.toggleFavorite(withId: recipe.id)
        recipeStore.sync(recipe)
    }
}
