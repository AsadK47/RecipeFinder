import SwiftUI

// Recipes tab actions: share-extension imports, deep links, requests from other tabs and filter resets.
extension RecipeSearchView {
    /// Back to the list, showing every recipe of the requested cuisine (other filters cleared so none hides one).
    func applyBrowseRequest() {
        guard let request = browseRequest else { return }
        browseRequest = nil
        let criteria = request.criteria(keepingSort: filters.sortOrder)
        returnToRoot()
        selectedCollectionID = nil
        filters = criteria
    }

    /// Navigates to a pending "OpenRecipe" deep link once its recipe is present in the loaded library; a no-op
    /// until then, so the request survives arriving before `recipes` loads instead of being dropped.
    func openPendingRecipeIfAvailable() {
        guard let id = pendingOpenRecipeId, recipes.contains(where: { $0.id == id }) else { return }
        pendingOpenRecipeId = nil
        navigationPath = NavigationPath()
        navigationPath.append(id)
    }

    /// Handles the share-extension App Group inbox per `SharedImportPlan`: finished recipes saved with a toast, the
    /// first link opens the import sheet or the first text prefills the wizard, later ones wait for the next foreground.
    func checkSharedImportInbox() {
        let plan = SharedImportPlan(payloads: SharedImportInbox.consumePayloads())
        for data in plan.extracted {
            ingest(sharedRecipe: RecipeImportBuilder().build(from: data))
        }
        switch plan.interactive {
        case .url(let urlString): sharedImportURL = SharedImportURL(url: urlString)
        case .text(let text): Task { await importSharedText(text) }
        case nil: break
        }
        for share in plan.requeued {
            switch share {
            case .url(let urlString): SharedImportInbox.storeURL(urlString)
            case .text(let text): SharedImportInbox.storeText(text)
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
        switch SharedImportPlan.verdict(for: recipe, existingNames: recipes.map { $0.name }) {
        case .duplicate:
            showImportToast("\"\(recipe.name)\" is already in your recipes")
        case .incomplete:
            showImportToast("Couldn't read a full recipe from that share")
        case .add:
            addRecipe(recipe, successMessage: "Imported \"\(recipe.name)\"")
        }
    }

    /// Adds a new/imported recipe optimistically then persists; on save failure it rolls back and alerts rather than vanishing on relaunch.
    func addRecipe(_ recipe: RecipeModel, successMessage: String) {
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

    func updateDerivedMetadata() {
        facets = RecipeLibraryFacets(recipes: recipes)
    }

    /// Reads the kitchen here, not in `body`, so pantry toggles in a pushed detail don't re-render this list (as
    /// `availableIngredients`); the next appear picks them up.
    func updateDiscovery() {
        // Built only when shown: on My recipes the feed would be paid for on every appear and library change.
        guard browseMode == .discover else { return }
        recentlyCooked = DiscoveryPool.recentlyCooked(recipes)
        // Kept out of the first deal: the Recently cooked row above already shows these.
        discovery.update(
            recipes: recipes, kitchenItemNames: kitchen.items.map(\.name), alreadyShown: Set(recentlyCooked.map(\.id))
        )
    }

    /// Recomputes the displayed list only via `FilterCacheUpdateModifier` (debounced on criteria change, immediate on library change) + initial onAppear, so filter passes never run in `body`.
    func updateFilterCache() {
        cachedFilteredRecipes = filterCriteria.apply(to: recipes)
    }

    /// "Keep browsing →" from Today: back to the top of Recipes, nothing typed or filtered, on Discover.
    func showDiscover() {
        returnToRoot()
        resetFilters()
        browseMode = .discover
    }

    /// Closes this tab's sheets and pops everything pushed, for requests that arrive from another tab.
    private func returnToRoot() {
        isSearchFocused = false
        showCollections = false
        showFilters = false
        showCookingSheet = false
        // Rows push recipes with destination links, which aren't in `navigationPath`; a fresh stack pops them too.
        navigationPath = NavigationPath()
        stackID = UUID()
    }

    func clearAllFilters() {
        HapticManager.shared.medium()
        resetFilters()
    }

    private func resetFilters() {
        isSearchFocused = false
        withAnimation {
            filters = RecipeFilterCriteria()
            selectedCollectionID = nil
        }
    }

    /// Awaitable reload so pull-to-refresh keeps its spinner up until the fetch completes.
    func refreshRecipesAsync() async {
        await recipeStore.refresh()
    }
}
