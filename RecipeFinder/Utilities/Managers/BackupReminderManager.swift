import Foundation
import SwiftUI

private let logger = AppLogger.logger(category: "BackupReminder")

/// Manages backup reminders to encourage users to export their data regularly
@MainActor
final class BackupReminderManager: ObservableObject {
    static let shared = BackupReminderManager()
    
    @Published var shouldShowBackupReminder = false
    
    private let userDefaults = UserDefaults.standard
    private let lastBackupDateKey = "lastBackupDate"
    private let backupReminderDismissedKey = "backupReminderDismissedDate"
    private let backupIntervalDays = 30 // Remind every 30 days
    private let snoozeIntervalDays = 7  // Wait 7 days after dismissing
    
    private init() {
        checkBackupReminder()
    }
    
    /// Check if a backup reminder should be shown
    func checkBackupReminder() {
        // Get last backup date
        let lastBackupDate = userDefaults.object(forKey: lastBackupDateKey) as? Date ?? Date.distantPast
        
        // Get last dismissal date
        let lastDismissalDate = userDefaults.object(forKey: backupReminderDismissedKey) as? Date ?? Date.distantPast
        
        let daysSinceBackup = Calendar.current.dateComponents([.day], from: lastBackupDate, to: Date()).day ?? 0
        let daysSinceDismissal = Calendar.current.dateComponents([.day], from: lastDismissalDate, to: Date()).day ?? 999
        
        // Show reminder if:
        // 1. It's been more than 30 days since last backup
        // 2. It's been more than 7 days since user dismissed the reminder
        shouldShowBackupReminder = daysSinceBackup >= backupIntervalDays && daysSinceDismissal >= snoozeIntervalDays
        
        if shouldShowBackupReminder {
            logger.debug("📦 Backup reminder triggered (last backup: \(daysSinceBackup) days ago)")
        }
    }
    
    /// Record that a backup was performed
    func recordBackupCompleted() {
        userDefaults.set(Date(), forKey: lastBackupDateKey)
        shouldShowBackupReminder = false
        logger.debug("✅ Backup completed and recorded")
    }
    
    /// Record that the user dismissed the reminder
    func dismissReminder() {
        userDefaults.set(Date(), forKey: backupReminderDismissedKey)
        shouldShowBackupReminder = false
        logger.debug("🔕 Backup reminder snoozed for \(self.snoozeIntervalDays) days")
    }
    
    /// Get days since last backup
    var daysSinceLastBackup: Int {
        let lastBackupDate = userDefaults.object(forKey: lastBackupDateKey) as? Date ?? Date.distantPast
        return Calendar.current.dateComponents([.day], from: lastBackupDate, to: Date()).day ?? 999
    }
    
    /// Get formatted last backup date string
    var lastBackupDateString: String {
        guard let lastBackupDate = userDefaults.object(forKey: lastBackupDateKey) as? Date else {
            return "Never"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: lastBackupDate, relativeTo: Date())
    }
}
