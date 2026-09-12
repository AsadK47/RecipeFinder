import SwiftUI

/// Lets the user add or remove recipes from a collection in one place.
/// Shows all recipes; those already in the collection are checked.
struct RecipePickerForCollectionSheet: View {
    let collection: RecipeCollection
    let recipes: [RecipeModel]
    @ObservedObject private var manager = CollectionManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
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
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    SearchBar(text: $searchText, placeholder: "Search Recipes...")
                        .padding(.horizontal, AppTheme.spacing16)
                        .padding(.vertical, AppTheme.spacing12)

                    if filteredRecipes.isEmpty {
                        Spacer()
                        VStack(spacing: AppTheme.spacing12) {
                            Image(systemName: "book.closed")
                                .font(.system(size: AppTheme.fontSize40))
                                .adaptiveSecondaryForeground()
                            Text(recipes.isEmpty ? "No recipes yet" : "No results")
                                .font(.headline)
                                .adaptiveSecondaryForeground()
                        }
                        Spacer()
                    } else {
                        List(filteredRecipes) { recipe in
                            let isMember = currentCollection.contains(recipe.id)
                            Button {
                                manager.toggle(recipeID: recipe.id, in: currentCollection)
                                HapticManager.shared.selection()
                            } label: {
                                HStack(spacing: AppTheme.spacing12) {
                                    VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                                        Text(recipe.name)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        Text(recipe.category)
                                            .font(.caption)
                                            .adaptiveSecondaryForeground()
                                    }
                                    Spacer()
                                    Image(systemName: isMember ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(isMember ? AppTheme.accentColor(for: selectedTheme) : .secondary.opacity(0.4))
                                        .font(.title3)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
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
