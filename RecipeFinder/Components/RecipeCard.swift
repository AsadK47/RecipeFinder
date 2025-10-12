import SwiftUI

struct RecipeCard: View {
    let recipe: RecipeModel
    let viewMode: RecipeViewMode
    @Environment(\.colorScheme) var colorScheme
    
    init(recipe: RecipeModel, viewMode: RecipeViewMode = .list) {
        self.recipe = recipe
        self.viewMode = viewMode
    }
    
    var body: some View {
        CardView {
            HStack(spacing: 12) {
                // Image on the left with rounded corners
                RecipeImageView(imageName: recipe.imageName, height: 70)
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // Content in the middle
                VStack(alignment: .leading, spacing: 6) {
                    // Title and category on same line
                    HStack(alignment: .top, spacing: 8) {
                        Text(recipe.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(recipe.category)
                            .font(.system(size: 10))
                            .fontWeight(.semibold)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(AppTheme.accentColor.opacity(0.15))
                            )
                            .foregroundColor(AppTheme.accentColor)
                    }
                    
                    // Time and difficulty on same line
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                            Text(recipe.prepTime)
                                .font(.caption)
                                .foregroundColor(.primary.opacity(0.7))
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.blue)
                            Text(recipe.difficulty)
                                .font(.caption)
                                .foregroundColor(.primary.opacity(0.7))
                        }
                    }
                }
                
                // Chevron on the right
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.primary.opacity(0.3))
            }
            .padding(12)
        }
    }
}
