import SwiftUI

struct IngredientRowView: View {
    let ingredient: Ingredient
    let isChecked: Bool
    let toggle: () -> Void
    var scaleFactor: Double = 1.0
    var onAddToShopping: (() -> Void)? = nil
    var isInShoppingList: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { withAnimation(.spring(response: 0.3)) { toggle() } }) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isChecked ? .green : .gray.opacity(0.3))
                    .frame(width: 28, height: 28)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(ingredient.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(isChecked)
                    .foregroundColor(isChecked ? .gray : .primary)
                
                Text("\(ingredient.formattedQuantity(for: scaleFactor)) \(ingredient.unit)")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            Spacer()
            
            // Optional basket button for adding to shopping list
            if let addToShopping = onAddToShopping {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        addToShopping()
                    }
                }) {
                    Image(systemName: isInShoppingList ? "basket.fill" : "basket")
                        .font(.system(size: 18))
                        .foregroundColor(isInShoppingList ? AppTheme.accentColor : .gray)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 4)
    }
}
