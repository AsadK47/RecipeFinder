import SwiftUI

/// "Cook it again" nudge on the home — resurfaces a loved recipe that's gone cold, to pull the user
/// back into the cook loop. Tapping opens the recipe.
struct RediscoveryCard: View {
    let recipe: RecipeModel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.spacing12) {
                IconBadge(systemName: "clock.arrow.circlepath", tint: .purple, diameter: 44, iconSize: AppTheme.fontSize18)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                    Text("Cook it again")
                        .font(.caption)
                        .adaptiveSecondaryForeground()
                    Text("You haven't made \(recipe.name) in a while")
                        .font(.body).fontWeight(.semibold)
                        .adaptiveForegroundColor()
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .adaptiveSecondaryForeground()
                    .accessibilityHidden(true)
            }
            .padding(AppTheme.spacing16)
            .appCard()
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens \(recipe.name)")
    }
}
