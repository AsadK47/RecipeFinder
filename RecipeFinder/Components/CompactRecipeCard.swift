import SwiftUI

struct CompactRecipeCard: View {
    let recipe: RecipeModel
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            // Image with rounded corners
            ZStack(alignment: .topLeading) {
                RecipeImageView(imageName: recipe.imageName, height: 100)
                    .frame(width: 100, height: 100, alignment: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Favorite badge
                if recipe.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                        .padding(4)
                        .background(
                            Circle()
                                .fill(.white)
                                .shadow(color: .black.opacity(0.2), radius: 2)
                        )
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
        .frame(maxWidth: .infinity, maxHeight: 220, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardStyle == .solid
                    ? (colorScheme == .dark ? AppTheme.cardBackgroundDark : AppTheme.cardBackground)
                    : (colorScheme == .dark ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(.regularMaterial))
                )
                .shadow(
                    color: Color.black.opacity(0.25),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
    }
}
