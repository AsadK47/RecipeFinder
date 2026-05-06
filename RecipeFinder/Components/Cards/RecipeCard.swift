import SwiftUI

struct RecipeCard: View {
    let recipe: RecipeModel
    let viewMode: RecipeViewMode
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted

    private enum Layout {
        static let difficultyBarSize: CGFloat = 3.5
        static let nameLineLimit: Int = 2
        static let nameMinScaleFactor: CGFloat = 0.9
    }

    init(recipe: RecipeModel, viewMode: RecipeViewMode = .list) {
        self.recipe = recipe
        self.viewMode = viewMode
    }

    var body: some View {
        HStack(spacing: AppTheme.cardVerticalSpacing) {
            ZStack(alignment: .topLeading) {
                RecipeImageView(imageName: recipe.imageName, height: AppTheme.cardImageSize)
                    .frame(width: AppTheme.cardImageSize, height: AppTheme.cardImageSize)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius * AppTheme.goldenRatioInverse))

                if recipe.isFavorite {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: AppTheme.iconSize24, height: AppTheme.iconSize24)
                            .shadow(color: .black.opacity(AppTheme.overlayLightOpacity), radius: AppTheme.shadowRadiusSmall)

                        Image(systemName: "heart.fill")
                            .font(.system(size: AppTheme.fontSize12))
                            .foregroundStyle(HeartPalette.gradient)
                    }
                    .offset(x: -AppTheme.spacing4, y: -AppTheme.spacing4)
                }
            }

            VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                Text(recipe.name)
                    .font(.system(size: AppTheme.fontSize16, weight: .semibold))
                    .foregroundColor(AppTheme.adaptiveEmphasis(for: colorScheme))
                    .lineLimit(Layout.nameLineLimit)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .minimumScaleFactor(Layout.nameMinScaleFactor)

                HStack(spacing: AppTheme.spacing10) {
                    HStack(spacing: AppTheme.spacing5) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: AppTheme.fontSize12, weight: .medium))
                            .foregroundColor(.orange)
                        Text(recipe.totalTime)
                            .font(.system(size: AppTheme.fontSize13, weight: .medium))
                            .foregroundColor(AppTheme.adaptiveCardTextEmphasis(for: colorScheme))
                    }

                    HStack(spacing: AppTheme.spacing6) {
                        DifficultyBarsView(difficulty: recipe.difficulty, size: Layout.difficultyBarSize)
                        Text(recipe.difficulty)
                            .font(.system(size: AppTheme.fontSize13, weight: .medium))
                            .foregroundColor(AppTheme.adaptiveCardTextEmphasis(for: colorScheme))
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: AppTheme.fontSize14, weight: .semibold))
                .foregroundColor(AppTheme.adaptiveSubtitle(for: colorScheme))
        }
        .padding(AppTheme.spacing16)
        .background {
            cardBackground
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recipe.name), \(recipe.category), Preparation time: \(recipe.prepTime), Difficulty: \(recipe.difficulty)")
        .accessibilityHint("Double tap to view recipe details")
    }

    @ViewBuilder
    private var cardBackground: some View {
        if cardStyle == .solid {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(AppTheme.cardBackground(for: colorScheme))
                .shadow(color: Color.black.opacity(CardViewLayout.shadowOpacitySolid), radius: AppTheme.shadowRadiusLarge, x: 0, y: AppTheme.shadowOffsetLarge)
        } else {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(.ultraThinMaterial)
        }
    }
}
