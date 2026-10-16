import SwiftUI

// Only genuinely boolean sheets live here. The share-import and wizard sheets are data-carrying and are presented
// directly via `.sheet(item:)` in RecipeSearchView, so their content rebuilds from the value (no stale first render).
struct SheetPresentationModifier: ViewModifier {
    @Binding var showFilters: Bool
    @Binding var showDeleteAlert: Bool

    let filterSheet: AnyView
    let deleteSheet: AnyView

    init(showFilters: Binding<Bool>,
         showDeleteAlert: Binding<Bool>,
         filterSheet: some View,
         deleteSheet: some View) {
        self._showFilters = showFilters
        self._showDeleteAlert = showDeleteAlert
        self.filterSheet = AnyView(filterSheet)
        self.deleteSheet = AnyView(deleteSheet)
    }

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showFilters) {
                filterSheet
            }
            .sheet(isPresented: $showDeleteAlert) {
                deleteSheet
            }
    }
}

struct FilterCacheUpdateModifier: ViewModifier {
    let filterCriteria: RecipeFilterCriteria
    let recipes: [RecipeModel]
    let updateAction: () -> Void

    func body(content: Content) -> some View {
        // Observe the whole criteria value (plus recipe list) instead of a hand-synced per-field list.
        content
            // Debounce criteria changes (~250 ms) so typing recomputes the list once the user pauses,
            // not on every keystroke. `.task(id:)` cancels the pending sleep when the criteria change
            // again, so only the final value after a pause runs `apply(to:)` over the whole library.
            .task(id: filterCriteria) {
                guard (try? await Task.sleep(for: .milliseconds(250))) != nil else { return }
                updateAction()
            }
            // Library load / add / delete must reflect immediately, not after the debounce.
            .onChange(of: recipes) { _, _ in updateAction() }
    }
}
