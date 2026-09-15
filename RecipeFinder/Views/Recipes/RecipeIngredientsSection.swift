import SwiftUI

/// The collapsible ingredients section on the recipe detail screen: the header
/// with a measurement toggle, and the checklist of ingredient rows. Extracted
/// from `RecipeDetailView`; all state mutation is delegated through closures.
struct RecipeIngredientsSection: View {
    let recipe: RecipeModel
    let ingredientsState: [Bool]
    let measurementSystem: MeasurementSystem
    let isExpanded: Bool
    let colorScheme: ColorScheme
    let onToggleSection: () -> Void
    let onToggleMeasurement: () -> Void
    let onToggleIngredient: (Int) -> Void
    let onAddToShopping: (Int) -> Void
    let onAddAllToShopping: () -> Void
    let isInShoppingList: (Ingredient) -> Bool
    let onEditIngredient: (Int) -> Void
    let onSubstitute: ((Int) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            header

            if isExpanded {
                ingredientsList
                    .transition(.asymmetric(
                        insertion: .scale(scale: AppTheme.transitionScaleDown).combined(with: .opacity),
                        removal: .scale(scale: AppTheme.transitionScaleDown).combined(with: .opacity)
                    ))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppTheme.spacing20)
    }

    private var header: some View {
        HStack(spacing: AppTheme.spacing8) {
            Button(action: onToggleSection) {
                HStack(spacing: AppTheme.spacing8) {
                    Image(systemName: "leaf.fill")
                        .adaptiveForegroundColor()
                        .font(.title3)
                    Text("Ingredients")
                        .font(.title2)
                        .fontWeight(.bold)
                        .adaptiveForegroundColor()
                }
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            addAllButton
            measurementToggle
            chevronButton
        }
        .padding(.top, AppTheme.spacing24)
    }

    private var addAllButton: some View {
        Button(action: onAddAllToShopping) {
            Image(systemName: "cart.badge.plus")
                .font(.title3)
                .adaptiveForegroundColor()
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(recipe.ingredients.isEmpty)
        .accessibilityLabel("Add all ingredients to shopping list")
        .accessibilityHint("Adds every ingredient from this recipe in one tap")
    }

    private var measurementToggle: some View {
        Button(action: onToggleMeasurement) {
            HStack(spacing: AppTheme.spacing6) {
                Image(systemName: measurementSystem.icon)
                    .font(.caption)
                Text(measurementSystem.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .adaptiveForegroundColor()
            .padding(.horizontal, AppTheme.spacing12)
            .padding(.vertical, AppTheme.spacing6)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius8)
                    .fill(colorScheme == .dark ? Color.white.opacity(AppTheme.overlayLightOpacity) : Color.black.opacity(AppTheme.dividerOpacity))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Measurement system")
        .accessibilityValue(measurementSystem.rawValue)
        .accessibilityHint("Double tap to switch between metric and imperial units")
    }

    private var chevronButton: some View {
        Button(action: onToggleSection) {
            Image(systemName: "chevron.down")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.adaptiveHighEmphasis(for: colorScheme))
                .rotationEffect(.degrees(isExpanded ? 0 : -90))
                .animation(.spring(response: 0.3), value: isExpanded)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(isExpanded ? "Collapse Ingredients" : "Expand Ingredients")
        .accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand") Ingredients section")
        .accessibilityAddTraits(.isButton)
    }

    private var ingredientsList: some View {
        GlassCard {
            VStack(spacing: AppTheme.spacing16) {
                ForEach(recipe.ingredients.indices, id: \.self) { index in
                    let ingredient = recipe.ingredients[index]
                    let hasSubstitutes = !IngredientSubstituteProvider.substitutes(for: ingredient.name).isEmpty
                    IngredientRowView(
                        ingredient: ingredient,
                        isChecked: ingredientsState[index],
                        toggle: { onToggleIngredient(index) },
                        scaleFactor: recipe.scaleFactor,
                        measurementSystem: measurementSystem,
                        onAddToShopping: { onAddToShopping(index) },
                        isInShoppingList: isInShoppingList(ingredient),
                        onTapQuantity: { onEditIngredient(index) },
                        onSubstitute: (hasSubstitutes && onSubstitute != nil) ? { onSubstitute?(index) } : nil
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppTheme.spacing24)
        }
    }
}
