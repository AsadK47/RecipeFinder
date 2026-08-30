import SwiftUI

/// The horizontally-scrolling "Recipe Ideas" strip that shows recipes matching
/// the user's kitchen. Extracted from `KitchenView`.
struct KitchenQuickMatchesView: View {
    let quickMatches: [RecipeModel]
    let kitchenItemNames: [String]
    let selectedTheme: AppTheme.ThemeType
    let colorScheme: ColorScheme
    let onFavoriteToggle: () -> Void

    private var matchCountText: String {
        let count = quickMatches.count
        return count == 1 ? "1 match" : "\(count) matches"
    }

    private var badgeKitchenIngredients: Set<String> {
        Set(kitchenItemNames.map { $0.lowercased() })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            HStack(spacing: AppTheme.spacing6) {
                Image(systemName: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.yellow)
                Text("Recipe Ideas")
                    .font(.title3.bold())
                    .adaptiveForegroundColor()
                Spacer()
                Text(matchCountText)
                    .font(.caption)
                    .foregroundColor(AppTheme.adaptiveSubtitle(for: colorScheme))
            }
            .padding(.horizontal, AppTheme.spacing20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.spacing12) {
                    ForEach(quickMatches.prefix(10)) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipe: recipe, onFavoriteToggle: onFavoriteToggle)) {
                            QuickMatchRecipeCard(
                                recipe: recipe,
                                matchCount: KitchenRecipeMatcher.matchCount(
                                    recipe: recipe,
                                    kitchenIngredients: badgeKitchenIngredients
                                ),
                                totalIngredients: recipe.ingredients.count
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, AppTheme.spacing20)
            }
        }
    }
}
