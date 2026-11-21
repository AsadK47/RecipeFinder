import SwiftUI

/// Groceries' "Still got the coriander?" card: one quick question about something the plan counts on that's been At
/// home a while. Either answer settles it in one tap; the plan's card stays the screen's primary action.
struct StillGotCard: View {
    let question: StillGotCheck.Question
    let onYes: () -> Void
    let onNo: () -> Void

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
            }
            .accessibilityElement(children: .combine)
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
        .accessibilityIdentifier("groceries.stillGot")
    }
}
