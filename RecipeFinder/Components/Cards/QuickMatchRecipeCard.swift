import SwiftUI

/// A recipe card that surfaces how many of a set of ingredients a recipe matches.
/// Shared between the ingredient search and kitchen ("what can I make?") flows.
struct QuickMatchRecipeCard: View {
    let recipe: RecipeModel
    let matchCount: Int
    let totalIngredients: Int
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.15) : AppTheme.secondaryText.opacity(0.15)
    }
    
    private var shadowOpacity: Double {
        cardStyle == .solid ? 0.25 : (colorScheme == .dark ? 0.2 : 0.15)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            imageSection
            contentSection
        }
        .frame(width: AppTheme.width220)
        .background {
            cardBackground
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                .stroke(borderColor, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(shadowOpacity), radius: AppTheme.shadowRadiusLarge, x: 0, y: AppTheme.shadowOffsetLarge)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius16))
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        if cardStyle == .solid {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                .fill(AppTheme.cardBackground(for: colorScheme))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                    .fill(colorScheme == .dark ? Color.black.opacity(AppTheme.cardDarkOpacity) : Color.white.opacity(AppTheme.shadowDarkOpacity))
                
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                    .fill(.regularMaterial)
            }
        }
    }
    
    private var imageSection: some View {
        ZStack(alignment: .topTrailing) {
            RecipeImageView(imageName: recipe.imageName, height: AppTheme.height160)
                .frame(width: AppTheme.width220, height: AppTheme.height160)
                .clipped()
            
            matchBadge
        }
    }
    
    private var matchBadge: some View {
        let pct = totalIngredients > 0 ? Double(matchCount) / Double(totalIngredients) : 0
        let label = "\(matchCount) matched"
        return VStack(alignment: .trailing, spacing: 3) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.white)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.3)).frame(height: 3)
                    Capsule().fill(Color.white).frame(width: geo.size.width * pct, height: 3)
                }
            }
            .frame(width: 60, height: 3)
        }
        .padding(.horizontal, AppTheme.spacing8)
        .padding(.vertical, AppTheme.spacing6)
        .background(Capsule().fill(Color.green.opacity(0.85)))
        .shadow(color: Color.black.opacity(AppTheme.overlayLightOpacity), radius: 4, x: 0, y: 2)
        .padding(AppTheme.spacing10)
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            recipeNameText
            metadataRow
        }
        .padding(AppTheme.spacing12)
        .frame(width: AppTheme.width220, alignment: .leading)
        .background(contentBackground)
    }
    
    private var contentBackground: Color {
        colorScheme == .dark ? Color.white.opacity(AppTheme.glassSubtleOpacity) : Color.white
    }
    
    private var recipeNameText: some View {
        Text(recipe.name)
            .font(.headline)
            .fontWeight(.semibold)
            .adaptiveForegroundColor()
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(height: AppTheme.height40, alignment: .top)
    }
    
    private var metadataRow: some View {
        HStack(spacing: AppTheme.spacing6) {
            timeInfo
            
            Text("•")
                .font(.caption)
                .foregroundColor(colorScheme == .dark ? .white.opacity(AppTheme.lowEmphasisOpacity) : .black.opacity(AppTheme.lowEmphasisOpacity))
            
            categoryText
        }
    }
    
    private var timeInfo: some View {
        HStack(spacing: AppTheme.spacing3) {
            Image(systemName: "clock.fill")
                .font(.caption2)
                .foregroundColor(.orange)
            Text(recipe.prepTime)
                .font(.caption)
                .foregroundColor(AppTheme.adaptiveSubtitle(for: colorScheme))
        }
    }
    
    private var categoryText: some View {
        Text(recipe.category)
            .font(.caption)
            .foregroundColor(AppTheme.adaptiveSubtitle(for: colorScheme))
            .lineLimit(1)
    }
}
