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
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.orange)
                    Text(recipe.prepTime)
                        .font(.system(size: 9))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.7))
                }
                
                Text(recipe.category)
                    .font(.system(size: 9))
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(AppTheme.accentColor)
                    )
                    .foregroundColor(.white)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
        )
    }
}
