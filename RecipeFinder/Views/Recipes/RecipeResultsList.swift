import SwiftUI

/// The scrollable results for the recipe search screen. Renders recipes as a
/// flat list — section labels and sample/user distinctions are not surfaced here.
struct RecipeResultsList: View {
    let filteredRecipes: [RecipeModel]
    let onFavoriteToggle: () -> Void
    let onRequestDelete: (RecipeModel) -> Void

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
    }

    private func navigationLink(for recipe: RecipeModel) -> some View {
        NavigationLink(
            destination: RecipeDetailView(
                recipe: recipe,
                onFavoriteToggle: onFavoriteToggle
            )
        ) {
            RecipeCard(recipe: recipe, viewMode: .list)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(role: .destructive) {
                onRequestDelete(recipe)
            } label: {
                Label("Delete Recipe", systemImage: "trash.fill")
            }
        }
    }
}
