import SwiftUI

/// Settings → Data → "iCloud Sync": the opt-in switch (Data safety 2/4) and what it's doing right now. The switch
/// takes effect next launch (`SyncPreference`), so the status line says so instead of pretending it's instant.
struct ICloudSyncSection: View {
    @State private var wanted = SyncPreference.isWanted(in: .shared)
    @State private var hasICloudAccount: Bool?
    private let launchedOn = SyncPreference.isOn(in: .shared)
    private let isSyncing = PersistenceController.shared.isSyncing

    var body: some View {
        let status = SyncStatus(
            wanted: wanted, launchedOn: launchedOn, isSyncing: isSyncing, hasICloudAccount: hasICloudAccount
        )
        VStack(spacing: AppTheme.spacing8) {
            SettingsSectionHeader(title: "iCloud Sync")

            SettingsCard {
                VStack(alignment: .leading, spacing: 0) {
                    SettingsToggleRow(
                        icon: "icloud.fill",
                        iconColor: .blue,
                        title: "Sync with iCloud",
                        subtitle: status.title,
                        isOn: Binding(
                            get: { wanted },
                            set: { newValue in
                                wanted = newValue
                                SyncPreference.setWanted(newValue, in: .shared)
                                HapticManager.shared.light()
                            }
                        )
                    )
                    .accessibilityIdentifier("settings.iCloudSync")

                    Text(status.detail)
                        .font(.subheadline)
                        .adaptiveSecondaryForeground()
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, AppTheme.spacing20)
                        .padding(.bottom, AppTheme.spacing20)
                }
            }
        }
        .task {
            guard isSyncing else { return }
            hasICloudAccount = await CloudSyncStore.hasICloudAccount()
        }
    }
}

#Preview {
    NavigationStack {
        SettingsScreen("Data Management") {
            ICloudSyncSection()
        }
    }
}
