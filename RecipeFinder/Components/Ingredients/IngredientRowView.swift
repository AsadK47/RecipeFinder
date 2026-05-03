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
            VStack(alignment: .leading, spacing: 10) {
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
                    HStack(spacing: 4) {
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

            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 1)
                .padding(.vertical, 6)

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

