import SwiftUI

// Split across files: chrome and sheets in `RecipeSearchView+Content.swift`, imports, browse requests and filter
// resets in `RecipeSearchView+Actions.swift`; state is internal (not private) only so those extensions can use it.
struct RecipeSearchView: View {
    @Environment(\.recipeStore) var recipeStore
    /// Library from the store; reading it in a body re-renders that view on any write.
    var recipes: [RecipeModel] { recipeStore.recipes }
    /// True while the library is still fetching on launch, so empty `recipes` shows a skeleton, not the empty state.
    var isLoading: Bool = false
    @State var showCollections = false
    /// One-time tip for "+", which replaced the Import tab.
    @AppStorage("hasSeenAddRecipeTip") var hasSeenAddRecipeTip = false
    @State var showFilters = false
    /// What the cook typed, picked and sorted. The kitchen and the chosen collection are added in `filterCriteria`.
    @State var filters = RecipeFilterCriteria()
    @State var sharedImportURL: SharedImportURL?
    @State var sharedWizardPrefill: RecipeWizardView.PrefilledRecipeData?
    @State var pendingOpenRecipeId: UUID?
    @State var importToastMessage: String?
    @State var recipeToDelete: RecipeModel?
    @State var cachedFilteredRecipes: [RecipeModel] = []
    /// The filter sheet's courses, tags and cuisines; rebuilt when the library changes, not in `body`.
    @State var facets = RecipeLibraryFacets()
    @FocusState var isSearchFocused: Bool
    @Environment(\.collections) var collectionManager
    @Environment(\.cookingStreak) var cookingStreak
    @Environment(\.kitchen) var kitchen
    /// Endless chapters below the library while browsing; rebuilt on library/kitchen change, paged as you scroll.
    @State var discovery = DiscoveryFeedModel()
    @State var recentlyCooked: [RecipeModel] = []
    /// Discover | My recipes; remembered, and set to Discover by Today's "Keep browsing →".
    @AppStorage(RecipeBrowse.modeKey) var browseMode: RecipeBrowse.Mode = RecipeBrowse.defaultMode
    @AppStorage(RecipeBrowse.discoverRequestKey) private var discoverRequests = 0
    @State var showCookingSheet = false
    @State var selectedCollectionID: UUID? = nil
    @State var navigationPath = NavigationPath()
    /// Changed to rebuild the stack at its root (see `applyBrowseRequest`).
    @State var stackID = UUID()
    // Refreshed on appear so RecipeDetailView pantry toggles don't re-render this buried view and re-run apply(to:) 3x per toggle.
    @State var availableIngredients: Set<String> = []

    /// Current filters as a plain value; filtering/sorting lives in `RecipeFilterCriteria` to stay out of `body` and be unit tested.
    var filterCriteria: RecipeFilterCriteria {
        var c = filters
        c.availableIngredients = availableIngredients
        c.selectedCollectionRecipeIDs = selectedCollectionID
            .flatMap { collectionManager.collection(withID: $0) }
            .map { Set($0.recipeIDs) }
        return c
    }

    var activeFilterCount: Int {
        filterCriteria.activeCount
    }

    /// Opens the add-recipe sheet, presented by the app root so badge celebrations can wait for it to close.
    let onAddRecipe: () -> Void
    /// "More <cuisine> recipes" from a recipe screen; held by the app root so it survives this tab not existing yet.
    @Binding var browseRequest: RecipeBrowseRequest?

    init(isLoading: Bool = false, browseRequest: Binding<RecipeBrowseRequest?> = .constant(nil),
         onAddRecipe: @escaping () -> Void = {}) {
        self.isLoading = isLoading
        self._browseRequest = browseRequest
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
                    AddRecipeImportFlow(source: .from(shared.url), existingNames: recipes.map { $0.name }) { importedRecipe in
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
        .id(stackID)
        .sheet(isPresented: $showCollections) { collectionsSheet }
        .sheet(isPresented: $showCookingSheet) { CookingSheet(streak: cookingStreak.streak) }
        .onAppear {
            availableIngredients = Set(KitchenInventoryManager.shared.items.map { $0.name.lowercased() })
            updateFilterCache()
            checkSharedImportInbox()
            updateDerivedMetadata()
            updateDiscovery()
            applyBrowseRequest()
        }
        .onChange(of: browseMode) { _, _ in updateDiscovery() }
        .onChange(of: discoverRequests) { _, _ in showDiscover() }
        .onChange(of: browseRequest) { _, _ in applyBrowseRequest() }
        .onChange(of: recipes) { _, _ in
            updateDerivedMetadata()
            updateDiscovery()
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

    private var mainContentView: some View {
        ZStack(alignment: .top) {
            AppBackground()
            allRecipesContent

            if let importToastMessage {
                RecipeImportToast(message: importToastMessage)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
    }

    private var allRecipesContent: some View {
        VStack(spacing: 0) {
            searchHeaderGroup
            if RecipeBrowse.showsModePicker(criteria: filterCriteria, libraryCount: recipes.count) {
                modePicker
            }
            activeFiltersSection
            recipeContentArea
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
                    discovery: content == .discover
                        ? RecipeResultsList.Discovery(recentlyCooked: recentlyCooked, feed: discovery)
                        : nil,
                    onRequestDelete: { recipeToDelete = $0 },
                    onRefresh: refreshRecipesAsync
                )
                // A fresh scroll per side, so switching never lands mid-list or mid-feed.
                .id(content)
            }
        }
    }

    private var content: RecipeBrowse.Content {
        RecipeBrowse.content(mode: browseMode, criteria: filterCriteria, libraryCount: recipes.count)
    }

    // Identifiable wrapper so a shared import URL presents via `.sheet(item:)` — content rebuilds from the value
    // rather than reading a separately-set `@State`, which opened the import sheet with a nil URL on first run.
    struct SharedImportURL: Identifiable {
        let id = UUID()
        let url: String
    }
}
