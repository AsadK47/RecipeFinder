import SwiftUI

/// Appearance mode picker (system / light / dark). Each mode applies its
/// matching card style automatically.
struct AppearanceSettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        SettingsScreen("Appearance") {
            VStack(spacing: AppTheme.spacing8) {
                SettingsSectionHeader(title: "Appearance Mode")

                SettingsCard {
                    VStack(spacing: 0) {
                        SettingsChoiceRow(
                            icon: "circle.lefthalf.filled",
                            iconColor: .indigo,
                            title: "System",
                            subtitle: "Follows device settings — currently \(colorScheme == .dark ? "Ember Dark" : "Frost Light")",
                            isSelected: appearanceMode == .system
                        ) {
                            appearanceMode = .system
                        }

                        SettingsRowDivider()

                        SettingsChoiceRow(
                            icon: "sparkles",
                            iconColor: .cyan,
                            title: "Frost Light",
                            subtitle: "Translucent frosted glass cards",
                            isSelected: appearanceMode == .light
                        ) {
                            appearanceMode = .light
                        }

                        SettingsRowDivider()

                        SettingsChoiceRow(
                            icon: "flame.fill",
                            iconColor: .orange,
                            title: "Ember Dark",
                            subtitle: "Solid dark cards",
                            isSelected: appearanceMode == .dark
                        ) {
                            appearanceMode = .dark
                        }
                    }
                }
            }
        }
        .onChange(of: appearanceMode) { _, newMode in
            switch newMode {
            case .system:
                cardStyle = colorScheme == .dark ? .solid : .frosted
            case .light:
                cardStyle = .frosted
            case .dark:
                cardStyle = .solid
            }
        }
    }
}

#Preview {
    NavigationStack {
        AppearanceSettingsView()
    }
}
