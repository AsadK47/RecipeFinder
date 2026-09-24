import SwiftUI

/// Shared chrome for the Recipe Wizard steps, extracted from `RecipeWizardView`
/// so each step can live in its own file.

/// The title/subtitle/illustration header shown at the top of each wizard
/// section. Renders as a plain section heading — the recipe editor is a single
/// scrollable form, so there is no "Step X of Y" stepping.
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

/// The card surface around each wizard section. Delegates to the app-wide
/// `.appCard()` token so the wizard matches every other card in the app (and
/// respects the solid/frosted setting) instead of hand-rolling its own fill.
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
