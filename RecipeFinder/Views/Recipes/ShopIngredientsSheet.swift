import SwiftUI

/// "Shop" sheet: every ingredient starts ticked (smart default), so adding a recipe's shopping is one tap
/// plus unticking whatever is already in the cupboard — instead of all-or-nothing or one row at a time.
struct ShopIngredientsSheet: View {
    let recipe: RecipeModel
    let measurementSystem: MeasurementSystem
    let onAdd: ([Ingredient]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selected: Set<Int>

    init(recipe: RecipeModel, measurementSystem: MeasurementSystem, onAdd: @escaping ([Ingredient]) -> Void) {
        self.recipe = recipe
        self.measurementSystem = measurementSystem
        self.onAdd = onAdd
        _selected = State(initialValue: Set(recipe.ingredients.indices))
    }

    var body: some View {
        VStack(spacing: AppTheme.spacing12) {
            Text("Untick anything you already have.")
                .font(.subheadline)
                .adaptiveSecondaryForeground()
                .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView {
                VStack(spacing: AppTheme.spacing8) {
                    ForEach(recipe.ingredients.indices, id: \.self) { index in
                        row(index)
                    }
                }
            }

            PrimaryButton(
                selected.isEmpty ? "Nothing selected" : "Add \(selected.count) to Groceries",
                systemImage: "cart.badge.plus",
                fillWidth: true
            ) {
                onAdd(selected.sorted().map { recipe.ingredients[$0] })
                dismiss()
            }
            .disabled(selected.isEmpty)
            .opacity(selected.isEmpty ? AppTheme.glassLightOpacity : 1)
            .accessibilityIdentifier("shop.confirm")
        }
        .padding(AppTheme.spacing20)
        .sheetScaffold("Add to Groceries")
        .sheetDismissButton("Cancel", placement: .cancellationAction)
        .presentationDetents([.medium, .large])
    }

    private func row(_ index: Int) -> some View {
        let ingredient = recipe.ingredients[index]
        let isOn = selected.contains(index)
        let amount = IngredientRowView.amount(for: ingredient, scaleFactor: recipe.scaleFactor, system: measurementSystem)
        let qty = [amount.quantity, amount.unit].compactMap { $0 }.joined(separator: " ")
        return Button {
            if isOn { selected.remove(index) } else { selected.insert(index) }
            HapticManager.shared.selection()
        } label: {
            HStack(spacing: AppTheme.spacing12) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isOn ? AppTheme.accentColor : Color.secondary)
                Text(qty.isEmpty ? ingredient.displayName : "\(qty) \(ingredient.displayName)")
                    .font(.body)
                    .adaptiveForegroundColor()
                    .opacity(isOn ? 1 : 0.5)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, AppTheme.spacing10)
            .padding(.horizontal, AppTheme.spacing16)
            .appCard()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
