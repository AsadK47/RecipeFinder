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
        HStack(spacing: 0) {
            // Left column: Ingredient name with optional prep notes
            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.mainIngredientName)
                    .font(.body)
                    .fontWeight(.semibold)
                    .strikethrough(isChecked)
                    .foregroundStyle(isChecked ? .secondary : .primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                    
                // Show preparation notes if any
                if let prepNotes = ingredient.preparationNotes {
                    Text(prepNotes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 12)
            
            // First separator
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 1, height: 40)
            
            // Middle column: Quantity with unit
            Button(action: {
                onTapQuantity?()
            }) {
                HStack(spacing: 4) {
                    // Quantity - bold and prominent
                    Text(formatQuantity(ingredient.scaledQuantity(for: scaleFactor)))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    // Unit - lighter weight
                    if !ingredient.unit.isEmpty {
                        Text(formatUnit(ingredient.unit, system: measurementSystem))
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.accentColor.opacity(0.12))
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(onTapQuantity == nil)
            .frame(width: 80)
            .padding(.horizontal, 12)
            .allowsHitTesting(true)
            
            // Second separator
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 1, height: 40)
            
            // Right column: Checkbox
            Button(action: { 
                HapticManager.shared.light()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { 
                    toggle() 
                } 
            }, label: {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isChecked ? .green : .gray.opacity(0.4))
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            })
            .buttonStyle(.plain)
            .frame(width: 50)
            .padding(.leading, 12)
            .allowsHitTesting(true)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .swipe(onAddToShopping != nil,
               trailing: onAddToShopping.map { addAction in
                   SwipeAction(
                       icon: "cart.badge.plus",
                       backgroundColor: AppTheme.accentColor,
                       action: addAction
                   )
               })
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
