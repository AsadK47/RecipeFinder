import SwiftUI

// Shared chrome for the Recipe Wizard steps, extracted from `RecipeWizardView`.

/// Plain section heading (title/subtitle/illustration) — the editor is one scrollable form, so there's no "Step X of Y".
struct WizardStepHeader: View {
    let title: String
    let subtitle: String
    let illustration: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            HStack(alignment: .top, spacing: AppTheme.spacing12) {
                VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .adaptiveForegroundColor()

                    Text(subtitle)
                        .font(.subheadline)
                        .adaptiveForegroundColor(opacity: AppTheme.veryHighEmphasisOpacity)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: illustration)
                    .font(.system(size: AppTheme.fontSize42, weight: .medium))
                    .adaptiveForegroundColor(opacity: AppTheme.mediumEmphasisOpacity)
                    .padding(.top, AppTheme.spacing2)
            }
        }
    }
}

/// Card surface for each wizard section; delegates to `.appCard()` so it matches every other card (and respects solid/frosted) instead of hand-rolling a fill.
struct WizardCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content().appCard()
    }
}

/// A single labelled row in the recipe summary on the final step.
struct WizardSummaryRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: AppTheme.spacing12) {
            Image(systemName: icon)
                .adaptiveForegroundColor()
                .frame(width: AppTheme.iconSize20)

            Text(label)
                .adaptiveSecondaryForeground()

            Spacer()

            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}
