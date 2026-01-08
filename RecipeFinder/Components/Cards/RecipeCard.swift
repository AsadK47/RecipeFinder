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
            // Image on the left with rounded corners
            ZStack(alignment: .topLeading) {
                RecipeImageView(imageName: recipe.imageName, height: imageSize)
                    .frame(width: imageSize, height: imageSize)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius * AppTheme.goldenRatioInverse))
                
                // Favorite badge
                if recipe.isFavorite {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 24, height: 24)
                            .shadow(color: .black.opacity(AppTheme.overlayLightOpacity), radius: 2)
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: AppTheme.fontSizeCaption1))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 1.0, green: 0.2, blue: 0.4),
                                        Color(red: 0.96, green: 0.26, blue: 0.21),
                                        Color(red: 1.0, green: 0.38, blue: 0.27),
                                        Color(red: 1.0, green: 0.5, blue: 0.0)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .offset(x: -4, y: -4)
                }
            }
            
            // Content in the middle
            VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                // Title 
                Text(recipe.name)
                    .font(.system(size: AppTheme.fontSizeBody, weight: .semibold))
                    .foregroundColor(AppTheme.adaptiveEmphasis(for: colorScheme))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .minimumScaleFactor(0.9)
                
                // Time and difficulty on same line
                HStack(spacing: AppTheme.spacing10) {
                    HStack(spacing: AppTheme.spacing5) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: AppTheme.fontSizeCaption1, weight: .medium))
                            .foregroundColor(.orange)
                        Text(recipe.totalTime)
                            .font(.system(size: AppTheme.fontSizeFootnote, weight: .medium))
                            .foregroundColor(AppTheme.adaptiveCardTextEmphasis(for: colorScheme))
                    }
                    
                    HStack(spacing: AppTheme.spacing6) {
                        DifficultyBarsView(difficulty: recipe.difficulty, size: 3.5)
                        Text(recipe.difficulty)
                            .font(.system(size: AppTheme.fontSizeFootnote, weight: .medium))
                            .foregroundColor(AppTheme.adaptiveCardTextEmphasis(for: colorScheme))
                    }
                }
            }
            
            // Chevron on the right
            Image(systemName: "chevron.right")
                .font(.system(size: AppTheme.fontSizeSubheadline, weight: .semibold))
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
    
    // Extracted background to reduce body complexity
    @ViewBuilder
    private var cardBackground: some View {
        if cardStyle == .solid {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(AppTheme.cardBackground(for: colorScheme))
                .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
        } else {
            // Frosted glass - exactly like Shopping List
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
        }
    }
}
