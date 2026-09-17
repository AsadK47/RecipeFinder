import SwiftUI

/// Read-only list of recipes matching a `SmartCollection` rule.
/// Mirrors the layout of `CollectionDetailView` without edit controls.
struct SmartCollectionDetailView: View {
    let smartCollection: SmartCollection
    let recipes: [RecipeModel]

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
                    NavigationLink {
                        RecipeDetailView(recipe: recipe)
                    } label: {
                        recipeRow(recipe)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppTheme.spacing16)
            .padding(.vertical, AppTheme.spacing12)
            .padding(.bottom, AppTheme.spacing100)
        }
    }

    private func recipeRow(_ recipe: RecipeModel) -> some View {
        HStack(spacing: AppTheme.spacing12) {
            RecipeImageView(
                imageName: recipe.imageName,
                height: Constants.Sizes.recipeImageSize,
                recipeName: recipe.name
            )
            .frame(width: Constants.Sizes.recipeImageSize, height: Constants.Sizes.recipeImageSize)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius8))

            VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                Text(recipe.name)
                    .font(.subheadline.weight(.semibold))
                    .adaptiveForegroundColor()
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: AppTheme.spacing6) {
                    if !recipe.category.isEmpty {
                        Text(recipe.category)
                            .font(.caption)
                            .adaptiveSecondaryForeground()
                    }
                    if !recipe.difficulty.isEmpty {
                        Text("·")
                            .font(.caption)
                            .adaptiveSecondaryForeground()
                        Text(recipe.difficulty)
                            .font(.caption)
                            .adaptiveSecondaryForeground()
                    }
                }
            }

            Spacer()
        }
        .padding(AppTheme.spacing12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius12))
    }

    private var emptyState: some View {
        VStack(spacing: AppTheme.spacing16) {
            Image(systemName: smartCollection.systemImage)
                .font(.system(size: AppTheme.fontSize50))
                .foregroundColor(smartCollection.color.opacity(0.5))

            Text("No Recipes Yet")
                .font(.title3.weight(.semibold))
                .adaptiveForegroundColor()

            Text("Recipes matching \u{201c}\(smartCollection.name)\u{201d} will appear here as you add them.")
                .font(.subheadline)
                .adaptiveSecondaryForeground()
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.spacing32)
        }
    }
}
