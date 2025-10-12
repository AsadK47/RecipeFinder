import SwiftUI

struct CompactRecipeCard: View {
    let recipe: RecipeModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            // Circular image bubble
            RecipeImageView(imageName: recipe.imageName, height: 100)
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    AppTheme.gradientStart.opacity(0.6),
                                    AppTheme.gradientEnd.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                )
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            
            // Recipe name below
            Text(recipe.name)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 100)
        }
    }
}
