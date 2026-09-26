import SwiftUI

private let logger = AppLogger.logger(category: "RecipeSearchView")

struct RecipeSearchView: View {
    @Binding var recipes: [RecipeModel]
    @Environment(\.recipeStore) private var recipeStore
    /// True while the library is still being fetched after sign-in, so an empty
    /// `recipes` shows a loading skeleton instead of the "no recipes" empty state.
    var isLoading: Bool = false
    @State private var showCollections = false
    @State private var searchText = ""
    @State private var showFilters = false
    @State private var selectedCategories: Set<String> = []
    @State private var selectedDifficulties: Set<String> = []
    @State private var selectedCookTimes: Set<Int> = []
    @State private var selectedDietaryFilters: Set<String> = []
    @State private var selectedTags: Set<String> = []
    @State private var selectedCuisines: Set<String> = []
    @State private var sortOrder: SortOrder = .nameAZ
    @State private var ingredientSearchText = ""
    @State private var availableIngredientsOnly = false
    @State private var showFavoritesOnly = false
    @State private var showImportSheet = false
    @State private var sharedImportURL: String?
    @State private var sharedWizardPrefill: RecipeWizardView.PrefilledRecipeData?
    @State private var importToastMessage: String?
    @State private var showRecipeWizard: Bool = false
    @State private var recipeToDelete: RecipeModel?
    @State private var showDeleteAlert: Bool = false
    @State private var dontAskAgainDelete: Bool = false
    @State private var cachedFilteredRecipes: [RecipeModel] = []
    @State private var availableTags: [String] = []
    @State private var availableCuisines: [String] = []
    @State private var categories: [String] = []
    @FocusState private var isSearchFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @AppStorage("skipRecipeDeleteConfirmation") private var skipDeleteConfirmation: Bool = false
    @Environment(\.collections) private var collectionManager
    @State private var selectedCollectionID: UUID? = nil
    @State private var navigationPath = NavigationPath()
    // Refreshed on appear so pantry toggles in RecipeDetailView don't cause
    // this buried view to re-render and re-run apply(to:) 3 times per toggle.
    @State private var availableIngredients: Set<String> = []

    /// The current filters as a plain value; all filtering/sorting lives in
    /// `RecipeFilterCriteria` so it stays out of `body` and is unit tested.
    private var filterCriteria: RecipeFilterCriteria {
        var c = RecipeFilterCriteria()
        c.searchText = searchText
        c.ingredientSearchText = ingredientSearchText
        c.availableIngredientsOnly = availableIngredientsOnly
        c.showFavoritesOnly = showFavoritesOnly
        c.selectedCategories = selectedCategories
        c.selectedDifficulties = selectedDifficulties
        c.selectedCookTimes = selectedCookTimes
        c.selectedDietaryFilters = selectedDietaryFilters
        c.selectedTags = selectedTags
        c.selectedCuisines = selectedCuisines
        c.sortOrder = sortOrder
        c.availableIngredients = availableIngredients
        c.selectedCollectionRecipeIDs = selectedCollectionID
            .flatMap { collectionManager.collection(withID: $0) }
            .map { Set($0.recipeIDs) }
        return c
    }
    
    var activeFilterCount: Int {
        filterCriteria.activeCount
    }
    
    var difficulties: [String] {
        ["Basic", "Expert", "Intermediate"]
    }

    init(recipes: Binding<[RecipeModel]>, isLoading: Bool = false) {
        _recipes = recipes
        self.isLoading = isLoading
        // Seed the cache so the first frame renders the (unfiltered) library
        // rather than flashing the empty state before onAppear seeds it.
        _cachedFilteredRecipes = State(initialValue: RecipeFilterCriteria().apply(to: recipes.wrappedValue))
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            mainContentView
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbar { keyboardToolbar }
                .modifier(SheetPresentationModifier(
                    showFilters: $showFilters,
                    showImportSheet: $showImportSheet,
                    showRecipeWizard: $showRecipeWizard,
                    showDeleteAlert: $showDeleteAlert,
                    filterSheet: filterSheet,
                    importSheet: recipeImportSheet,
                    wizardSheet: recipeWizardSheet,
                    deleteSheet: deleteConfirmationSheet
                ))
                .modifier(FilterCacheUpdateModifier(
                    filterCriteria: filterCriteria,
                    recipes: recipes,
                    updateAction: updateFilterCache
                ))
                .navigationDestination(for: UUID.self) { recipeId in
                    if let recipe = recipes.first(where: { $0.id == recipeId }) {
                        RecipeDetailView(recipe: recipe, onRecipeChange: refreshRecipes)
                    }
                }
        }
        .sheet(isPresented: $showCollections) { collectionsSheet }
        .onAppear {
            availableIngredients = Set(KitchenInventoryManager.shared.items.map { $0.name.lowercased() })
            updateFilterCache()
            checkSharedImportInbox()
            updateDerivedMetadata()
        }
        .onChange(of: recipes) { _, _ in updateDerivedMetadata() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            checkSharedImportInbox()
        }
        .onChange(of: showImportSheet) { _, isPresented in
            if !isPresented {
                sharedImportURL = nil
            }
        }
        .onChange(of: showRecipeWizard) { _, isPresented in
            if !isPresented {
                sharedWizardPrefill = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenRecipe"))) { notification in
            guard let idString = notification.userInfo?["recipeId"] as? String,
                  let recipeId = UUID(uuidString: idString),
                  recipes.contains(where: { $0.id == recipeId }) else { return }
            navigationPath = NavigationPath()
            navigationPath.append(recipeId)
        }
    }

