import SwiftUI

/// Factory reset and destructive-action confirmation preferences.
struct DataManagementSettingsView: View {
    @State private var showingResetAlert = false
    @State private var dataCleared = false
    @AppStorage("skipRecipeDeleteConfirmation") private var skipDeleteConfirmation: Bool = false

    var body: some View {
        SettingsScreen("Data Management") {
            VStack(spacing: AppTheme.spacing8) {
                SettingsSectionHeader(title: "Reset")

                SettingsCard {
                    VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                        HStack(spacing: AppTheme.spacing12) {
                            SettingsIconTile(systemName: "exclamationmark.triangle.fill", color: .orange)

                            VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                                Text("Reset App to Default")
                                    .font(.body)
                                    .adaptiveForegroundColor()

                                Text("Use this option if something goes wrong")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Text("This will reset the app to its initial state, clearing all your data and restoring default settings with sample recipes. Use this if you encounter issues or want a fresh start.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Button(action: {
                            showingResetAlert = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.body)
                                Text("Reset to Default")
                                    .font(.body)
                                    .fontWeight(.semibold)
                            }
                            .adaptiveForegroundColor()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.spacing12)
                            .background(Color.orange)
                            .cornerRadius(AppTheme.cornerRadius12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(AppTheme.spacing20)
                }
            }

            VStack(spacing: AppTheme.spacing8) {
                SettingsSectionHeader(title: "Delete Confirmations")

                SettingsCard {
                    SettingsToggleRow(
                        icon: "trash.fill",
                        iconColor: .red,
                        title: "Ask before deleting recipes",
                        subtitle: skipDeleteConfirmation ? "Recipes delete immediately on swipe" : "You'll be asked to confirm first",
                        isOn: Binding(
                            get: { !skipDeleteConfirmation },
                            set: { skipDeleteConfirmation = !$0 }
                        )
                    )
                }
            }

            if dataCleared {
                HStack(spacing: AppTheme.spacing8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Data cleared successfully")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.3), value: dataCleared)
        .alert("Reset to Default", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetToDefault()
            }
        } message: {
            Text("This will reset the app to factory defaults, clearing all your data and restoring sample recipes. Use this if you encounter any issues. This action cannot be undone!")
        }
    }

    private func resetToDefault() {
        // Scope the wipe to the signed-in user — a batch delete with no predicate
        // (the previous implementation) also erased other accounts' recipes, and
        // wiping the whole UserDefaults domain desynced the in-memory auth/scope
        // state and left populateDatabase() unable to repopulate.
        PersistenceController.shared.clearAllRecipes()
        UserScopedStorage.shared.clearCurrentUserData()

        // Appearance settings are app-wide (global @AppStorage) — restore defaults.
        let defaults = UserDefaults.standard
        defaults.set("Teal", forKey: "appTheme")
        defaults.set("Frost Light", forKey: "cardStyle")
        defaults.set("metric", forKey: "measurementSystem")

        // currentUserId is still set, so this repopulates the sample recipes.
        PersistenceController.shared.populateDatabase()
        UserScopedStorage.shared.set(true, forKey: Constants.UserDefaultsKeys.hasPopulatedDatabase)

        // Refresh in-memory managers so the UI reflects the reset immediately.
        ShoppingListManager.shared.reloadForCurrentUser()
        KitchenInventoryManager.shared.reloadForCurrentUser()
        MealPlanningManager.shared.reloadForCurrentUser()
        NotesManager.shared.reloadForCurrentUser()
        AccountManager.shared.loadProfile()
        AccountManager.shared.updateStats()

        dataCleared = true
        HapticManager.shared.success()

        DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.animationDelayFeedback) {
            dataCleared = false
        }
    }
}

#Preview {
    NavigationStack {
        DataManagementSettingsView()
    }
}
