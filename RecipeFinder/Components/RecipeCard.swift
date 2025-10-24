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
        HStack(spacing: 12) {
            // Image on the left with rounded corners
            RecipeImageView(imageName: recipe.imageName, height: 70)
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
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
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                        Text(recipe.totalTime)
                            .font(.caption)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.7))
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
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
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recipe.name), \(recipe.category), Preparation time: \(recipe.prepTime), Difficulty: \(recipe.difficulty)")
        .accessibilityHint("Double tap to view recipe details")
    }
}