    /// Handles whatever the share extension left in the App Group inbox: a
    /// finished recipe is saved silently with a toast, a URL opens the
    /// interactive import sheet, and plain text is parsed into a prefilled
    /// wizard for review.
    private func checkSharedImportInbox() {
        switch SharedImportInbox.consumePayload() {
        case .extracted(let data):
            ingest(sharedRecipe: RecipeImportBuilder().build(from: data))
        case .url(let urlString):
            sharedImportURL = urlString
            showImportSheet = true
        case .text(let text):
            Task { await importSharedText(text) }
        case nil:
            break
        }
    }

    /// Routes shared free text into the wizard for review — AI results are never
    /// saved silently. Shows a toast when no recipe can be found.
    private func importSharedText(_ text: String) async {
        if let prefill = await RecipeTextImportRouter().prefill(for: text) {
            sharedWizardPrefill = prefill
            showRecipeWizard = true
        } else {
            showImportToast("Couldn't find a recipe in the shared text")
        }
    }

    private func ingest(sharedRecipe recipe: RecipeModel) {
        let normalizedName = recipe.name.trimmingCharacters(in: .whitespaces).lowercased()
        let isDuplicate = recipes.contains {
            $0.name.trimmingCharacters(in: .whitespaces).lowercased() == normalizedName
        }

        guard !isDuplicate else {
            showImportToast("\"\(recipe.name)\" is already in your recipes")
            return
        }

        addRecipe(recipe, successMessage: "Imported \"\(recipe.name)\"")
    }

    /// Adds a newly created/imported recipe: optimistically shows it, then
    /// persists. If the save fails, the optimistic insertion is rolled back and
    /// the user is told — rather than the recipe silently vanishing on relaunch.
    private func addRecipe(_ recipe: RecipeModel, successMessage: String) {
        guard recipeStore.add(recipe) else {
            showImportToast("Couldn't save \"\(recipe.name)\". Please try again.")
            return
        }

        HapticManager.shared.success()
        showImportToast(successMessage)
    }

