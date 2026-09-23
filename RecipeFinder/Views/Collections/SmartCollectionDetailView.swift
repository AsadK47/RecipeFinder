import SwiftUI

/// Read-only list of recipes matching a `SmartCollection` rule.
/// Mirrors the layout of `CollectionDetailView` without edit controls.
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
                    RecipeLink(recipe: recipe, onRecipeChange: refreshRecipes) {
                        RecipeRow(recipe: recipe)
                    }
                }
            }
            .padding(.horizontal, AppTheme.spacing16)
            .padding(.vertical, AppTheme.spacing12)
            .padding(.bottom, AppTheme.spacing100)
        }
    }

    /// Re-syncs the bound recipe array from Core Data after a change made on the
    /// detail screen so returning to this smart collection shows fresh data.
    private func refreshRecipes() {
        Task { recipes = await PersistenceController.shared.fetchRecipesAsync() }
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
