import Foundation

/// Behavioural seam over `NotificationManager` for the weekly cooking-streak lapse nudge, so
/// `CookingStreakManager` can be asserted in tests without the `.shared` singleton.
protocol StreakReminderScheduling: AnyObject {
    /// Schedules a one-shot "your streak is about to lapse" reminder at `date` for a `weeks`-long streak.
    func scheduleStreakReminder(weeks: Int, at date: Date, identifier: String)
    func cancelNotification(identifier: String)
}

extension NotificationManager: StreakReminderScheduling {}
