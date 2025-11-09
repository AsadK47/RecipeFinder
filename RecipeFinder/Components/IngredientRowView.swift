import SwiftUI

struct IngredientRowView: View {
    let ingredient: Ingredient
    let isChecked: Bool
    let toggle: () -> Void
    var scaleFactor: Double = 1.0
    var measurementSystem: MeasurementSystem = .metric
    var onAddToShopping: (() -> Void)?
    var isInShoppingList: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Optional basket button for adding to shopping list
            if let addToShopping = onAddToShopping {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        addToShopping()
                    }
                }, label: {
                    Image(systemName: isInShoppingList ? "basket.fill" : "basket")
                        .font(.system(size: 20))
                        .foregroundColor(isInShoppingList ? AppTheme.accentColor : .gray.opacity(0.5))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                })
                .buttonStyle(PlainButtonStyle())
            }
            
            HStack(spacing: 12) {
                // Ingredient name
                Text(ingredient.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .strikethrough(isChecked)
                    .foregroundColor(isChecked ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Visual separator
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 1, height: 20)
                
                // Quantity with unit
                Text(ingredient.formattedWithUnit(for: scaleFactor, system: measurementSystem))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.1))
                    )
            }
            
            Spacer()
            
            Button(action: { withAnimation(.spring(response: 0.3)) { toggle() } }, label: {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 28))
                    .foregroundColor(isChecked ? .green : .gray.opacity(0.4))
                    .frame(width: 32, height: 32)
            })
        }
        .padding(.vertical, 8)
    }
}
