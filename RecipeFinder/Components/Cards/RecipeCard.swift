import SwiftUI

struct RecipeCard: View {
    let recipe: RecipeModel
    let viewMode: RecipeViewMode
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    private static let cardPadding: CGFloat = AppTheme.cardHorizontalPadding
    private static let imageSize: CGFloat = AppTheme.cardImageSize
    private static let cornerRadius: CGFloat = AppTheme.cardCornerRadius
    private static let contentSpacing: CGFloat = AppTheme.cardVerticalSpacing
    
    private var cardPadding: CGFloat { Self.cardPadding }
    private var imageSize: CGFloat { Self.imageSize }
    private var cornerRadius: CGFloat { Self.cornerRadius }
    private var contentSpacing: CGFloat { Self.contentSpacing }
    
    init(recipe: RecipeModel, viewMode: RecipeViewMode = .list) {
        self.recipe = recipe
        self.viewMode = viewMode
    }
    
    var body: some View {
        HStack(spacing: contentSpacing) {
            ZStack(alignment: .topLeading) {
                RecipeImageView(imageName: recipe.imageName, height: imageSize)
                    .frame(width: imageSize, height: imageSize)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius * AppTheme.goldenRatioInverse))
                
                if recipe.isFavorite {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: AppTheme.iconSize24, height: AppTheme.iconSize24)
                            .shadow(color: .black.opacity(AppTheme.overlayLightOpacity), radius: 2)

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
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .minimumScaleFactor(0.9)
                
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
                        DifficultyBarsView(difficulty: recipe.difficulty, size: 3.5)
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
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recipe.name), \(recipe.category), Preparation time: \(recipe.prepTime), Difficulty: \(recipe.difficulty)")
        .accessibilityHint("Double tap to view recipe details")
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        if cardStyle == .solid {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(AppTheme.cardBackground(for: colorScheme))
                .shadow(color: Color.black.opacity(CardViewLayout.shadowOpacitySolid), radius: AppTheme.shadowRadiusLarge, x: 0, y: AppTheme.shadowOffsetLarge)
        } else {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
        }
    }
}
