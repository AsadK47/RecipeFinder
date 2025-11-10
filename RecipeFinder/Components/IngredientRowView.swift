import SwiftUI

struct IngredientRowView: View {
    let ingredient: Ingredient
    let isChecked: Bool
    let toggle: () -> Void
    var scaleFactor: Double = 1.0
    var measurementSystem: MeasurementSystem = .metric
    var onAddToShopping: (() -> Void)?
    var isInShoppingList: Bool = false
    var onTapQuantity: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
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
            
            HStack(spacing: 16) {
                // Ingredient name with optional prep notes
                VStack(alignment: .leading, spacing: 4) {
                    Text(ingredient.mainIngredientName)
                        .font(.body)
                        .fontWeight(.medium)
                        .strikethrough(isChecked)
                        .foregroundColor(isChecked ? .secondary : .primary)
                    
                    // Show preparation notes if any
                    if let prepNotes = ingredient.preparationNotes {
                        Text(prepNotes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Visual separator
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 1, height: 20)
                
                // Quantity with unit - improved visual separation
                Button(action: {
                    onTapQuantity?()
                }) {
                    HStack(spacing: 4) {
                        // Quantity - bold and prominent
                        Text(formatQuantity(ingredient.scaledQuantity(for: scaleFactor)))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        // Unit - lighter weight
                        if !ingredient.unit.isEmpty {
                            Text(formatUnit(ingredient.unit, system: measurementSystem))
                                .font(.caption)
                                .fontWeight(.regular)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(onTapQuantity != nil ? 0.15 : 0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(onTapQuantity == nil)
            }
            
            Spacer()
            
            Button(action: { withAnimation(.spring(response: 0.3)) { toggle() } }, label: {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 28))
                    .foregroundColor(isChecked ? .green : .gray.opacity(0.4))
                    .frame(width: 32, height: 32)
            })
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - Helper Functions
    
    /// Format quantity with smart rounding
    /// - Small values (< 5): show 1 decimal place (2.1, 3.5)
    /// - Medium values (5-100): show whole numbers (44, 75)
    /// - Large values (> 100): show whole numbers (250, 1000)
    private func formatQuantity(_ quantity: Double) -> String {
        // Handle fractions nicely
        if quantity < 1 {
            // Check common fractions
            if abs(quantity - 0.25) < 0.01 { return "¼" }
            if abs(quantity - 0.33) < 0.02 { return "⅓" }
            if abs(quantity - 0.5) < 0.01 { return "½" }
            if abs(quantity - 0.66) < 0.02 { return "⅔" }
            if abs(quantity - 0.75) < 0.01 { return "¾" }
        }
        
        // For small quantities, show 1 decimal if meaningful
        if quantity < 5 {
            if quantity.truncatingRemainder(dividingBy: 1) < 0.1 {
                return String(format: "%.0f", quantity)
            }
            return String(format: "%.1f", quantity)
        }
        
        // For larger quantities, round to whole numbers
        return String(format: "%.0f", quantity)
    }
    
    /// Format unit with proper conversion and abbreviation
    private func formatUnit(_ unit: String, system: MeasurementSystem) -> String {
        // Convert if needed
        let converted = UnitConversion.convert(
            value: ingredient.scaledQuantity(for: scaleFactor),
            unit: unit,
            to: system,
            ingredientName: ingredient.name
        )
        
        return converted.unit
    }
}
