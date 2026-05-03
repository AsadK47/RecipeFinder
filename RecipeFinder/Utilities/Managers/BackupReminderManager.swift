import Foundation
import SwiftUI

private let logger = AppLogger.logger(category: "BackupReminder")

@MainActor
final class BackupReminderManager: ObservableObject {
    static let shared = BackupReminderManager()
    
    @Published var shouldShowBackupReminder = false
    
    private let userDefaults = UserDefaults.standard
    private let lastBackupDateKey = "lastBackupDate"
    private let backupReminderDismissedKey = "backupReminderDismissedDate"
    private let backupIntervalDays = 30
    private let snoozeIntervalDays = 7
    
    private init() {
        checkBackupReminder()
    }
    
    func checkBackupReminder() {
        let lastBackupDate = userDefaults.object(forKey: lastBackupDateKey) as? Date ?? Date.distantPast
        
        let lastDismissalDate = userDefaults.object(forKey: backupReminderDismissedKey) as? Date ?? Date.distantPast
        
        let daysSinceBackup = Calendar.current.dateComponents([.day], from: lastBackupDate, to: Date()).day ?? 0
        let daysSinceDismissal = Calendar.current.dateComponents([.day], from: lastDismissalDate, to: Date()).day ?? 999
        
        shouldShowBackupReminder = daysSinceBackup >= backupIntervalDays && daysSinceDismissal >= snoozeIntervalDays
        
        if shouldShowBackupReminder {
            logger.debug("📦 Backup reminder triggered (last backup: \(daysSinceBackup) days ago)")
        }
    }
    
    func recordBackupCompleted() {
        userDefaults.set(Date(), forKey: lastBackupDateKey)
        shouldShowBackupReminder = false
        logger.debug("✅ Backup completed and recorded")
    }
    
    func dismissReminder() {
        userDefaults.set(Date(), forKey: backupReminderDismissedKey)
        shouldShowBackupReminder = false
        logger.debug("🔕 Backup reminder snoozed for \(self.snoozeIntervalDays) days")
    }
    
    var daysSinceLastBackup: Int {
        let lastBackupDate = userDefaults.object(forKey: lastBackupDateKey) as? Date ?? Date.distantPast
        return Calendar.current.dateComponents([.day], from: lastBackupDate, to: Date()).day ?? 999
    }
    
    var lastBackupDateString: String {
        guard let lastBackupDate = userDefaults.object(forKey: lastBackupDateKey) as? Date else {
            return "Never"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: lastBackupDate, relativeTo: Date())
    }
}
