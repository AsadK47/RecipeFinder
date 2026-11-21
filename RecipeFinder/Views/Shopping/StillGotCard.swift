import SwiftUI

/// Groceries' "Still got the coriander?" card: one quick question about something the plan counts on that's been At
/// home a while. Either answer settles it in one tap; the plan's card stays the screen's primary action.
struct StillGotCard: View {
    let question: StillGotCheck.Question
    let onYes: () -> Void
    let onNo: () -> Void
    /// Not sure right now (e.g. in the shop): hides this question until the app restarts.
    let onLater: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            HStack(spacing: AppTheme.spacing12) {
                IconBadge(systemName: "questionmark.circle", tint: AppTheme.accentColor, diameter: 40)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                    Text(question.title)
                        .font(.headline)
                        .adaptiveForegroundColor()
                    Text(question.detail)
                        .font(.subheadline)
                        .adaptiveSecondaryForeground()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button(action: onLater) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .adaptiveSecondaryForeground()
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Ask me later")
                .accessibilityIdentifier("groceries.stillGot.later")
            }
            HStack(spacing: AppTheme.spacing8) {
                PrimaryButton("Yes, got it", systemImage: "checkmark", fillWidth: true, variant: .secondary, action: onYes)
                    .accessibilityHint("Keeps it At home")
                    .accessibilityIdentifier("groceries.stillGot.yes")
                PrimaryButton("No, add it", systemImage: "cart.badge.plus", fillWidth: true, variant: .secondary, action: onNo)
                    .accessibilityHint("Takes it off At home and adds it to your list")
                    .accessibilityIdentifier("groceries.stillGot.no")
            }
        }
        .padding()
        .appCard()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("groceries.stillGot")
    }
}
