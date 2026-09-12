import SwiftUI

struct RecipeSelectionSheet: View {
    @Binding var recipes: [RecipeModel]
    let mealTime: MealTime?
    let onSelectExisting: (RecipeModel) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @Environment(\.colorScheme) var colorScheme

    var filteredRecipes: [RecipeModel] {
        if searchText.isEmpty {
            return recipes
        }
        return recipes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: AppTheme.spacing12) {
                    SearchBar(text: $searchText, placeholder: "Search Recipes...")
                        .padding(.horizontal)

                    if filteredRecipes.isEmpty {
                        Spacer()
                        VStack(spacing: AppTheme.spacing12) {
                            Image(systemName: "book.closed")
                                .font(.system(size: AppTheme.fontSize40))
                                .adaptiveSecondaryForeground()
                            Text("No recipes found")
                                .font(.headline)
                                .adaptiveSecondaryForeground()
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: AppTheme.spacing16) {
                                ForEach(filteredRecipes) { recipe in
                                    Button(action: {
                                        onSelectExisting(recipe)
                                        HapticManager.shared.light()
                                    }) {
                                        CompactRecipeCard(recipe: recipe)
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
            .navigationTitle(mealTime.map { "Add to \($0.rawValue)" } ?? "Add Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .adaptiveForegroundColor()
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}
