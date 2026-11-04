import SwiftUI

// Standard empty-state block (icon, title, message, optional CTA) so empty states stay consistent across screens.
struct EmptyStateView: View {
    let icon: String
    var iconTint: Color?
    let title: String
    let message: String
    var actionTitle: String?
    var actionIcon: String?
    var onAction: (() -> Void)?


    init(
        icon: String,
        iconTint: Color? = nil,
        title: String,
        message: String,
        actionTitle: String? = nil,
        actionIcon: String? = nil,
        onAction: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.iconTint = iconTint
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.actionIcon = actionIcon
        self.onAction = onAction
    }

    var body: some View {
        VStack(spacing: AppTheme.spacing16) {
            Image(systemName: icon)
                .font(.system(size: AppTheme.fontSize60))
                .foregroundStyle(iconTint?.opacity(0.5) ?? AppTheme.textColor(opacity: AppTheme.lowEmphasisOpacity))

            Text(title)
                .font(.title2).fontWeight(.bold)
                .adaptiveForegroundColor()

            Text(message)
                .font(.subheadline)
                .adaptiveSecondaryForeground()
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.spacing32)

            if let actionTitle, let onAction {
                PrimaryButton(actionTitle, systemImage: actionIcon ?? "plus.circle.fill", action: onAction)
            }
        }
        .padding(.top, AppTheme.spacing40)
        .frame(maxWidth: .infinity)
    }
}
