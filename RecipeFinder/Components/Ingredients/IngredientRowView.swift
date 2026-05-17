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
    
    private enum Layout {
        static let dividerWidth: CGFloat = 1
        static let dividerOpacity: Double = 0.2
        static let checkButtonSize: CGFloat = AppTheme.iconSize20
        static let checkButtonFrameWidth: CGFloat = 36
        static let uncheckedOpacity: Double = 0.4
        static let quantityPillOpacity: Double = 0.13
    }

    private enum Timing {
        static let springResponse: Double = 0.3
        static let springDamping: Double = 0.6
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: AppTheme.spacing10) {
                Text(ingredient.mainIngredientName)
                    .font(.body)
                    .fontWeight(.semibold)
                    .strikethrough(isChecked)
                    .foregroundStyle(isChecked ? .secondary : .primary)
                    .fixedSize(horizontal: false, vertical: true)

                if let prepNotes = ingredient.preparationNotes {
                    Text(prepNotes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(action: { onTapQuantity?() }) {
                    HStack(spacing: AppTheme.spacing4) {
                        Text(formatQuantity(convertedIngredient.quantity))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)

                        if !convertedIngredient.unit.isEmpty {
                            Text(convertedIngredient.unit)
                                .font(.caption)
                                .fontWeight(.regular)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, AppTheme.spacing8)
                    .padding(.vertical, AppTheme.spacing4)
                    .background(
                        Capsule()
                            .fill(AppTheme.accentColor.opacity(Layout.quantityPillOpacity))
                    )
                }
                .buttonStyle(.plain)
                .disabled(onTapQuantity == nil)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, AppTheme.spacing10)

            Rectangle()
                .fill(Color.secondary.opacity(Layout.dividerOpacity))
                .frame(width: Layout.dividerWidth)
                .padding(.vertical, AppTheme.spacing6)

            Button(action: {
                HapticManager.shared.light()
                withAnimation(.spring(response: Timing.springResponse, dampingFraction: Timing.springDamping)) {
                    toggle()
                }
            }, label: {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: AppTheme.fontSize22))
                    .foregroundColor(isChecked ? .green : .gray.opacity(Layout.uncheckedOpacity))
                    .frame(width: Layout.checkButtonSize, height: Layout.checkButtonSize)
                    .contentShape(Rectangle())
            })
            .buttonStyle(.plain)
            .frame(width: Layout.checkButtonFrameWidth)
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

