import SwiftUI

/// Factory reset and destructive-action confirmation preferences.
struct DataManagementSettingsView: View {
    @Environment(\.recipeStore) private var recipeStore
    @Environment(\.auth) private var auth
    @State private var showingResetAlert = false
    @State private var dataCleared = false
    @AppStorage("skipRecipeDeleteConfirmation") private var skipDeleteConfirmation: Bool = false

    @State private var isExporting = false
    @State private var isImporting = false
    @State private var exportDocument: BackupDocument?
    @State private var backupMessage: String?
    @State private var backupMessageIsError = false

    // On-device import availability, read on appear.
    @State private var importStatus: OnDeviceRecipeImportStatus = .unknown

    var body: some View {
        SettingsScreen("Data Management") {
            backupSection

            onDeviceImportSection

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
                                    .adaptiveSecondaryForeground()
                            }
                        }

                        Text("This will reset the app to its initial state, clearing all your data and restoring default settings with sample recipes. Use this if you encounter issues or want a fresh start.")
                            .font(.subheadline)
                            .adaptiveSecondaryForeground()
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
                            .background(AppTheme.warning)
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
                    Text("Data cleared successfully")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, AppTheme.spacing12)
                .padding(.vertical, AppTheme.spacing6)
                .background(Capsule().fill(.green))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if let backupMessage {
                HStack(spacing: AppTheme.spacing8) {
                    Image(systemName: backupMessageIsError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(backupMessageIsError ? .orange : .green)
                    Text(backupMessage)
                        .font(.caption)
                        .foregroundStyle(backupMessageIsError ? .orange : .green)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.3), value: dataCleared)
        .animation(.spring(response: 0.3), value: backupMessage)
        .onAppear { importStatus = OnDeviceRecipeImport.currentStatus() }
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: BackupDocument.backupType,
            defaultFilename: Self.defaultBackupFilename()
        ) { result in
            if case .failure = result {
                showBackupMessage("Couldn't save the backup.", isError: true)
            } else {
                showBackupMessage("Backup saved.", isError: false)
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [BackupDocument.backupType, .json]
        ) { result in
            switch result {
            case let .success(url):
                importBackup(from: url)
            case .failure:
                showBackupMessage("Couldn't open that file.", isError: true)
            }
        }
        .alert("Reset to Default", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetToDefault()
            }
        } message: {
            Text("This will reset the app to factory defaults, clearing all your data and restoring sample recipes. Use this if you encounter any issues. This action cannot be undone!")
        }
    }

    private var onDeviceImportSection: some View {
        VStack(spacing: AppTheme.spacing8) {
            SettingsSectionHeader(title: "On-Device Import")

            SettingsCard {
                HStack(alignment: .top, spacing: AppTheme.spacing12) {
                    SettingsIconTile(systemName: "sparkles", color: importStatus.isAvailable ? .purple : .gray)

                    VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                        Text("AI Recipe Import")
                            .font(.body)
                            .adaptiveForegroundColor()

                        Text(importStatus.title)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(importStatus.isAvailable ? .green : .secondary)

                        Text(importStatus.detail)
                            .font(.caption)
                            .adaptiveSecondaryForeground()
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }
                .padding(AppTheme.spacing20)
            }
        }
    }

    private var backupSection: some View {
        VStack(spacing: AppTheme.spacing8) {
            SettingsSectionHeader(title: "Backup & Restore")

            SettingsCard {
                VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                    HStack(spacing: AppTheme.spacing12) {
                        SettingsIconTile(systemName: "externaldrive.fill", color: .blue)

                        VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                            Text("Backup Your Library")
                                .font(.body)
                                .adaptiveForegroundColor()

                            Text("Save everything to a file, or restore from one")
                                .font(.caption)
                                .adaptiveSecondaryForeground()
                        }
                    }

                    Text("Exports your recipes, notes, groceries, kitchen, meal plans, badges and tips to a single file. Importing merges a backup into your current library without overwriting anything.")
                        .font(.subheadline)
                        .adaptiveSecondaryForeground()
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: exportBackup) {
                        actionLabel(icon: "square.and.arrow.up", title: "Export Backup", color: .blue)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { isImporting = true }) {
                        actionLabel(icon: "square.and.arrow.down", title: "Import Backup", color: .green)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(AppTheme.spacing20)
            }
        }
    }

    private func actionLabel(icon: String, title: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
            Text(title)
                .font(.body)
                .fontWeight(.semibold)
        }
        .adaptiveForegroundColor()
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.spacing12)
        .background(color)
        .cornerRadius(AppTheme.cornerRadius12)
    }

    private static let backupDateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
    }()

    private static func defaultBackupFilename() -> String {
        "RecipeFinder-Backup-\(backupDateFormatter.string(from: Date()))"
    }

    private func exportBackup() {
        do {
            exportDocument = BackupDocument(data: try BackupService().exportData())
            isExporting = true
        } catch {
            showBackupMessage("Couldn't create the backup.", isError: true)
        }
    }

    private func importBackup(from url: URL) {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }

        do {
            let data = try Data(contentsOf: url)
            try BackupService().importData(data)

            // Core Data recipe list only reloads on a scope-change signal — nudge it to re-fetch the merged recipes.
            NotificationCenter.default.post(name: .userScopeDidChange, object: nil)

            showBackupMessage("Backup restored.", isError: false)
            HapticManager.shared.success()
        } catch let error as BackupError {
            showBackupMessage(error.errorDescription ?? "That backup couldn't be restored.", isError: true)
            HapticManager.shared.error()
        } catch {
            showBackupMessage("Couldn't read that backup.", isError: true)
            HapticManager.shared.error()
        }
    }

    private func showBackupMessage(_ message: String, isError: Bool) {
        backupMessage = message
        backupMessageIsError = isError
        DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.animationDelayFeedback) {
            backupMessage = nil
        }
    }

    private func resetToDefault() {
        // Scope the wipe to the current scope (account, or the guest's nil scope) — never other accounts.
        PersistenceController.shared.clearAllRecipes()
        UserScopedStorage.shared.clearCurrentUserData()

        // Appearance settings are app-wide (global @AppStorage) — restore defaults.
        let defaults = UserDefaults.standard
        defaults.set("Teal", forKey: "appTheme")
        defaults.set("Frost Light", forKey: "cardStyle")
        defaults.set("metric", forKey: "measurementSystem")

        // Seed flags were cleared above, so this re-seeds the starters + bundled collection a fresh install gets and
        // refreshes the visible list (previously the list kept showing the deleted recipes).
        recipeStore.load(isAuthenticated: auth.isAuthenticated)

        // Refresh in-memory managers so the UI reflects the reset immediately.
        ShoppingListManager.shared.reloadForCurrentUser()
        KitchenInventoryManager.shared.reloadForCurrentUser()
        MealPlanningManager.shared.reloadForCurrentUser()
        CollectionManager.shared.reloadForCurrentUser()
        BadgeManager.shared.reloadForCurrentUser()  // else cleared badges stay in memory and get re-persisted on the next write
        CookingStreakManager.shared.reloadForCurrentUser()
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
