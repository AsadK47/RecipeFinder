import SwiftUI

// Pieces of `CookingModeView`, split out so the screen reads as layout + state only.

/// Thin bar across the top: how far through the cook you are.
struct CookingProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(.white.opacity(0.2))
                    .frame(height: 4)
                RoundedRectangle(cornerRadius: 2)
                    .fill(.white.opacity(0.85))
                    .frame(width: geo.size.width * CGFloat(progress), height: 4)
                    .animation(.appGentle, value: progress)
            }
        }
        .frame(height: 4)
        .padding(.top, AppTheme.spacing8)
        .padding(.bottom, AppTheme.spacing16)
    }
}

/// First screen of a cook: tap each ingredient off as you gather it.
struct CookingIngredientChecklist: View {
    let recipe: RecipeModel
    @Binding var completed: Set<Int>
    @AppStorage("measurementSystem") private var measurementSystem: MeasurementSystem = .metric

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                Text("Gather your ingredients")
                    .font(.title2.weight(.bold))
                    .adaptiveForegroundColor()
                    .padding(.bottom, AppTheme.spacing8)

                ForEach(recipe.ingredients.indices, id: \.self) { i in
                    row(i)
                }
            }
            .padding(.vertical, AppTheme.spacing8)
        }
    }

    private func row(_ i: Int) -> some View {
        let isChecked = completed.contains(i)
        return Button {
            withAnimation(.appSnappy) {
                if isChecked { completed.remove(i) } else { completed.insert(i) }
            }
            HapticManager.shared.selection()
        } label: {
            HStack(spacing: AppTheme.spacing16) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isChecked ? .green : .white.opacity(0.6))
                    .frame(width: AppTheme.iconSize28)

                Text(IngredientLineText.line(for: recipe.ingredients[i], scaleFactor: recipe.scaleFactor, system: measurementSystem))
                    .font(.body)
                    .adaptiveForegroundColor()
                    .strikethrough(isChecked, color: .secondary)
                    .opacity(isChecked ? 0.5 : 1)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, AppTheme.spacing10)
            .padding(.horizontal, AppTheme.spacing16)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius10)
                    .fill(.white.opacity(isChecked ? 0.05 : 0.1))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Back / Next (or Finish on the last item) along the bottom.
struct CookingNavigationRow: View {
    let isFirst: Bool
    let isLast: Bool
    let onBack: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.spacing16) {
            if !isFirst {
                Button(action: onBack) {
                    HStack(spacing: AppTheme.spacing8) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.body.weight(.semibold))
                    .adaptiveForegroundColor()
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(RoundedRectangle(cornerRadius: AppTheme.cornerRadius12).fill(.ultraThinMaterial))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("cooking.back")
            }

            Button(action: onNext) {
                HStack(spacing: AppTheme.spacing8) {
                    Text(isLast ? "Finish" : "Next")
                    if !isLast { Image(systemName: "chevron.right") }
                    if isLast  { Image(systemName: "checkmark") }
                }
                .font(.body.weight(.semibold))
                .adaptiveForegroundColor()
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                        .fill(isLast ? Color.green.opacity(0.4) : AppTheme.accentColor.opacity(0.35))
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("cooking.next")
        }
        .padding(.top, AppTheme.spacing16)
    }
}

/// Finishing a recipe already cooked today: no Made it sheet to close into (one cook a day), so say so here.
struct CookingFinishedCard: View {
    let recipeName: String
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.spacing20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)
                .accessibilityHidden(true)

            VStack(spacing: AppTheme.spacing8) {
                Text("Nice cooking!")
                    .font(.title.weight(.bold))
                    .adaptiveForegroundColor()
                Text("\(recipeName) is already in today's cooks.")
                    .font(.body)
                    .adaptiveSecondaryForeground()
                    .multilineTextAlignment(.center)
            }

            PrimaryButton("Done", systemImage: "checkmark", fillWidth: true, action: onDone)
                .padding(.top, AppTheme.spacing8)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("cooking.finished")
    }
}

/// Under a step: the ingredients it uses, so the cook needn't flip back to the list. Amounts are the recipe's,
/// left off where the step sets its own ("1 tbsp oil", "the remaining oil").
struct CookingStepIngredients: View {
    let uses: [StepIngredientMatcher.Use]
    let ingredients: [Ingredient]
    let scaleFactor: Double
    @AppStorage("measurementSystem") private var measurementSystem: MeasurementSystem = .metric

    /// One line per use: "200 g butter", or just "Oil" when the step gives its own amount.
    static func lines(for uses: [StepIngredientMatcher.Use], in ingredients: [Ingredient], scaleFactor: Double,
                      system: MeasurementSystem) -> [String] {
        uses.compactMap { use in
            guard ingredients.indices.contains(use.index) else { return nil }
            let ingredient = ingredients[use.index]
            return use.stepGivesAmount
                ? ingredient.displayName
                : IngredientLineText.line(for: ingredient, scaleFactor: scaleFactor, system: system)
        }
    }

    var body: some View {
        let lines = Self.lines(for: uses, in: ingredients, scaleFactor: scaleFactor, system: measurementSystem)
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            Text("Ingredients in this step")
                .font(.subheadline.weight(.semibold))
                .adaptiveSecondaryForeground()
            ForEach(lines.indices, id: \.self) { i in
                HStack(alignment: .firstTextBaseline, spacing: AppTheme.spacing10) {
                    Circle()
                        .fill(.white.opacity(0.6))
                        .frame(width: 6, height: 6)
                        .accessibilityHidden(true)
                    Text(lines[i])
                        .font(.body)
                        .adaptiveForegroundColor()
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(AppTheme.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: AppTheme.cornerRadius16).fill(.white.opacity(0.08)))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("cooking.stepIngredients")
    }
}
