import SwiftUI

struct BackupReminderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var backupManager = BackupReminderManager.shared
    @AppStorage("cardStyle") private var cardStyle: String = "glass"
    
    let onExportTapped: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppTheme.spacing32) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "externaldrive.badge.checkmark")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                }
                .padding(.top, AppTheme.spacing32)
                
                VStack(spacing: AppTheme.spacing12) {
                    Text("Backup Your Data")
                        .font(.title2)
                        .fontWeight(.bold)
                        .adaptiveForegroundColor()
                    
                    Text("It's been **\(backupManager.daysSinceLastBackup) days** since your last backup. Protect your \(recipeCountText) by exporting them now.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, AppTheme.spacing32)
                }
                
                VStack(spacing: AppTheme.spacing12) {
                    InfoCard(
                        icon: "shield.checkmark.fill",
                        title: "Protect Against Data Loss",
                        description: "Device issues or accidental deletion can happen"
                    )
                    
                    InfoCard(
                        icon: "clock.fill",
                        title: "Quick & Easy",
                        description: "Export takes just a few seconds"
                    )
                    
                    InfoCard(
                        icon: "icloud.and.arrow.up.fill",
                        title: "Save to Your Files",
                        description: "Store in iCloud, Files app, or any location"
                    )
                }
                .padding(.horizontal, AppTheme.spacing24)
                
                Spacer()
                
                VStack(spacing: AppTheme.spacing12) {
                    Button {
                        HapticManager.shared.light()
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onExportTapped()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.down.doc.fill")
                            Text("Export Data Now")
                        }
                        .font(.headline)
                        .adaptiveForegroundColor()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.orange)
                        .cornerRadius(AppTheme.cornerRadius12)
                    }
                    
                    Button {
                        HapticManager.shared.light()
                        backupManager.dismissReminder()
                        dismiss()
                    } label: {
                        Text("Remind Me in 7 Days")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, AppTheme.spacing24)
                .padding(.bottom, AppTheme.spacing24)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        backupManager.dismissReminder()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var recipeCountText: String {
        let count = AccountManager.shared.recipeCount
        if count == 1 {
            return "1 recipe"
        } else {
            return "\(count) recipes"
        }
    }
}

private struct InfoCard: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: AppTheme.spacing12) {
            Image(systemName: icon)
                .font(.system(size: AppTheme.fontSize20))
                .foregroundColor(.orange)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .adaptiveForegroundColor()
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(AppTheme.spacing16)
        .background(AppTheme.adaptiveCard(for: colorScheme))
        .cornerRadius(AppTheme.cornerRadius12)
    }
}

#Preview {
    BackupReminderSheet {
        print("Export tapped")
    }
}
