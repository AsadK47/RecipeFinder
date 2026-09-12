import SwiftUI

private let logger = AppLogger.logger(category: "RecipeSearchView")

struct RecipeSearchView: View {
    enum ViewMode: String, CaseIterable {
        case all = "Recipes"
        case collections = "Collections"
    }

    @Binding var recipes: [RecipeModel]
    @State private var viewMode: ViewMode = .all
    @State private var searchText = ""
    @State private var showFilters = false
    @State private var selectedCategories: Set<String> = []
    @State private var selectedDifficulties: Set<String> = []
    @State private var selectedCookTimes: Set<Int> = []
    @State private var selectedDietaryFilters: Set<String> = []
    @State private var selectedTags: Set<String> = []
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
    @State private var lastFilterHash: Int = 0
    @State private var hideSampleRecipes = false
    @FocusState private var isSearchFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @AppStorage("skipRecipeDeleteConfirmation") private var skipDeleteConfirmation: Bool = false
    @ObservedObject private var kitchenManager = KitchenInventoryManager.shared

    private var availableIngredients: Set<String> {
        Set(kitchenManager.items.map { $0.name.lowercased() })
    }

    private var filteredRecipes: [RecipeModel] {
        let currentHash = computeFilterHash()
        
        if currentHash == lastFilterHash && !cachedFilteredRecipes.isEmpty {
            return cachedFilteredRecipes
        }
        
        return filterCriteria.apply(to: recipes)
    }

    /// The current filters as a plain value; all filtering/sorting lives in
    /// `RecipeFilterCriteria` so it stays out of `body` and is unit tested.
    private var filterCriteria: RecipeFilterCriteria {
        RecipeFilterCriteria(
            searchText: searchText,
            ingredientSearchText: ingredientSearchText,
            availableIngredientsOnly: availableIngredientsOnly,
            showFavoritesOnly: showFavoritesOnly,
            selectedCategories: selectedCategories,
            selectedDifficulties: selectedDifficulties,
            selectedCookTimes: selectedCookTimes,
            selectedDietaryFilters: selectedDietaryFilters,
            selectedTags: selectedTags,
            availableIngredients: availableIngredients
        )
    }
    
    /// Cache key derived from the whole `RecipeFilterCriteria` value (which is
    /// `Hashable` and holds every filter, including the pantry) plus the recipe
    /// count. Hashing the value directly means a newly added filter can't be
    /// forgotten here the way a hand-maintained field list would.
    private func computeFilterHash() -> Int {
        var hasher = Hasher()
        hasher.combine(filterCriteria)
        hasher.combine(recipes.count)
        return hasher.finalize()
    }
    
    var activeFilterCount: Int {
        filterCriteria.activeCount
    }
    
    var availableTags: [String] {
        Array(Set(recipes.flatMap { $0.tags })).sorted()
    }
    
    var categories: [String] {
        let validCategories = ["Breakfast", "Dessert", "Drink", "Main", "Side", "Soup", "Starter"]
        return Array(Set(recipes.map { $0.category }))
            .filter { validCategories.contains($0) }
            .sorted()
    }
    
    var difficulties: [String] {
        ["Basic", "Expert", "Intermediate"]
    }

    var body: some View {
        NavigationStack {
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
        }
        .onAppear(perform: checkSharedImportInbox)
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
        recipes.append(recipe)

        guard PersistenceController.shared.saveRecipeModel(recipe) else {
            recipes.removeAll { $0.id == recipe.id }
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

            VStack(spacing: 0) {
                viewModeToggle

                switch viewMode {
                case .all:
                    allRecipesContent
                        .transition(.opacity)
                case .collections:
                    collectionsContent
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewMode)

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
                .foregroundColor(.green)

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
    
    private var viewModeToggle: some View {
        Picker("View", selection: $viewMode) {
            ForEach(ViewMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, AppTheme.spacing16)
        .padding(.top, AppTheme.spacing12)
        .padding(.bottom, AppTheme.spacing4)
    }

    private var allRecipesContent: some View {
        VStack(spacing: 0) {
            searchHeaderGroup
            activeFiltersSection
            recipeContentArea
        }
    }

    private var collectionsContent: some View {
        CollectionsInlineView(recipes: $recipes)
    }
    
    private var searchHeaderGroup: some View {
        RecipeSearchHeader(
            searchText: $searchText,
            isSearchFocused: $isSearchFocused,
            activeFilterCount: activeFilterCount,
            onToggleFilters: { showFilters.toggle() },
            onImport: { showImportSheet = true },
            onWizard: { showRecipeWizard = true }
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
                    onClearAll: clearAllFilters
                )
            }
        }
    }
    
    private var recipeContentArea: some View {
        Group {
            if filteredRecipes.filter({ !$0.isSampleRecipe }).isEmpty {
                RecipeEmptyStateView(activeFilterCount: activeFilterCount, onClearFilters: clearAllFilters)
            } else {
                RecipeResultsList(
                    filteredRecipes: filteredRecipes,
                    hideSampleRecipes: $hideSampleRecipes,
                    searchText: searchText,
                    activeFilterCount: activeFilterCount,
                    showFavoritesOnly: showFavoritesOnly,
                    onFavoriteToggle: refreshRecipes,
                    onRequestDelete: requestDelete
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
                    .foregroundColor(.gray)
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
            availableIngredients: availableIngredients,
            selectedCategories: $selectedCategories,
            selectedDifficulties: $selectedDifficulties,
            selectedCookTimes: $selectedCookTimes,
            selectedDietaryFilters: $selectedDietaryFilters,
            selectedTags: $selectedTags,
            ingredientSearchText: $ingredientSearchText,
            availableIngredientsOnly: $availableIngredientsOnly,
            showFavoritesOnly: $showFavoritesOnly
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
    
    private func updateFilterCache() {
        let newHash = computeFilterHash()
        if newHash != lastFilterHash {
            cachedFilteredRecipes = filteredRecipes
            lastFilterHash = newHash
        }
    }
    
    private func deleteRecipe(_ recipe: RecipeModel) {
        withAnimation {
            recipes.removeAll { $0.id == recipe.id }
        }
        PersistenceController.shared.deleteRecipe(withId: recipe.id)
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
            ingredientSearchText = ""
            availableIngredientsOnly = false
            showFavoritesOnly = false
        }
    }
    
    private func refreshRecipes() {
        guard PersistenceController.shared.hasCurrentUserScope() else {
            logger.debug("⚠️ Skipping recipe refresh because user scope is unavailable")
            return
        }

        recipes = PersistenceController.shared.fetchRecipes()
    }
}
