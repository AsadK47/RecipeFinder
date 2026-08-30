import SwiftUI

/// A single ingredient row in the search results: tap to see recipes, or add it
/// to the shopping list. Extracted from `IngredientSearchView`.
struct IngredientRow: View {
    let ingredient: String
    let recipeCount: Int
    let isAdded: Bool
    let onSelect: () -> Void
    let onAddToShoppingList: () -> Void
    let cardStyle: CardStyle
    let colorScheme: ColorScheme

    var body: some View {
        let category = CategoryClassifier.suggestCategory(for: ingredient)

        return HStack(spacing: 0) {
            Button(
                action: onSelect,
                label: {
                    HStack(spacing: AppTheme.spacing12) {
                    Image(systemName: CategoryClassifier.categoryIcon(for: category))
                        .foregroundColor(CategoryClassifier.categoryColor(for: category))
                        .font(.body)
                    
                    Text(ingredient)
                        .font(.body)
                        .adaptiveForegroundColor()
                    
                    Spacer()
                    
                    Text("\(recipeCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .adaptiveForegroundColor()
                        .padding(.horizontal, AppTheme.spacing10)
                        .padding(.vertical, AppTheme.spacing5)
                        .background(
                            Capsule()
                                .fill(AppTheme.accentColor)
                        )
                }
                .padding(.horizontal, AppTheme.spacing16)
                .padding(.vertical, AppTheme.spacing14)
            })
            .buttonStyle(PlainButtonStyle())
            
            Button(
                action: onAddToShoppingList,
                label: {
                    Image(systemName: isAdded ? "basket.fill" : "basket")
                        .foregroundColor(isAdded ? AppTheme.accentColor : (AppTheme.adaptiveSubtitle(for: colorScheme)))
                        .font(.system(size: AppTheme.fontSize20))
                        .frame(width: AppTheme.buttonHeight, height: AppTheme.height44)
                        .scaleEffect(isAdded ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAdded)
                }
            )
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, AppTheme.spacing12)
        }
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .fill(AppTheme.cardBackground(for: colorScheme))
            } else {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .fill(.regularMaterial)
            }
        }
    }
}
