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
        HStack(alignment: .center, spacing: 0) {
            // Left column: name stacked above quantity pill
            VStack(alignment: .leading, spacing: 10) {
                // Ingredient name — gets all available width, wraps freely
                Text(ingredient.mainIngredientName)
                    .font(.body)
                    .fontWeight(.semibold)
                    .strikethrough(isChecked)
                    .foregroundStyle(isChecked ? .secondary : .primary)
                    .fixedSize(horizontal: false, vertical: true)

                // Preparation notes (e.g. "finely chopped")
                if let prepNotes = ingredient.preparationNotes {
                    Text(prepNotes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Quantity + unit pill, tappable for scaling
                Button(action: { onTapQuantity?() }) {
                    HStack(spacing: 4) {
                        Text(formatQuantity(ingredient.scaledQuantity(for: scaleFactor)))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)

                        if !ingredient.unit.isEmpty {
                            Text(formatUnit(ingredient.unit, system: measurementSystem))
                                .font(.caption)
                                .fontWeight(.regular)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(AppTheme.accentColor.opacity(0.13))
                    )
                }
                .buttonStyle(.plain)
                .disabled(onTapQuantity == nil)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 10)

            // Vertical divider
            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 1)
                .padding(.vertical, 6)

            // Right column: Checkbox
            Button(action: {
                HapticManager.shared.light()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    toggle()
                }
            }, label: {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: AppTheme.fontSize28))
                    .foregroundColor(isChecked ? .green : .gray.opacity(0.4))
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            })
            .buttonStyle(.plain)
            .frame(width: 48)
            .allowsHitTesting(true)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .contextMenu {
            if let onAddToShopping = onAddToShopping {
                Button(action: {
                    onAddToShopping()
                    HapticManager.shared.light()
                }) {
                    Label(isInShoppingList ? "Already in Shopping List" : "Add to Shopping List", 
                          systemImage: isInShoppingList ? "checkmark.circle.fill" : "cart.badge.plus")
                }
                .disabled(isInShoppingList)
            }
        }
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
