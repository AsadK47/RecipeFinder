import SwiftUI

struct RecipeCard: View {
    let recipe: RecipeModel
    let viewMode: RecipeViewMode

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
                RecipeImageView(imageName: recipe.heroImageName, height: AppTheme.cardImageSize, recipeName: recipe.name)
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
                    .foregroundStyle(AppTheme.adaptiveEmphasis())
                    .lineLimit(Layout.nameLineLimit)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .minimumScaleFactor(Layout.nameMinScaleFactor)

                HStack(spacing: AppTheme.spacing10) {
                    if recipe.hasTotalTime {
                        HStack(spacing: AppTheme.spacing5) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: AppTheme.fontSize12, weight: .medium))
                                .foregroundStyle(.orange)
                            Text(recipe.totalTime)
                                .font(.system(size: AppTheme.fontSize13, weight: .medium))
                                .foregroundStyle(AppTheme.adaptiveCardTextEmphasis)
                        }
                    }

                    HStack(spacing: AppTheme.spacing6) {
                        DifficultyBarsView(difficulty: recipe.difficulty, size: Layout.difficultyBarSize)
                        Text(recipe.difficulty)
                            .font(.system(size: AppTheme.fontSize13, weight: .medium))
                            .foregroundStyle(AppTheme.adaptiveCardTextEmphasis)
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: AppTheme.fontSize14, weight: .semibold))
                .foregroundStyle(AppTheme.adaptiveSubtitle)
        }
        .padding(AppTheme.spacing16)
        .appCard(cornerRadius: AppTheme.cardCornerRadius)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .accessibilityElement(children: .combine)
        // Read the total time the card actually shows (it used to announce prep time only).
        .accessibilityLabel("\(recipe.name), \(recipe.category), \(recipe.hasTotalTime ? "Total time: \(recipe.totalTime), " : "")Difficulty: \(recipe.difficulty)")
        .accessibilityHint("Double tap to view recipe details")
    }
}
