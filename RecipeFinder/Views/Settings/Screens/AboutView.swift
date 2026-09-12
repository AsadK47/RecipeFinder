import SwiftUI

/// App identity, version details, and support contact.
struct AboutView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    var body: some View {
        SettingsScreen("About") {
            VStack(spacing: AppTheme.spacing16) {
                Image(systemName: "book.circle.fill")
                    .font(.system(size: AppTheme.fontSize80))
                    .foregroundColor(AppTheme.accentColor(for: appTheme))

                Text("RecipeFinder")
                    .font(.system(size: AppTheme.fontSize32, weight: .bold))
                    .adaptiveForegroundColor()

                Text("Your Personal Cooking Companion")
                    .font(.subheadline)
                    .adaptiveForegroundColor(opacity: AppTheme.highEmphasisOpacity)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, AppTheme.spacing20)
            .padding(.bottom, AppTheme.spacing16)

            SettingsCard {
                VStack(spacing: AppTheme.spacing16) {
                    HStack {
                        Text("Version")
                            .adaptiveSecondaryForeground()
                        Spacer()
                        Text(appVersion)
                            .fontWeight(.medium)
                            .adaptiveForegroundColor()
                    }

                    Divider()

                    HStack {
                        Text("Build")
                            .adaptiveSecondaryForeground()
                        Spacer()
                        Text(buildNumber)
                            .fontWeight(.medium)
                            .adaptiveForegroundColor()
                    }
                }
                .padding(AppTheme.spacing20)
            }

            VStack(spacing: AppTheme.spacing8) {
                SettingsSectionHeader(title: "Legal Information")

                SettingsCard {
                    VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                            Text("© 2025 RecipeFinder")
                                .font(.subheadline)
                                .adaptiveSecondaryForeground()

                            Text("All rights reserved")
                                .font(.caption)
                                .adaptiveSecondaryForeground()
                        }

                        Divider()

                        Text("For Terms of Service and Privacy Policy, please visit the Legal Information section in Settings.")
                            .font(.caption)
                            .adaptiveSecondaryForeground()
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(AppTheme.spacing20)
                }
            }

            SettingsSection(title: "Support", items: [
                .init(
                    row: SettingsRow(icon: "envelope.fill", iconColor: .teal, title: "Email Support", subtitle: "recipefinderlimited@icloud.com", accessory: .externalLink),
                    action: {
                        if let url = URL(string: "mailto:recipefinderlimited@icloud.com") {
                            UIApplication.shared.open(url)
                        }
                    }
                )
            ])

            Text("Made with ❤️ for home cooks")
                .font(.caption)
                .adaptiveForegroundColor(opacity: AppTheme.mediumEmphasisOpacity)
                .padding(.top, AppTheme.spacing16)
        }
    }
}

struct AboutFeatureRow: View {
    let icon: String
    let text: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: AppTheme.spacing12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: AppTheme.iconSize20)

            Text(text)
                .font(.subheadline)
                .foregroundColor(AppTheme.adaptiveEmphasis(for: colorScheme, level: AppTheme.cardLightOpacity))
        }
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