    private func showImportToast(_ message: String) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            importToastMessage = message
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeOut(duration: AppTheme.animationDuration08)) {
                importToastMessage = nil
            }
        }
    }
    
    private var mainContentView: some View {
        ZStack(alignment: .top) {
            backgroundView
            allRecipesContent

            if let importToastMessage {
                importToast(message: importToastMessage)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
    }

    private func importToast(message: String) -> some View {
        HStack(spacing: AppTheme.spacing8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)

            Text(message)
                .font(.subheadline)
                .adaptiveForegroundColor()
                .lineLimit(2)
        }
        .padding(.horizontal, AppTheme.spacing16)
        .padding(.vertical, AppTheme.spacing12)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
        .padding(.top, AppTheme.spacing8)
        .padding(.horizontal, AppTheme.spacing20)
        .accessibilityElement(children: .combine)
    }
    
    private var allRecipesContent: some View {
        VStack(spacing: 0) {
            searchHeaderGroup
            activeFiltersSection
            recipeContentArea
        }
    }

    private var collectionsSheet: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                CollectionsInlineView(recipes: $recipes)
            }
            .navigationTitle("Collections")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    private var searchHeaderGroup: some View {
        RecipeSearchHeader(
            searchText: $searchText,
            isSearchFocused: $isSearchFocused,
            activeFilterCount: activeFilterCount,
            onToggleFilters: { showFilters.toggle() },
            onShowCollections: { showCollections = true }
        )
    }
    
    private var activeFiltersSection: some View {
        Group {
            if activeFilterCount > 0 {
                ActiveFiltersBar(
                    showFavoritesOnly: $showFavoritesOnly,
                    availableIngredientsOnly: $availableIngredientsOnly,
                    ingredientSearchText: $ingredientSearchText,
                    selectedCategories: $selectedCategories,
                    selectedDifficulties: $selectedDifficulties,
                    selectedCookTimes: $selectedCookTimes,
                    selectedDietaryFilters: $selectedDietaryFilters,
                    selectedTags: $selectedTags,
                    selectedCuisines: $selectedCuisines,
                    selectedCollectionID: $selectedCollectionID,
                    availableCollections: collectionManager.collections,
                    onClearAll: clearAllFilters
                )
            }
        }
    }
    
    private var recipeContentArea: some View {
        // Read the maintained cache directly — no filtering/hashing in `body`.
        // `updateFilterCache()` keeps it current via onChange + onAppear.
        let current = cachedFilteredRecipes
        return Group {
            if isLoading && recipes.isEmpty {
                RecipeListSkeleton()
            } else if current.isEmpty {
                RecipeEmptyStateView(activeFilterCount: activeFilterCount, onClearFilters: clearAllFilters)
            } else {
                RecipeResultsList(
                    filteredRecipes: current,
                    onRecipeChange: refreshRecipes,
                    onRequestDelete: requestDelete,
                    onRefresh: refreshRecipesAsync
                )
            }
        }
    }

    /// Applies the user's delete preference: skip straight to deletion when the
    /// "don't ask again" setting is on, otherwise stage the recipe and confirm.
    private func requestDelete(_ recipe: RecipeModel) {
        recipeToDelete = recipe
        if skipDeleteConfirmation {
            deleteRecipe(recipe)
            recipeToDelete = nil
        } else {
            showDeleteAlert = true
            HapticManager.shared.warning()
        }
    }
    
    @ToolbarContentBuilder
    private var keyboardToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button {
                isSearchFocused = false
            } label: {
                Image(systemName: "keyboard.chevron.compact.down")
                    .adaptiveSecondaryForeground()
            }
        }
    }
    
    private var backgroundView: some View {
        AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
            .ignoresSafeArea()
    }
    
    
    
    
    private var filterSheet: some View {
        FilterSheet(
            categories: categories,
            difficulties: difficulties,
            availableTags: availableTags,
            availableCuisines: availableCuisines,
            availableIngredients: availableIngredients,
            availableCollections: collectionManager.collections,
            selectedCategories: $selectedCategories,
            selectedDifficulties: $selectedDifficulties,
            selectedCookTimes: $selectedCookTimes,
            selectedDietaryFilters: $selectedDietaryFilters,
            selectedTags: $selectedTags,
            selectedCuisines: $selectedCuisines,
            sortOrder: $sortOrder,
            ingredientSearchText: $ingredientSearchText,
            availableIngredientsOnly: $availableIngredientsOnly,
            showFavoritesOnly: $showFavoritesOnly,
            selectedCollectionID: $selectedCollectionID
        )
    }
    
    private var recipeImportSheet: some View {
        RecipeImportView(initialURL: sharedImportURL, existingNames: recipes.map { $0.name }) { importedRecipe in
            addRecipe(importedRecipe, successMessage: "Imported \"\(importedRecipe.name)\"")
        }
    }

    private var recipeWizardSheet: some View {
        RecipeWizardView(prefilledData: sharedWizardPrefill) { newRecipe in
            addRecipe(newRecipe, successMessage: "Added \"\(newRecipe.name)\"")
        }
    }
    
    private var deleteConfirmationSheet: some View {
        RecipeDeleteConfirmationSheet(
            recipeName: recipeToDelete?.name ?? "",
            dontAskAgain: $dontAskAgainDelete,
            onConfirm: {
                if dontAskAgainDelete {
                    skipDeleteConfirmation = true
                }
                if let recipe = recipeToDelete {
                    deleteRecipe(recipe)
                }
                recipeToDelete = nil
                dontAskAgainDelete = false
                showDeleteAlert = false
            },
            onCancel: {
                recipeToDelete = nil
                dontAskAgainDelete = false
                showDeleteAlert = false
            }
        )
    }
    
    private func updateDerivedMetadata() {
        let validCategories = Set(["Breakfast", "Dessert", "Drink", "Main", "Side", "Soup", "Starter"])
        availableTags = Array(Set(recipes.flatMap { $0.tags })).sorted()
        availableCuisines = Array(Set(recipes.compactMap { $0.cuisine })).sorted()
        categories = Array(Set(recipes.map { $0.category }).intersection(validCategories)).sorted()
    }

    /// Recomputes the displayed list. Driven only by `FilterCacheUpdateModifier`'s
    /// `onChange` (fires on a real filter/recipes change) + the initial `onAppear`,
    /// so the ~10 filter passes never run inside `body`.
    private func updateFilterCache() {
        cachedFilteredRecipes = filterCriteria.apply(to: recipes)
    }
    
    private func deleteRecipe(_ recipe: RecipeModel) {
        withAnimation {
            recipeStore.delete(id: recipe.id)
        }
        HapticManager.shared.success()
    }
    
    
    private func clearAllFilters() {
        HapticManager.shared.medium()
        withAnimation {
            selectedCategories.removeAll()
            selectedDifficulties.removeAll()
            selectedCookTimes.removeAll()
            selectedDietaryFilters.removeAll()
            selectedTags.removeAll()
            selectedCuisines.removeAll()
            ingredientSearchText = ""
            availableIngredientsOnly = false
            showFavoritesOnly = false
            sortOrder = .nameAZ
            selectedCollectionID = nil
        }
    }
    
    private func refreshRecipes() {
        Task { await refreshRecipesAsync() }
    }

    /// Awaitable reload so pull-to-refresh keeps its spinner up until the fetch
    /// completes. `refreshRecipes` wraps this for the fire-and-forget callers.
    private func refreshRecipesAsync() async {
        await recipeStore.refresh()
    }
}
