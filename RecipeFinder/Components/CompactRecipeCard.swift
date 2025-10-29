import SwiftUI

struct CompactRecipeCard: View {
    let recipe: RecipeModel
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    // Performance: Pre-compute static values
    private static let imageSize: CGFloat = 100
    private static let cornerRadius: CGFloat = 12
    private static let cardHeight: CGFloat = 220
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            // Image with rounded corners
            ZStack(alignment: .topLeading) {
                RecipeImageView(imageName: recipe.imageName, height: Self.imageSize)
                    .frame(width: Self.imageSize, height: Self.imageSize, alignment: .center)
                    .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
                
                // Favorite badge
                if recipe.isFavorite {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 20, height: 20)
                            .shadow(color: .black.opacity(0.2), radius: 2)
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
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
            .padding(.top, 12)
            
            Spacer()
                .frame(height: 12)
            
            // Recipe info
            VStack(spacing: 6) {
                Text(recipe.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.orange)
                    Text(recipe.totalTime)
                        .font(.system(size: 9))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.7))
                }
                
                // Difficulty text and bars inline
                HStack(spacing: 6) {
                    DifficultyBarsView(difficulty: recipe.difficulty, size: 2.5)
                    Text(recipe.difficulty)
                        .font(.system(size: 9))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.7))
                }
            }
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: Self.cardHeight, alignment: .top)
        .background {
            cardBackground
        }
        .drawingGroup() // Performance optimization
    }
    
    // Extract background to reduce body complexity
    @ViewBuilder
    private var cardBackground: some View {
        if cardStyle == .solid {
            RoundedRectangle(cornerRadius: Self.cornerRadius)
                .fill(colorScheme == .dark ? AppTheme.cardBackgroundDark : AppTheme.cardBackground)
                .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
        } else {
            // Pure frosted glass - exactly like Settings
            RoundedRectangle(cornerRadius: Self.cornerRadius)
                .fill(.regularMaterial)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.15), radius: 10, x: 0, y: 4)
        }
    }
}
