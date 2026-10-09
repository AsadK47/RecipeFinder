import SwiftUI

private let logger = AppLogger.logger(category: "RecipeSearchView")

struct RecipeSearchView: View {
    @Environment(\.recipeStore) private var recipeStore
    /// Library from the store; reading it in a body re-renders that view on any write.
    private var recipes: [RecipeModel] { recipeStore.recipes }
    /// True while the library is still fetching post-sign-in, so empty `recipes` shows a skeleton, not the empty state.
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
    @Environment(\.cookingStreak) private var cookingStreak
    @State private var showCookingSheet = false
    @State private var selectedCollectionID: UUID? = nil
    @State private var navigationPath = NavigationPath()
    // Refreshed on appear so RecipeDetailView pantry toggles don't re-render this buried view and re-run apply(to:) 3x per toggle.
    @State private var availableIngredients: Set<String> = []

    /// Current filters as a plain value; filtering/sorting lives in `RecipeFilterCriteria` to stay out of `body` and be unit tested.
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

    init(isLoading: Bool = false) {
        self.isLoading = isLoading
        // Seed from the shared store (the env default) so the first frame isn't an empty-state flash.
        _cachedFilteredRecipes = State(initialValue: RecipeFilterCriteria().apply(to: RecipeStore.shared.recipes))
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
                        RecipeDetailView(recipe: recipe)
                    }
                }
        }
        .sheet(isPresented: $showCollections) { collectionsSheet }
        .sheet(isPresented: $showCookingSheet) { CookingSheet(streak: cookingStreak.streak) }
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

    /// Handles the share-extension App Group inbox: finished recipe saved with a toast, URL opens the import sheet, text prefills the wizard.
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

    /// Routes shared free text into the wizard for review (AI results never saved silently); toasts when no recipe is found.
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

    /// Adds a new/imported recipe optimistically then persists; on save failure it rolls back and alerts rather than vanishing on relaunch.
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
            rediscoverySection
            activeFiltersSection
            recipeContentArea
        }
    }

    /// "Cook it again" nudge for a loved recipe gone cold — only on the plain browse home (no search/filter).
    @ViewBuilder
    private var rediscoverySection: some View {
        if searchText.isEmpty, activeFilterCount == 0, let pick = RecipeRediscovery.pick(from: recipes) {
            RediscoveryCard(recipe: pick) {
                HapticManager.shared.light()
                navigationPath.append(pick.id)
            }
            .padding(.horizontal, AppTheme.spacing16)
            .padding(.bottom, AppTheme.spacing8)
        }
    }

    private var collectionsSheet: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                CollectionsInlineView()
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
            streak: recipes.isEmpty ? nil : cookingStreak.streak,
            onToggleFilters: { showFilters.toggle() },
            onShowCollections: { showCollections = true },
            onShowStreak: { showCookingSheet = true }
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
        // Read the maintained cache directly (no filtering/hashing in `body`); updateFilterCache() keeps it current via onChange + onAppear.
        let current = cachedFilteredRecipes
        return Group {
            if isLoading && recipes.isEmpty {
                RecipeListSkeleton()
            } else if current.isEmpty {
                RecipeEmptyStateView(activeFilterCount: activeFilterCount, onClearFilters: clearAllFilters)
            } else {
                RecipeResultsList(
                    filteredRecipes: current,
                    onRequestDelete: requestDelete,
                    onRefresh: refreshRecipesAsync
                )
            }
        }
    }

    /// Applies the delete preference: delete immediately when "don't ask again" is on, otherwise stage the recipe and confirm.
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

    /// Recomputes the displayed list only via `FilterCacheUpdateModifier` (debounced on criteria change, immediate on library change) + initial onAppear, so filter passes never run in `body`.
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
    
    /// Awaitable reload so pull-to-refresh keeps its spinner up until the fetch completes.
    private func refreshRecipesAsync() async {
        await recipeStore.refresh()
    }
}
