import SwiftUI

/// Collapsible ingredients section extracted from `RecipeDetailView`; all state mutation is delegated through closures.
struct RecipeIngredientsSection: View {
    let recipe: RecipeModel
    let ingredientsState: [Bool]
    let measurementSystem: MeasurementSystem
    let isExpanded: Bool
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
    /// Non-nil only where the on-device model can run: offers "Estimate amounts" alongside typing them in.
    var onEstimateAmounts: (() -> Void)? = nil

    /// Offers cooking mode once every ingredient is ticked; nil hides the prompt.
    var onStartCooking: (() -> Void)? = nil
    /// Pulses the first circle (shows rows can be ticked) until the cook has ticked a row once.
    var hasTickedBefore: Bool = true

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
                    .fill(AppTheme.adaptive(light: Color.black.opacity(AppTheme.dividerOpacity), dark: Color.white.opacity(AppTheme.overlayLightOpacity)))
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
                .foregroundStyle(AppTheme.adaptiveHighEmphasis)
                .rotationEffect(.degrees(isExpanded ? 0 : -90))
                .animation(.appSpring, value: isExpanded)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(isExpanded ? "Collapse Ingredients" : "Expand Ingredients")
        .accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand") Ingredients section")
        .accessibilityAddTraits(.isButton)
    }

    /// Every ingredient ticked: the natural moment to start cooking.
    private func allSetPrompt(_ onStartCooking: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("All set — start cooking?")
                .font(.headline)
                .adaptiveForegroundColor()
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton("Start cooking", systemImage: "frying.pan.fill", fillWidth: true, action: onStartCooking)
                .accessibilityIdentifier("recipe.ingredients.startCooking")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.spacing12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius8)
                .fill(AppTheme.accentColor.opacity(0.10))
        )
        .transition(.opacity.combined(with: .scale(scale: AppTheme.transitionScaleDown)))
    }

    private func gotItHeader(count: Int) -> some View {
        HStack(spacing: AppTheme.spacing6) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.accentColor)
                .accessibilityHidden(true)
            Text("Got it")
                .font(.headline)
                .adaptiveForegroundColor()
            Text("\(count)")
                .font(.subheadline.weight(.semibold))
                .adaptiveSecondaryForeground()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, AppTheme.spacing8)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier("recipe.ingredients.gotIt")
    }

    /// Shown when most ingredients have no amount (e.g. a recipe imported from a caption that never listed them).
    private var missingAmountsCard: some View {
        HStack(alignment: .top, spacing: AppTheme.spacing8) {
            Image(systemName: "scalemass")
                .font(.subheadline)
                .foregroundStyle(AppTheme.accentColor)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: AppTheme.spacing6) {
                Text("This recipe didn't list most amounts.")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .adaptiveForegroundColor()
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: AppTheme.spacing16) {
                    if let onEstimateAmounts {
                        Button("Estimate amounts", action: onEstimateAmounts)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.accentColor)
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("recipe.estimateAmounts")
                    }
                    Button("Add your amounts", action: onEditIngredients)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.accentColor)
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("recipe.addAmounts")
                }
            }
            Spacer(minLength: 0)
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
        VStack(spacing: AppTheme.spacing16) {
            if IngredientAmountGaps.isMostlyMissing(recipe.ingredients) {
                missingAmountsCard
            }
            let ingredients = recipe.ingredients
            if let onStartCooking, IngredientChecklist.isAllSet(count: ingredients.count, ticked: ingredientsState) {
                allSetPrompt(onStartCooking)
            }
            // Stable entry ids let SwiftUI slide a ticked row down into "Got it" instead of rebuilding the list.
            let substituteIDs = ingredientsWithSubstitutes
            let pulseIndex = IngredientChecklist.pulseIndex(count: ingredients.count, hasTickedBefore: hasTickedBefore)
            ForEach(IngredientChecklist.entries(sections: ingredients.map(\.section), ticked: ingredientsState)) { entry in
                switch entry {
                case .groupTitle(let title, _):
                    IngredientGroupHeader(title: title)
                case .gotItTitle(let count):
                    gotItHeader(count: count)
                case .row(let index, let isTicked):
                    if let ingredient = ingredients[safe: index] {
                        IngredientRowView(
                            ingredient: ingredient,
                            isChecked: isTicked,
                            toggle: { onToggleIngredient(index) },
                            scaleFactor: recipe.scaleFactor,
                            measurementSystem: measurementSystem,
                            onAddToShopping: { onAddToShopping(index) },
                            isInShoppingList: isInShoppingList(ingredient),
                            onTapQuantity: { onEditIngredient(index) },
                            onSubstitute: (substituteIDs.contains(ingredient.id) && onSubstitute != nil)
                                ? { onSubstitute?(index) } : nil,
                            pulses: pulseIndex == index
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.spacing24)
        .appCard(elevated: true)
    }
}

/// A group title ("For the sauce") above the ingredients in that group — on the recipe and on the add/review screen.
struct IngredientGroupHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline)
            .adaptiveForegroundColor()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, AppTheme.spacing8)
            .accessibilityAddTraits(.isHeader)
    }
}
