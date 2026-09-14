import SwiftUI

/// Shows all recipes inside a single collection, with the ability to remove
/// recipes from the collection via swipe-to-delete.
struct CollectionDetailView: View {
    let collection: RecipeCollection
    @Binding var recipes: [RecipeModel]
    @ObservedObject private var manager = CollectionManager.shared
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @State private var showAddRecipes = false
    @State private var shoppingListFeedback: String?

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
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: AppTheme.spacing4) {
                    if !collectionRecipes.isEmpty {
                        Button {
                            addAllToShoppingList()
                        } label: {
                            Image(systemName: "basket.badge.plus")
                                .adaptiveForegroundColor()
                        }
                        .accessibilityLabel("Add all ingredients to shopping list")
                    }
                    Button {
                        HapticManager.shared.light()
                        showAddRecipes = true
                    } label: {
                        Image(systemName: "plus")
                            .adaptiveForegroundColor()
                    }
                    .accessibilityLabel("Add Recipes")
                }
            }
        }
        .sheet(isPresented: $showAddRecipes) {
            RecipePickerForCollectionSheet(collection: currentCollection, recipes: recipes)
        }
        .overlay(alignment: .bottom) {
            if let feedback = shoppingListFeedback {
                HStack(spacing: AppTheme.spacing12) {
                    Image(systemName: "basket.fill")
                        .adaptiveForegroundColor()
                    Text(feedback)
                        .font(.subheadline)
                        .adaptiveForegroundColor()
                }
                .padding(.horizontal, AppTheme.spacing20)
                .padding(.vertical, AppTheme.spacing12)
                .background(Capsule().fill(AppTheme.accentColor).shadow(color: .black.opacity(0.15), radius: 8, y: 4))
                .padding(.bottom, AppTheme.spacing20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: shoppingListFeedback)
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
            RecipeImageView(imageName: recipe.imageName, height: Constants.Sizes.recipeImageSize, recipeName: recipe.name)
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
                    Text("\u{2022}")
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

    private func addAllToShoppingList() {
        let ingredientCount = collectionRecipes.flatMap { $0.ingredients }.count
        guard ingredientCount > 0 else { return }
        ShoppingListManager.shared.addIngredients(from: collectionRecipes)
        HapticManager.shared.success()
        let recipeCount = collectionRecipes.count
        shoppingListFeedback = "\(ingredientCount) ingredient\(ingredientCount == 1 ? "" : "s") from \(recipeCount) recipe\(recipeCount == 1 ? "" : "s") added"
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation { shoppingListFeedback = nil }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppTheme.spacing16) {
            Image(systemName: "tray")
                .font(.system(size: AppTheme.fontSize50))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Recipes Yet")
                .font(.title3.weight(.semibold))
                .adaptiveForegroundColor()

            Text("Add your recipes to \u{201c}\(currentCollection.name)\u{201d} to keep them together.")
                .font(.subheadline)
                .adaptiveSecondaryForeground()
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.spacing32)

            Button {
                HapticManager.shared.light()
                showAddRecipes = true
            } label: {
                Label("Add Recipes", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, AppTheme.spacing24)
                    .padding(.vertical, AppTheme.spacing12)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .adaptiveForegroundColor()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
