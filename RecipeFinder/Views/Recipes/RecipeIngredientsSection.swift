import SwiftUI

/// Collapsible ingredients section extracted from `RecipeDetailView`; all state mutation is delegated through closures.
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
    /// Opens the full recipe editor on the ingredients section (add/remove/reorder).
    let onEditIngredients: () -> Void

    // One-time hint for the non-obvious tap-to-check / tap-amount-to-edit gestures; hidden once seen or anything is checked off.
    @AppStorage("hasSeenIngredientTapHint") private var hasSeenTapHint = false

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
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)   // shrink rather than hyphenate ("Ingredi-ents") beside the header buttons
                        .layoutPriority(1)
                }
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            editButton
            addAllButton
            measurementToggle
            chevronButton
        }
        .padding(.top, AppTheme.spacing24)
    }

    private var editButton: some View {
        Button(action: onEditIngredients) {
            Image(systemName: "pencil")
                .font(.title3)
                .adaptiveForegroundColor()
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Edit ingredients")
        .accessibilityHint("Opens the recipe editor on the ingredients section")
    }

    private var addAllButton: some View {
        Button(action: onAddAllToShopping) {
            Image(systemName: "cart.badge.plus")
                .font(.title3)
                .adaptiveForegroundColor()
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(recipe.ingredients.isEmpty)
        .accessibilityLabel("Add all ingredients to groceries")
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
                .foregroundStyle(AppTheme.adaptiveHighEmphasis(for: colorScheme))
                .rotationEffect(.degrees(isExpanded ? 0 : -90))
                .animation(.spring(response: 0.3), value: isExpanded)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(isExpanded ? "Collapse Ingredients" : "Expand Ingredients")
        .accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand") Ingredients section")
        .accessibilityAddTraits(.isButton)
    }

    private var tapHint: some View {
        HStack(alignment: .top, spacing: AppTheme.spacing8) {
            Image(systemName: "hand.tap")
                .font(.subheadline)
                .foregroundStyle(AppTheme.accentColor)
                .accessibilityHidden(true)
            Text("Tap a name to check it off while cooking · tap its amount to edit.")
                .font(.caption)
                .adaptiveSecondaryForeground()
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: AppTheme.spacing8)
            Button {
                withAnimation { hasSeenTapHint = true }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss tip")
        }
        .padding(AppTheme.spacing12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius8)
                .fill(AppTheme.accentColor.opacity(0.10))
        )
    }

    // Pre-computed once per body so the O(table) substitute scan doesn't run per-row on every re-render.
    private var ingredientsWithSubstitutes: Set<UUID> {
        Set(recipe.ingredients.compactMap { ingredient in
            IngredientSubstituteProvider.substitutes(for: ingredient.name).isEmpty ? nil : ingredient.id
        })
    }

    private var ingredientsList: some View {
        GlassCard {
            VStack(spacing: AppTheme.spacing16) {
                if !hasSeenTapHint && !ingredientsState.contains(true) && !recipe.ingredients.isEmpty {
                    tapHint
                }
                // ingredient.id identity lets SwiftUI diff individual rows, not rebuild all N on every pantry/shopping change.
                let substituteIDs = ingredientsWithSubstitutes
                ForEach(Array(recipe.ingredients.enumerated()), id: \.element.id) { index, ingredient in
                    IngredientRowView(
                        ingredient: ingredient,
                        // Safe read: the parent resizes its state in onChange, which runs after this render sees an edited recipe.
                        isChecked: ingredientsState[safe: index] ?? false,
                        toggle: { onToggleIngredient(index) },
                        scaleFactor: recipe.scaleFactor,
                        measurementSystem: measurementSystem,
                        onAddToShopping: { onAddToShopping(index) },
                        isInShoppingList: isInShoppingList(ingredient),
                        onTapQuantity: { onEditIngredient(index) },
                        onSubstitute: (substituteIDs.contains(ingredient.id) && onSubstitute != nil) ? { onSubstitute?(index) } : nil
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppTheme.spacing24)
        }
    }
}
