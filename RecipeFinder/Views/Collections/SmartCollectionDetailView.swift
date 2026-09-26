import SwiftUI

/// Read-only list of recipes matching a `SmartCollection` rule; mirrors `CollectionDetailView`.
struct SmartCollectionDetailView: View {
    let smartCollection: SmartCollection
    @Binding var recipes: [RecipeModel]

    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @Environment(\.colorScheme) var colorScheme

    private var matchingRecipes: [RecipeModel] {
        smartCollection.recipes(from: recipes)
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()

            if matchingRecipes.isEmpty {
                emptyState
            } else {
                recipeList
            }
        }
        .navigationTitle(smartCollection.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var recipeList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.cardVerticalSpacing) {
                ForEach(matchingRecipes) { recipe in
                    RecipeLink(recipe: recipe) {
                        RecipeRow(recipe: recipe)
                    }
                }
            }
            .padding(.horizontal, AppTheme.spacing16)
            .padding(.vertical, AppTheme.spacing12)
            .padding(.bottom, AppTheme.spacing100)
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: smartCollection.systemImage,
            iconTint: smartCollection.color,
            title: "No Recipes Yet",
            message: "Recipes matching \u{201c}\(smartCollection.name)\u{201d} will appear here as you add them."
        )
    }
}
