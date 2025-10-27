import SwiftUI

struct CompactRecipeCard: View {
    let recipe: RecipeModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            // Image with rounded corners
            RecipeImageView(imageName: recipe.imageName, height: 100)
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
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
        }
        .padding(12)
        .frame(height: 220)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
                .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
        )
    }
}
