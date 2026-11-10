import SwiftUI

private let logger = AppLogger.logger(category: "RecipeSearchView")

struct RecipeSearchView: View {
    @Environment(\.recipeStore) private var recipeStore
    /// Library from the store; reading it in a body re-renders that view on any write.
    private var recipes: [RecipeModel] { recipeStore.recipes }
    /// True while the library is still fetching on launch, so empty `recipes` shows a skeleton, not the empty state.
    var isLoading: Bool = false
    @State private var showCollections = false
    /// One-time tip for "+", which replaced the Import tab.
    @AppStorage("hasSeenAddRecipeTip") private var hasSeenAddRecipeTip = false
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
    @State private var sharedImportURL: SharedImportURL?
    @State private var sharedWizardPrefill: RecipeWizardView.PrefilledRecipeData?
    @State private var pendingOpenRecipeId: UUID?
    @State private var importToastMessage: String?
    @State private var recipeToDelete: RecipeModel?
    @State private var cachedFilteredRecipes: [RecipeModel] = []
    @State private var availableTags: [String] = []
    @State private var availableCuisines: [String] = []
    @State private var categories: [String] = []
    @FocusState private var isSearchFocused: Bool
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

    /// Opens the add-recipe sheet, presented by the app root so badge celebrations can wait for it to close.
    private let onAddRecipe: () -> Void

    init(isLoading: Bool = false, onAddRecipe: @escaping () -> Void = {}) {
        self.isLoading = isLoading
        self.onAddRecipe = onAddRecipe
        // Seed from the shared store (the env default) so the first frame isn't an empty-state flash.
        _cachedFilteredRecipes = State(initialValue: RecipeFilterCriteria().apply(to: RecipeStore.shared.recipes))
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            mainContentView
                .appNavigationChrome()
                .toolbar { keyboardToolbar }
                .modifier(SheetPresentationModifier(
                    showFilters: $showFilters,
                    filterSheet: filterSheet
                ))
                .recipeDeleteFlow(pending: $recipeToDelete)
                .sheet(item: $sharedImportURL) { shared in
                    RecipeImportView(initialURL: shared.url, existingNames: recipes.map { $0.name }) { importedRecipe in
                        addRecipe(importedRecipe, successMessage: "Imported \"\(importedRecipe.name)\"")
                    }
                }
                .sheet(item: $sharedWizardPrefill) { prefill in
                    RecipeWizardView(prefilledData: prefill) { newRecipe in
                        addRecipe(newRecipe, successMessage: "Added \"\(newRecipe.name)\"")
                    }
                }
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
        .onChange(of: recipes) { _, _ in
            updateDerivedMetadata()
            openPendingRecipeIfAvailable()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            checkSharedImportInbox()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openRecipe)) { notification in
            guard let idString = notification.userInfo?["recipeId"] as? String,
                  let recipeId = UUID(uuidString: idString) else { return }
            // Remember the target and open it now if loaded, else when `recipes` arrives — a deep link that
            // lands before the library finishes loading must not be silently dropped.
            pendingOpenRecipeId = recipeId
            openPendingRecipeIfAvailable()
        }
    }

    /// Navigates to a pending "OpenRecipe" deep link once its recipe is present in the loaded library; a no-op
    /// until then, so the request survives arriving before `recipes` loads instead of being dropped.
    private func openPendingRecipeIfAvailable() {
        guard let id = pendingOpenRecipeId, recipes.contains(where: { $0.id == id }) else { return }
        pendingOpenRecipeId = nil
        navigationPath = NavigationPath()
        navigationPath.append(id)
    }

    /// Handles the share-extension App Group inbox: finished recipe saved with a toast, URL opens the import sheet, text prefills the wizard.
    /// Finished recipes all save; only the first link/text opens a sheet (one sheet at a time) and the rest go
    /// back into the inbox for the next foreground.
    private func checkSharedImportInbox() {
        var openedInteractive = false
        for payload in SharedImportInbox.consumePayloads() {
            switch payload {
            case .extracted(let data):
                ingest(sharedRecipe: RecipeImportBuilder().build(from: data))
            case .url(let urlString) where !openedInteractive:
                openedInteractive = true
                sharedImportURL = SharedImportURL(url: urlString)
            case .text(let text) where !openedInteractive:
                openedInteractive = true
                Task { await importSharedText(text) }
            case .url(let urlString):
                SharedImportInbox.storeURL(urlString)
            case .text(let text):
                SharedImportInbox.storeText(text)
            }
        }
    }

    /// Routes shared free text into the wizard for review (AI results never saved silently); toasts when no recipe is found.
    private func importSharedText(_ text: String) async {
        if let prefill = await RecipeTextImportRouter().prefill(for: text) {
            sharedWizardPrefill = prefill
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

        // Don't silently save an unusable recipe — the interactive URL import already gates on this, so the
        // share-extension path must too rather than dropping a half-parsed page into the library.
        guard !recipe.ingredients.isEmpty, !recipe.instructions.isEmpty else {
            showImportToast("Couldn't read a full recipe from that share")
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
        withAnimation(.appGentle) {
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

    /// "Cook it again" nudge for a loved recipe gone cold — only on the plain browse home (no search/filter).
    /// Rendered as the first row of the results list so it scrolls away rather than pinning screen space.
    @ViewBuilder
    private var rediscoverySection: some View {
        if searchText.isEmpty, activeFilterCount == 0, let pick = RecipeRediscovery.pick(from: recipes) {
            RediscoveryCard(recipe: pick) {
                HapticManager.shared.light()
                navigationPath.append(pick.id)
            }
        }
    }

    private var collectionsSheet: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                CollectionsInlineView()
            }
            .appNavigationTitle("Collections")
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
            onShowStreak: { showCookingSheet = true },
            onAdd: {
                hasSeenAddRecipeTip = true
                onAddRecipe()
            },
            showsAddTip: !hasSeenAddRecipeTip,
            onDismissAddTip: { hasSeenAddRecipeTip = true }
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
                RecipeEmptyStateView(clearActionTitle: filterCriteria.clearActionTitle, onClearFilters: clearAllFilters)
            } else {
                RecipeResultsList(
                    filteredRecipes: current,
                    onRequestDelete: { recipeToDelete = $0 },
                    onRefresh: refreshRecipesAsync
                ) {
                    rediscoverySection
                }
            }
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
        AppBackground()
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
    
    // Identifiable wrapper so a shared import URL presents via `.sheet(item:)` — content rebuilds from the value
    // rather than reading a separately-set `@State`, which opened the import sheet with a nil URL on first run.
    private struct SharedImportURL: Identifiable {
        let id = UUID()
        let url: String
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
    
    
    
    private func clearAllFilters() {
        HapticManager.shared.medium()
        isSearchFocused = false
        withAnimation {
            searchText = ""
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
