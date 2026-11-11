import SwiftUI

/// Scrollable search results as a flat list — no section labels or sample/user distinctions.
struct RecipeResultsList: View {
    let filteredRecipes: [RecipeModel]
    let onRequestDelete: (RecipeModel) -> Void
    let onRefresh: () async -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.cardVerticalSpacing) {
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
