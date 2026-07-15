import SwiftUI
import CoreData

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
        let context = PersistenceController.shared.container.viewContext

        let recipeFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Recipe")
        let recipeBatchDelete = NSBatchDeleteRequest(fetchRequest: recipeFetch)
        _ = try? context.execute(recipeBatchDelete)
        _ = try? context.save()

        KitchenInventoryManager.shared.clearAll()
        ShoppingListManager.shared.clearAllItems()

        let defaults = UserDefaults.standard
        if let domain = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: domain)
            defaults.synchronize()
        }

        defaults.set("Teal", forKey: "appTheme")
        defaults.set("Frost Light", forKey: "cardStyle")
        defaults.set("metric", forKey: "measurementSystem")

        PersistenceController.shared.populateDatabase()

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
