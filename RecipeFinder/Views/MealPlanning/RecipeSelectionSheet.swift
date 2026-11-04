import SwiftUI
import Kingfisher

struct RecipeSelectionSheet: View {
    @Environment(\.recipeStore) private var recipeStore
    private var recipes: [RecipeModel] { recipeStore.recipes }
    let mealTime: MealTime?
    let onSelectExisting: (RecipeModel) -> Void

    @State private var searchText = ""
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted

    var filteredRecipes: [RecipeModel] {
        if searchText.isEmpty {
            return recipes
        }
        return recipes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: AppTheme.spacing12) {
            SearchBar(text: $searchText, placeholder: "Search Recipes...")
                .padding(.horizontal)

            if filteredRecipes.isEmpty {
                Spacer()
                EmptyStateView(
                    icon: "book.closed",
                    title: "No recipes found",
                    message: "Try a different search, or add a recipe to your library."
                )
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: AppTheme.spacing12) {
                        ForEach(filteredRecipes) { recipe in
                            Button(action: {
                                onSelectExisting(recipe)
                                HapticManager.shared.light()
                            }) {
                                MealPickerRecipeCard(recipe: recipe)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, AppTheme.spacing100)
                }
            }
        }
        .padding(.top, AppTheme.spacing8)
        .sheetDismissButton("Cancel", placement: .cancellationAction)
        .sheetScaffold(mealTime.map { "Add to \($0.rawValue)" } ?? "Add Recipe")
    }
}

/// Photo-forward meal-planner picker card: image fills the card, name overlays the bottom with a scrim, no separate background/border.
private struct MealPickerRecipeCard: View {
    let recipe: RecipeModel

    @State private var loadFailed = false

    // Shared resolver: handles http/legacy-absolute/relative paths and versions the cache key so a replaced photo never serves stale.
    private var kfSource: Source? {
        RecipeImageView.resolvedSource(for: recipe.imageName)
    }

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay { photoContent }
            .overlay(alignment: .bottom) { nameOverlay }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius12))
    }

    @ViewBuilder
    private var photoContent: some View {
        if let source = kfSource, !loadFailed {
            KFImage(source: source)
                .onFailure { _ in loadFailed = true }
                .resizable()
                .scaledToFill()
        } else if let name = recipe.imageName, let img = UIImage(named: name) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
        } else {
            // Per-recipe coloured placeholder — matches the main recipe tab.
            RecipePlaceholderView(recipeName: recipe.name)
        }
    }

    private var nameOverlay: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [.clear, .black.opacity(0.68)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 72)

            Text(recipe.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppTheme.spacing10)
                .padding(.bottom, AppTheme.spacing10)
        }
    }
}
