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
                            .shadow(color: .black.opacity(0.2), radius: 2)
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.2, blue: 0.4),
                                        Color(red: 0.96, green: 0.26, blue: 0.21),
                                        Color(red: 1.0, green: 0.38, blue: 0.27),
                                        Color(red: 1.0, green: 0.5, blue: 0.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .offset(x: -4, y: -4)
                }
            }
            
            // Content in the middle
            VStack(alignment: .leading, spacing: 6) {
                // Title 
                Text(recipe.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Time and difficulty on same line
                HStack(spacing: contentSpacing) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                        Text(recipe.totalTime)
                            .font(.caption)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.7))
                    }
                    
                    HStack(spacing: 6) {
                        DifficultyBarsView(difficulty: recipe.difficulty, size: 3)
                        Text(recipe.difficulty)
                            .font(.caption)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.7))
                    }
                }
            }
            
            // Chevron on the right
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.4))
        }
        .padding(contentSpacing)
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
                .fill(colorScheme == .dark ? AppTheme.cardBackgroundDark : AppTheme.cardBackground)
                .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
        } else {
            // Frosted glass - exactly like Shopping List
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.regularMaterial)
        }
    }
}
