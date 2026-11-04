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
    var onSubstitute: (() -> Void)?

    private enum Timing {
        static let springResponse: Double = 0.3
        static let springDamping: Double = 0.6
    }

    var body: some View {
        HStack(alignment: .center, spacing: AppTheme.spacing12) {

            // Fixed-width amount column so names align; whole column is the tap target, reserved even when empty to keep alignment.
            Button(action: { onTapQuantity?() }) {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    if convertedIngredient.quantity > 0 {
                        Text(formatQuantity(convertedIngredient.quantity))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(isChecked ? .secondary : .primary)
                    }

                    if !convertedIngredient.unit.isEmpty {
                        Text(Self.displayUnit(convertedIngredient.unit, quantity: convertedIngredient.quantity))
                            .font(.caption)
                            .adaptiveSecondaryForeground()
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                .frame(width: 72, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(onTapQuantity == nil)

            Button(action: {
                HapticManager.shared.light()
                withAnimation(.spring(response: Timing.springResponse, dampingFraction: Timing.springDamping)) {
                    toggle()
                }
            }) {
                VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                    let parts = ingredient.displayParts
                    Text(parts.name)
                        .font(.body)
                        .fontWeight(.semibold)
                        .strikethrough(isChecked)
                        .foregroundStyle(isChecked ? .secondary : .primary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let prep = parts.note {
                        Text(prep)
                            .font(.caption)
                            .adaptiveSecondaryForeground()
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(isChecked ? 0.5 : 1)
            .accessibilityValue(isChecked ? "checked" : "unchecked")

            if let onSubstitute {
                Button(action: onSubstitute) {
                    Image(systemName: "arrow.2.squarepath")
                        .font(.system(size: AppTheme.fontSize16))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Find substitute for \(ingredient.mainIngredientName)")
            }

            if let onAddToShopping {
                Button(action: {
                    onAddToShopping()
                    HapticManager.shared.light()
                }) {
                    Image(systemName: isInShoppingList ? "cart.fill" : "cart.badge.plus")
                        .font(.system(size: AppTheme.fontSize16))
                        .foregroundStyle(isInShoppingList ? .green : .secondary)
                }
                .buttonStyle(.plain)
                .disabled(isInShoppingList)
            }
        }
        .padding(.vertical, AppTheme.spacing8)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    private var convertedIngredient: (quantity: Double, unit: String) {
        UnitConversion.convert(
            value: ingredient.scaledQuantity(for: scaleFactor),
            unit: ingredient.unit,
            to: measurementSystem,
            ingredientName: ingredient.name
        )
    }

    private func formatQuantity(_ quantity: Double) -> String {
        FractionFormatter.format(prettyQuantity(quantity))
    }

    // Snaps converted quantities to cooking-sensible precision so conversions don't surface ugly values like "14.79 ml".
    private func prettyQuantity(_ q: Double) -> Double { Self.prettyQuantity(q) }

    /// Nearest of the fractions cooks use — eighths/quarters OR thirds, whichever is closer (⅓ used to become ⅜).
    static func prettyQuantity(_ q: Double) -> Double {
        guard q > 0 else { return q }
        if q >= 100 { return (q / 5).rounded() * 5 }
        if q >= 10 { return q.rounded() }
        let binary = q >= 1 ? (q * 4).rounded() / 4 : (q * 8).rounded() / 8
        let thirds = (q * 3).rounded() / 3
        return abs(thirds - q) < abs(binary - q) ? thirds : binary
    }

    /// "L" (not "l", which reads as "I") and plural cups ("2 cups", not "2 cup").
    static func displayUnit(_ unit: String, quantity: Double) -> String {
        let lower = unit.lowercased()
        if lower == "l" { return "L" }
        if lower == "cup", quantity > 1 { return "cups" }
        return lower
    }
}
