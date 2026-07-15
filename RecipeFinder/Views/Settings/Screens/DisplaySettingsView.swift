import SwiftUI

/// Screen behavior options for hands-busy cooking.
struct DisplaySettingsView: View {
    @AppStorage("keepScreenAwake") private var keepScreenAwake: Bool = false

    var body: some View {
        SettingsScreen("Display") {
            VStack(spacing: AppTheme.spacing8) {
                SettingsSectionHeader(title: "Screen")

                SettingsCard {
                    SettingsToggleRow(
                        icon: "light.max",
                        iconColor: .yellow,
                        title: "Keep Screen Awake",
                        subtitle: "Prevent screen from dimming while cooking",
                        isOn: $keepScreenAwake
                    )
                }
            }

            SettingsCard {
                VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                    HStack(spacing: AppTheme.spacing12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title3)

                        Text("About This Setting")
                            .font(.headline)
                            .adaptiveForegroundColor()
                    }

                    Text("When enabled, your screen will stay on while you're viewing recipes or using timers. This is helpful when cooking and you need to reference instructions without constantly touching your device.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()
                        .padding(.vertical, AppTheme.spacing4)

                    HStack(spacing: AppTheme.spacing8) {
                        Image(systemName: "battery.100")
                            .foregroundColor(.green)
                            .font(.caption)

                        Text("Note: Keeping the screen on may use more battery")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(AppTheme.spacing20)
            }
        }
    }
}

#Preview {
    NavigationStack {
        DisplaySettingsView()
    }
}
