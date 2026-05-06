import SwiftUI

struct CompactRecipeCard: View {
    let recipe: RecipeModel
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted

    private enum Layout {
        static let cardHeight: CGFloat = 220
        static let difficultyBarSize: CGFloat = 2.5
        static let favoriteBadgeOffset: CGFloat = -AppTheme.spacing4
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            ZStack(alignment: .topLeading) {
                RecipeImageView(imageName: recipe.imageName, height: AppTheme.width100)
                    .frame(width: AppTheme.width100, height: AppTheme.width100, alignment: .center)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius12))

                if recipe.isFavorite {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: AppTheme.iconSize20, height: AppTheme.iconSize20)
                            .shadow(color: .black.opacity(AppTheme.overlayLightOpacity), radius: AppTheme.shadowRadiusSmall)

                        Image(systemName: "heart.fill")
                            .font(.system(size: AppTheme.fontSize10))
                            .foregroundStyle(HeartPalette.gradient)
                    }
                    .offset(x: Layout.favoriteBadgeOffset, y: Layout.favoriteBadgeOffset)
                }
            }
            .padding(.top, AppTheme.spacing12)

            Spacer()
                .frame(height: AppTheme.spacing12)

            VStack(spacing: AppTheme.spacing6) {
                Text(recipe.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.adaptiveEmphasis(for: colorScheme))
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                HStack(spacing: AppTheme.spacing4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: AppTheme.fontSize11))
                        .foregroundColor(.orange)
                    Text(recipe.totalTime)
                        .font(.system(size: AppTheme.fontSize11))
                        .foregroundColor(AppTheme.adaptiveCardTextEmphasis(for: colorScheme))
                }

                HStack(spacing: AppTheme.spacing6) {
                    DifficultyBarsView(difficulty: recipe.difficulty, size: Layout.difficultyBarSize)
                    Text(recipe.difficulty)
                        .font(.system(size: AppTheme.fontSize11))
                        .foregroundColor(AppTheme.adaptiveCardTextEmphasis(for: colorScheme))
                }
            }
            .padding(.bottom, AppTheme.spacing12)
        }
        .padding(.horizontal, AppTheme.spacing12)
        .frame(maxWidth: .infinity, maxHeight: Layout.cardHeight, alignment: .top)
        .background {
            cardBackground
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius12))
    }

    @ViewBuilder
    private var cardBackground: some View {
        if cardStyle == .solid {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                .fill(AppTheme.cardBackground(for: colorScheme))
                .shadow(
                    color: Color.black.opacity(CardViewLayout.shadowOpacitySolid),
                    radius: AppTheme.shadowRadiusLarge,
                    x: 0,
                    y: AppTheme.shadowOffsetLarge
                )
        } else {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                .fill(.ultraThinMaterial)
        }
    }
}
