import SwiftUI

/// Shared chrome for the Recipe Wizard steps, extracted from `RecipeWizardView`
/// so each step can live in its own file.

/// The title/subtitle/illustration header shown at the top of every wizard step.
struct WizardStepHeader: View {
    let title: String
    let subtitle: String
    let stepNumber: Int
    let totalSteps: Int
    let illustration: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("Step \(stepNumber) of \(totalSteps)")
                .font(.caption)
                .fontWeight(.medium)
                .adaptiveForegroundColor(opacity: AppTheme.highEmphasisOpacity)

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

/// The card background wrapper used around each step's content.
struct WizardCard<Content: View>: View {
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    @ViewBuilder let content: () -> Content

    var body: some View {
        Group {
            if cardStyle == .solid {
                content()
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                            .fill(colorScheme == .dark ? Color(white: AppTheme.cardDarkOpacity) : .white)
                    )
            } else {
                content()
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                            .fill(.ultraThinMaterial)
                    )
            }
        }
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
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}
