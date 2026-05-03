import SwiftUI

struct CompactRecipeCard: View {
    let recipe: RecipeModel
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    private static let imageSize: CGFloat = 100
    private static let cornerRadius: CGFloat = 12
    private static let cardHeight: CGFloat = 220
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            ZStack(alignment: .topLeading) {
                RecipeImageView(imageName: recipe.imageName, height: Self.imageSize)
                    .frame(width: Self.imageSize, height: Self.imageSize, alignment: .center)
                    .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
                
                if recipe.isFavorite {
                    ZStack {
                        Circle()
                            .fill(colorScheme == .dark ? .white : .white)
                            .frame(width: 20, height: 20)
                            .shadow(color: .black.opacity(AppTheme.overlayLightOpacity), radius: 2)
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: AppTheme.fontSize10))
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
            .padding(.top, 12)
            
            Spacer()
                .frame(height: 12)
            
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
                    DifficultyBarsView(difficulty: recipe.difficulty, size: 2.5)
                    Text(recipe.difficulty)
                        .font(.system(size: AppTheme.fontSize11))
                        .foregroundColor(AppTheme.adaptiveCardTextEmphasis(for: colorScheme))
                }
            }
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: Self.cardHeight, alignment: .top)
        .background {
            cardBackground
        }
        .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        if cardStyle == .solid {
            RoundedRectangle(cornerRadius: Self.cornerRadius)
                .fill(AppTheme.cardBackground(for: colorScheme))
                .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
        } else {
            RoundedRectangle(cornerRadius: Self.cornerRadius)
                .fill(.ultraThinMaterial)
        }
    }
}
