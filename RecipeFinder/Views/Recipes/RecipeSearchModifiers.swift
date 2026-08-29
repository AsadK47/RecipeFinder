import SwiftUI

struct SheetPresentationModifier: ViewModifier {
    @Binding var showFilters: Bool
    @Binding var showImportSheet: Bool
    @Binding var showRecipeWizard: Bool
    @Binding var showDeleteAlert: Bool
    
    let filterSheet: AnyView
    let importSheet: AnyView
    let wizardSheet: AnyView
    let deleteSheet: AnyView
    
    init(showFilters: Binding<Bool>,
         showImportSheet: Binding<Bool>,
         showRecipeWizard: Binding<Bool>,
         showDeleteAlert: Binding<Bool>,
         filterSheet: some View,
         importSheet: some View,
         wizardSheet: some View,
         deleteSheet: some View) {
        self._showFilters = showFilters
        self._showImportSheet = showImportSheet
        self._showRecipeWizard = showRecipeWizard
        self._showDeleteAlert = showDeleteAlert
        self.filterSheet = AnyView(filterSheet)
        self.importSheet = AnyView(importSheet)
        self.wizardSheet = AnyView(wizardSheet)
        self.deleteSheet = AnyView(deleteSheet)
    }
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showFilters) {
                filterSheet
            }
            .sheet(isPresented: $showImportSheet) {
                importSheet
            }
            .sheet(isPresented: $showRecipeWizard) {
                wizardSheet
            }
            .sheet(isPresented: $showDeleteAlert) {
                deleteSheet
            }
    }
}

struct FilterCacheUpdateModifier: ViewModifier {
    let searchText: String
    let ingredientSearchText: String
    let availableIngredientsOnly: Bool
    let selectedCategories: Set<String>
    let selectedDifficulties: Set<String>
    let selectedCookTimes: Set<Int>
    let selectedDietaryFilters: Set<String>
    let selectedTags: Set<String>
    let showFavoritesOnly: Bool
    let recipes: [RecipeModel]
    let updateAction: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onChange(of: searchText) { _, _ in updateAction() }
            .onChange(of: ingredientSearchText) { _, _ in updateAction() }
            .onChange(of: availableIngredientsOnly) { _, _ in updateAction() }
            .onChange(of: selectedCategories) { _, _ in updateAction() }
            .onChange(of: selectedDifficulties) { _, _ in updateAction() }
            .onChange(of: selectedCookTimes) { _, _ in updateAction() }
            .onChange(of: selectedDietaryFilters) { _, _ in updateAction() }
            .onChange(of: selectedTags) { _, _ in updateAction() }
            .onChange(of: showFavoritesOnly) { _, _ in updateAction() }
            .onChange(of: recipes) { _, _ in updateAction() }
    }
}
