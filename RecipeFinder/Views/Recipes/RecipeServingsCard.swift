import SwiftUI

/// Servings display, +/- controls, and quick-scale buttons extracted from `RecipeDetailView`; mutates the bound recipe's servings directly.
struct RecipeServingsCard: View {
    @Binding var recipe: RecipeModel

    var body: some View {
        VStack(spacing: AppTheme.spacing16) {
            HStack {
                servingsDisplay

                Divider()
                    .frame(height: AppTheme.height60)
                    .padding(.horizontal)

                servingsControls
            }

            Divider()
                .background(AppTheme.subtleStroke)

            quickScaleButtons
        }
        .padding()
        .appCard(elevated: true)
    }

    private var servingsDisplay: some View {
        VStack(spacing: AppTheme.spacing8) {
            Image(systemName: "person.2.fill")
                .font(.title2)
                .foregroundStyle(.cyan)
                .accessibilityHidden(true)
            Text("Servings")
                .font(.caption)
                .foregroundStyle(.primary)
                .accessibilityHidden(true)

            HStack(spacing: AppTheme.spacing4) {
                Text("\(recipe.currentServings)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                if recipe.currentServings != recipe.baseServings {
                    // A filled pill (white on accent) stays legible on the light frosted card — the old
                    // low-contrast accent-on-glass text was hard to read.
                    Text(String(format: "%.1fx", recipe.scaleFactor))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppTheme.spacing6)
                        .padding(.vertical, AppTheme.spacing2)
                        .background(Capsule().fill(AppTheme.accentColor))
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Current servings: \(recipe.currentServings)")
            .accessibilityValue(recipe.currentServings != recipe.baseServings ? "Scaled \(String(format: "%.1f", recipe.scaleFactor)) times from base" : "Base servings")
        }
        .frame(maxWidth: .infinity)
    }

    private var servingsControls: some View {
        HStack(spacing: AppTheme.spacing12) {
            servingsButton(icon: "minus", action: decreaseServings, isEnabled: recipe.currentServings > 1)
            servingsButton(icon: "plus", action: increaseServings, isEnabled: true)
        }
        .frame(maxWidth: .infinity)
    }

    private var quickScaleButtons: some View {
        HStack(spacing: AppTheme.spacing8) {
            quickScaleButton(label: "½x", multiplier: 0.5)
            quickScaleButton(label: "1x", multiplier: 1.0)
            quickScaleButton(label: "2x", multiplier: 2.0)
            quickScaleButton(label: "3x", multiplier: 3.0)
        }
        .frame(maxWidth: .infinity)
    }

    private func quickScaleButton(label: String, multiplier: Double) -> some View {
        let targetServings = recipe.servings(scaledBy: multiplier)
        let isActive = recipe.currentServings == targetServings

        return Button(action: {
            HapticManager.shared.light()
            withAnimation(.appSpring) {
                recipe.updateServings(to: targetServings)
            }
        }) {
            Text(label)
                .font(.subheadline)
                .fontWeight(isActive ? .bold : .medium)
                .foregroundStyle(isActive ? .white : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.height36)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius8)
                        .fill(isActive ? AppTheme.accentColor : AppTheme.subtleFill)
                )
        }
        .accessibilityLabel("Scale to \(label)")
        .accessibilityValue(isActive ? "Active" : "Inactive")
        .accessibilityHint("Sets servings to \(targetServings)")
        .accessibilityAddTraits(.isButton)
    }

    private func servingsButton(icon: String, action: @escaping () -> Void, isEnabled: Bool) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: AppTheme.fontSize18, weight: .semibold))
                .adaptiveForegroundColor()
                .frame(width: AppTheme.buttonHeight, height: AppTheme.height44)
                .background(Circle().fill(isEnabled ? AppTheme.accentColor : Color.gray))
        }
        .disabled(!isEnabled)
        .accessibilityLabel(icon == "minus" ? "Decrease servings" : "Increase servings")
        .accessibilityHint(icon == "minus" ? "Reduces serving size by one" : "Increases serving size by one")
        .accessibilityAddTraits(.isButton)
    }

    private func decreaseServings() {
        if recipe.currentServings > 1 {
            HapticManager.shared.light()
            withAnimation(.appSpring) {
                recipe.currentServings -= 1
            }
        }
    }

    private func increaseServings() {
        HapticManager.shared.light()
        withAnimation(.appSpring) {
            recipe.currentServings += 1
        }
    }
}
