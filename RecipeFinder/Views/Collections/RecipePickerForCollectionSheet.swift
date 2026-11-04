import SwiftUI

/// Add/remove recipes from a collection; `RecipeSelectionSheet` grid with a checkmark on selected.
struct RecipePickerForCollectionSheet: View {
    let collection: RecipeCollection
    let recipes: [RecipeModel]
    @Environment(\.collections) private var manager
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var currentCollection: RecipeCollection {
        manager.collections.first { $0.id == collection.id } ?? collection
    }

    private var filteredRecipes: [RecipeModel] {
        guard !searchText.isEmpty else { return recipes }
        return recipes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(spacing: AppTheme.spacing12) {
                    SearchBar(text: $searchText, placeholder: "Search Recipes...")
                        .padding(.horizontal)

                    if filteredRecipes.isEmpty {
                        Spacer()
                        EmptyStateView(
                            icon: "book.closed",
                            title: recipes.isEmpty ? "No recipes yet" : "No results",
                            message: recipes.isEmpty
                                ? "Add recipes to your library to put them in this collection."
                                : "Try a different search."
                        )
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: AppTheme.spacing16) {
                                ForEach(filteredRecipes) { recipe in
                                    let isMember = currentCollection.contains(recipe.id)
                                    Button {
                                        manager.toggle(recipeID: recipe.id, in: currentCollection)
                                        HapticManager.shared.selection()
                                    } label: {
                                        CompactRecipeCard(recipe: recipe)
                                            .overlay(alignment: .topTrailing) {
                                                if isMember {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.title3)
                                                        .foregroundStyle(.white, collection.colorName.swiftUIColor)
                                                        .padding(AppTheme.spacing6)
                                                }
                                            }
                                            .overlay {
                                                if isMember {
                                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                                        .strokeBorder(collection.colorName.swiftUIColor, lineWidth: 2)
                                                }
                                            }
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
            }
            .navigationTitle("Add Recipes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
