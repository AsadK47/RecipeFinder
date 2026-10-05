import SwiftUI

/// "Cook it again" nudge on the home — resurfaces a loved recipe that's gone cold, to pull the user
/// back into the cook loop. Tapping opens the recipe.
struct RediscoveryCard: View {
    let recipe: RecipeModel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.spacing12) {
                ZStack {
                    Circle().fill(Color.purple.opacity(0.15)).frame(width: 44, height: 44)
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: AppTheme.fontSize18, weight: .semibold))
                        .foregroundStyle(.purple)
                }
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
