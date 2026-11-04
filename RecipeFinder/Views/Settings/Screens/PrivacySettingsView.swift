import SwiftUI

/// Privacy policy access.
struct PrivacySettingsView: View {
    @State private var showPrivacyPolicy = false

    var body: some View {
        SettingsScreen("Privacy") {
            SettingsSection(title: "Policies", items: [
                .init(
                    row: SettingsRow(icon: "hand.raised.fill", iconColor: .blue, title: "Privacy Policy", subtitle: "View our privacy and data practices"),
                    action: {
                        showPrivacyPolicy = true
                        HapticManager.shared.light()
                    }
                )
            ])
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
    }
}

struct PrivacyInfoRow: View {
    let icon: String
    var iconColor: Color = .green
    let title: String
    let description: String

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.spacing16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(AppTheme.cardDarkOpacity))
                    .frame(width: 40, height: AppTheme.height40)

                Image(systemName: icon)
                    .font(.system(size: AppTheme.fontSize18, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .adaptiveForegroundColor()

                Text(description)
                    .font(.caption)
                    .adaptiveSecondaryForeground()
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    NavigationStack {
        PrivacySettingsView()
    }
}
