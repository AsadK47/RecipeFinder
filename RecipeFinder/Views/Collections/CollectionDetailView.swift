import SwiftUI

/// Shows all recipes inside a single collection, with the ability to remove
/// recipes from the collection via swipe-to-delete.
struct CollectionDetailView: View {
    let collection: RecipeCollection
    @Binding var recipes: [RecipeModel]
    @ObservedObject private var manager = CollectionManager.shared
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal

    private var collectionRecipes: [RecipeModel] {
        let ids = Set(currentCollection.recipeIDs)
        return recipes.filter { ids.contains($0.id) }
    }

    private var currentCollection: RecipeCollection {
        manager.collections.first { $0.id == collection.id } ?? collection
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()

            if collectionRecipes.isEmpty {
                emptyState
            } else {
                recipeList
            }
        }
        .navigationTitle(currentCollection.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var recipeList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.cardVerticalSpacing) {
                ForEach(collectionRecipes) { recipe in
                    NavigationLink {
                        RecipeDetailView(recipe: recipe)
                    } label: {
                        recipeRow(recipe)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            manager.remove(recipeID: recipe.id, from: currentCollection)
                            HapticManager.shared.delete()
                        } label: {
                            Label("Remove", systemImage: "minus.circle")
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.spacing16)
            .padding(.vertical, AppTheme.spacing12)
            .padding(.bottom, AppTheme.spacing100)
        }
    }

    private func recipeRow(_ recipe: RecipeModel) -> some View {
        HStack(spacing: AppTheme.spacing12) {
            RecipeImageView(imageName: recipe.imageName, height: Constants.Sizes.recipeImageSize)
                .frame(width: Constants.Sizes.recipeImageSize, height: Constants.Sizes.recipeImageSize)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius8))

            VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                Text(recipe.name)
                    .font(.subheadline.weight(.semibold))
                    .adaptiveForegroundColor()
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: AppTheme.spacing6) {
                    Text(recipe.category)
                    Text("•")
                    Text(recipe.difficulty)
                }
                .font(.caption)
                .adaptiveSecondaryForeground()

                if !recipe.tags.isEmpty {
                    TagRowView(tags: recipe.tags)
                }
            }

            Spacer(minLength: 0)

            if recipe.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(AppTheme.spacing12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius12))
    }

    private var emptyState: some View {
        VStack(spacing: AppTheme.spacing16) {
            Image(systemName: "tray")
                .font(.system(size: AppTheme.fontSize50))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Recipes Yet")
                .font(.title3.weight(.semibold))
                .adaptiveForegroundColor()

            Text("Add recipes to "\(currentCollection.name)" from any recipe's detail view.")
                .font(.subheadline)
                .adaptiveSecondaryForeground()
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.spacing32)
        }
    }
}
