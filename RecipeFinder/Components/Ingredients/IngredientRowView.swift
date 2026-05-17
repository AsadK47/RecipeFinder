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

    private enum Timing {
        static let springResponse: Double = 0.3
        static let springDamping: Double = 0.6
    }

    var body: some View {
        HStack(alignment: .center, spacing: AppTheme.spacing12) {

            // Left: quantity pill (fixed-width anchor so columns line up)
            Button(action: { onTapQuantity?() }) {
                HStack(spacing: 3) {
                    Text(formatQuantity(convertedIngredient.quantity))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(isChecked ? .secondary : .primary)

                    if !convertedIngredient.unit.isEmpty {
                        Text(convertedIngredient.unit.lowercased())
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(minWidth: 52)
                .padding(.horizontal, AppTheme.spacing10)
                .padding(.vertical, AppTheme.spacing8)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius8)
                        .fill(AppTheme.accentColor.opacity(0.13))
                )
            }
            .buttonStyle(.plain)
            .disabled(onTapQuantity == nil)

            // Middle: name + optional prep notes
            VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                Text(ingredient.mainIngredientName)
                    .font(.body)
                    .fontWeight(.semibold)
                    .strikethrough(isChecked)
                    .foregroundStyle(isChecked ? .secondary : .primary)
                    .fixedSize(horizontal: false, vertical: true)

                if let prep = ingredient.preparationNotes {
                    Text(prep)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right: checkbox
            Button(action: {
                HapticManager.shared.light()
                withAnimation(.spring(response: Timing.springResponse, dampingFraction: Timing.springDamping)) {
                    toggle()
                }
            }) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: AppTheme.fontSize22))
                    .foregroundColor(isChecked ? .green : .gray.opacity(0.3))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, AppTheme.spacing8)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .contextMenu {
            if let onAddToShopping {
                Button(action: {
                    onAddToShopping()
                    HapticManager.shared.light()
                }) {
                    Label(
                        isInShoppingList ? "Already in Shopping List" : "Add to Shopping List",
                        systemImage: isInShoppingList ? "checkmark.circle.fill" : "cart.badge.plus"
                    )
                }
                .disabled(isInShoppingList)
            }
        }
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
        FractionFormatter.format(quantity)
    }
}


