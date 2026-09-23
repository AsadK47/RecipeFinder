import SwiftUI

/// Shows all recipes inside a single collection, with the ability to remove
/// recipes from the collection via swipe-to-delete.
struct CollectionDetailView: View {
    let collection: RecipeCollection
    @Binding var recipes: [RecipeModel]
    @Environment(\.collections) private var manager
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
                            Image(systemName: "cart.badge.plus")
                                .adaptiveForegroundColor()
                        }
                        .accessibilityLabel("Add all ingredients to groceries")
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
        .toast($shoppingListFeedback)
    }

    private var recipeList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.cardVerticalSpacing) {
                ForEach(collectionRecipes) { recipe in
                    RecipeLink(recipe: recipe, onRecipeChange: refreshRecipes) {
                        RecipeRow(recipe: recipe)
                    }
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

    /// Re-syncs the bound recipe array from Core Data after a change made on the
    /// detail screen (post-cook photo, rating, cook count…) so returning to this
    /// collection shows fresh data rather than a stale copy.
    private func refreshRecipes() {
        Task { recipes = await PersistenceController.shared.fetchRecipesAsync() }
    }

    private func addAllToShoppingList() {
        let ingredientCount = collectionRecipes.flatMap { $0.ingredients }.count
        guard ingredientCount > 0 else { return }
        ShoppingListManager.shared.addIngredients(from: collectionRecipes)
        HapticManager.shared.success()
        let recipeCount = collectionRecipes.count
        shoppingListFeedback = "\(ingredientCount) ingredient\(ingredientCount == 1 ? "" : "s") from \(recipeCount) recipe\(recipeCount == 1 ? "" : "s") added"
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "tray",
            title: "No Recipes Yet",
            message: "Add your recipes to \u{201c}\(currentCollection.name)\u{201d} to keep them together.",
            actionTitle: "Add Recipes",
            actionIcon: "plus",
            onAction: { showAddRecipes = true }
        )
        .frame(maxHeight: .infinity)
    }
}
