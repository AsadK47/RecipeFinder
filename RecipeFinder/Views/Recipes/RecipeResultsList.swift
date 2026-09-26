import SwiftUI

/// The scrollable results for the recipe search screen. Renders recipes as a
/// flat list — section labels and sample/user distinctions are not surfaced here.
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
