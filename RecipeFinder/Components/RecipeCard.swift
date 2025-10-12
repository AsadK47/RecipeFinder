import SwiftUI

struct RecipeCard: View {
    let recipe: RecipeModel
    let viewMode: RecipeViewMode
    
    init(recipe: RecipeModel, viewMode: RecipeViewMode = .list) {
        self.recipe = recipe
        self.viewMode = viewMode
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Image on the left
            RecipeImageView(imageName: recipe.imageName, height: 120)
                .frame(width: 120)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 24,
                        bottomLeadingRadius: 24
                    )
                )
            
            // Content in the middle
            VStack(alignment: .leading, spacing: 8) {
                Text(recipe.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text(recipe.prepTime)
                            .font(.caption)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar")
                            .font(.caption)
                        Text(recipe.difficulty)
                            .font(.caption)
                    }
                }
                .foregroundColor(AppTheme.secondaryText)
                
                Text(recipe.category)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(AppTheme.accentColor)
                    )
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Chevron on the right
            Image(systemName: "chevron.right")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.accentColor.opacity(0.6))
                .padding(.trailing, 16)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }
}
