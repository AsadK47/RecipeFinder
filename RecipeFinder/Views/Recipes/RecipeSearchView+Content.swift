import SwiftUI

// Recipes tab chrome: header, Discover | My recipes picker, filter chips, sheets and the keyboard toolbar.
extension RecipeSearchView {
    var searchHeaderGroup: some View {
        RecipeSearchHeader(
            searchText: $filters.searchText,
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

    var modePicker: some View {
        Picker("Show", selection: $browseMode) {
            ForEach(RecipeBrowse.Mode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, AppTheme.cardHorizontalPadding)
        .padding(.bottom, AppTheme.spacing8)
        .accessibilityIdentifier("recipes.mode")
    }

    var activeFiltersSection: some View {
        Group {
            if activeFilterCount > 0 {
                ActiveFiltersBar(
                    showFavoritesOnly: $filters.showFavoritesOnly,
                    availableIngredientsOnly: $filters.availableIngredientsOnly,
                    ingredientSearchText: $filters.ingredientSearchText,
                    selectedCategories: $filters.selectedCategories,
                    selectedDifficulties: $filters.selectedDifficulties,
                    selectedCookTimes: $filters.selectedCookTimes,
                    selectedDietaryFilters: $filters.selectedDietaryFilters,
                    selectedTags: $filters.selectedTags,
                    selectedCuisines: $filters.selectedCuisines,
                    selectedCollectionID: $selectedCollectionID,
                    availableCollections: collectionManager.collections,
                    onClearAll: clearAllFilters
                )
            }
        }
    }

    var filterSheet: some View {
        FilterSheet(
            categories: facets.categories,
            difficulties: RecipeLibraryFacets.difficulties,
            availableTags: facets.tags,
            availableCuisines: facets.cuisines,
            availableIngredients: availableIngredients,
            availableCollections: collectionManager.collections,
            selectedCategories: $filters.selectedCategories,
            selectedDifficulties: $filters.selectedDifficulties,
            selectedCookTimes: $filters.selectedCookTimes,
            selectedDietaryFilters: $filters.selectedDietaryFilters,
            selectedTags: $filters.selectedTags,
            selectedCuisines: $filters.selectedCuisines,
            sortOrder: $filters.sortOrder,
            ingredientSearchText: $filters.ingredientSearchText,
            availableIngredientsOnly: $filters.availableIngredientsOnly,
            showFavoritesOnly: $filters.showFavoritesOnly,
            selectedCollectionID: $selectedCollectionID
        )
    }

    var collectionsSheet: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                CollectionsInlineView()
            }
            .appNavigationTitle("Collections")
        }
    }

    @ToolbarContentBuilder
    var keyboardToolbar: some ToolbarContent {
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
}

/// "Imported …" / "Couldn't …" capsule that slides in at the top of Recipes after a share or save.
struct RecipeImportToast: View {
    let message: String

    var body: some View {
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
}
