import SwiftUI

/// Scrollable search results as a flat list — no section labels or sample/user distinctions.
/// `header` scrolls with the list (e.g. the "Cook it again" card) instead of staying pinned above it.
struct RecipeResultsList<Header: View>: View {
    let filteredRecipes: [RecipeModel]
    let onRequestDelete: (RecipeModel) -> Void
    let onRefresh: () async -> Void
    @ViewBuilder let header: () -> Header

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.cardVerticalSpacing) {
                header()
                ForEach(filteredRecipes) { recipe in
                    navigationLink(for: recipe)
                }
            }
            .padding(.horizontal, AppTheme.cardHorizontalPadding)
            .padding(.bottom, AppTheme.cardHorizontalPadding)
        }
        .refreshable { await onRefresh() }
    }

    private func navigationLink(for recipe: RecipeModel) -> some View {
        RecipeLink(recipe: recipe) {
            RecipeCard(recipe: recipe, viewMode: .list)
        }
        .contextMenu {
            Button(role: .destructive) {
                onRequestDelete(recipe)
            } label: {
                Label("Delete Recipe", systemImage: "trash.fill")
            }
        }
    }
}
