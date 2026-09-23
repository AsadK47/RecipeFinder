import SwiftUI
import Kingfisher

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
        NavigationStack {
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

/// Photo-forward recipe card for the meal planner picker.
/// The image fills the entire card area; the recipe name overlays the bottom with a gradient scrim.
/// No separate card background or border — the photo is the card.
private struct MealPickerRecipeCard: View {
    let recipe: RecipeModel

    @State private var loadFailed = false

    private var kfSource: Source? {
        guard let name = recipe.imageName, !name.isEmpty else { return nil }
        if name.hasPrefix("http"), let url = URL(string: name) { return .network(url) }
        if name.hasPrefix("/") { return .provider(LocalFileImageDataProvider(fileURL: URL(fileURLWithPath: name))) }
        return nil
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
            // No photo: subtle gradient placeholder — avoids the heavy solid-box look
            ZStack {
                LinearGradient(
                    colors: [Color.white.opacity(0.12), Color.white.opacity(0.04)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "fork.knife")
                    .font(.system(size: 32))
                    .foregroundStyle(.white.opacity(0.2))
            }
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
