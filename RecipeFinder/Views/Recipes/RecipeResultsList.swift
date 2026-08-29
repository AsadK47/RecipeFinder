import SwiftUI

/// The scrollable results for the recipe search screen: a "My Recipes" section
/// and a collapsible "Sample Recipes" section. Extracted from `RecipeSearchView`
/// so the screen stays focused on composition and state.
struct RecipeResultsList: View {
    let filteredRecipes: [RecipeModel]
    @Binding var hideSampleRecipes: Bool
    let searchText: String
    let activeFilterCount: Int
    let showFavoritesOnly: Bool
    let onFavoriteToggle: () -> Void
    let onRequestDelete: (RecipeModel) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.cardVerticalSpacing) {
                let userRecipes = filteredRecipes.filter { !$0.isSampleRecipe }
                let sampleRecipes = filteredRecipes.filter { $0.isSampleRecipe }

                if !userRecipes.isEmpty {
                    sectionHeader(title: "My Recipes", count: userRecipes.count, isCollapsible: false)
                    ForEach(userRecipes) { recipe in
                        navigationLink(for: recipe)
                    }
                }

                if !sampleRecipes.isEmpty && !hideSampleRecipes {
                    sectionHeader(title: "Sample Recipes", count: sampleRecipes.count, isCollapsible: true)
                    ForEach(sampleRecipes) { recipe in
                        navigationLink(for: recipe)
                    }
                } else if !sampleRecipes.isEmpty && hideSampleRecipes && searchText.isEmpty && activeFilterCount == 0 && !showFavoritesOnly {
                    collapsedSampleIndicator(count: sampleRecipes.count)
                }
            }
            .padding(.horizontal, AppTheme.cardHorizontalPadding)
            .padding(.bottom, AppTheme.cardHorizontalPadding)
        }
    }

    private func sectionHeader(title: String, count: Int, isCollapsible: Bool) -> some View {
        HStack(spacing: AppTheme.spacing8) {
            Image(systemName: title == "My Recipes" ? "person.fill" : "sparkles")
                .font(.system(size: AppTheme.fontSize14, weight: .semibold))
                .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
            Text(title)
                .font(.system(size: AppTheme.fontSize15, weight: .semibold))
                .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
            Text("(\(count))")
                .font(.system(size: AppTheme.fontSize13, weight: .medium))
                .adaptiveForegroundColor(opacity: AppTheme.glassLightOpacity)
            Spacer()
            if isCollapsible {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        hideSampleRecipes.toggle()
                    }
                    HapticManager.shared.light()
                }) {
                    Image(systemName: hideSampleRecipes ? "chevron.down" : "chevron.up")
                        .font(.system(size: AppTheme.fontSize12, weight: .semibold))
                        .adaptiveForegroundColor(opacity: AppTheme.mediumEmphasisOpacity)
                        .frame(width: AppTheme.iconSize32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(AppTheme.shadowLightOpacity))
                        )
                }
            }
        }
        .padding(.horizontal, AppTheme.spacing4)
        .padding(.top, AppTheme.spacing8)
        .padding(.bottom, AppTheme.spacing4)
    }

    private func collapsedSampleIndicator(count: Int) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                hideSampleRecipes = false
            }
            HapticManager.shared.light()
        }) {
            HStack(spacing: AppTheme.spacing12) {
                Image(systemName: "sparkles")
                    .font(.system(size: AppTheme.fontSize16, weight: .semibold))
                    .adaptiveForegroundColor(opacity: AppTheme.mediumEmphasisOpacity)
                Text("\(count) sample recipes hidden")
                    .font(.system(size: AppTheme.fontSize15, weight: .medium))
                    .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: AppTheme.fontSize12, weight: .semibold))
                    .adaptiveForegroundColor(opacity: AppTheme.mediumEmphasisOpacity)
            }
            .padding(.horizontal, AppTheme.spacing16)
            .padding(.vertical, AppTheme.spacing12)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .fill(Color.white.opacity(AppTheme.tinyOpacity))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, AppTheme.spacing4)
    }

    private func navigationLink(for recipe: RecipeModel) -> some View {
        NavigationLink(
            destination: RecipeDetailView(
                recipe: recipe,
                onFavoriteToggle: onFavoriteToggle
            )
        ) {
            RecipeCard(recipe: recipe, viewMode: .list)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(role: .destructive) {
                onRequestDelete(recipe)
            } label: {
                Label("Delete Recipe", systemImage: "trash.fill")
            }
        }
    }
}
