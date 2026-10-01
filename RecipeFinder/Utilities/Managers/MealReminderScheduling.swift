import Foundation

/// Behavioural seam over `NotificationManager` so `MealPlanningManager`'s reminder scheduling
/// can be injected and asserted in tests, rather than calling the `.shared` singleton directly.
protocol MealReminderScheduling: AnyObject {
    /// Schedules (or re-schedules, when the identifier is reused) a meal reminder.
    /// `repeatsWeekly` fires on the date's weekday+time every week; otherwise it fires once.
    @discardableResult
    func scheduleMealReminder(
        mealName: String,
        recipeName: String,
        date: Date,
        identifier: String?,
        repeatsWeekly: Bool
    ) -> String

    func cancelNotification(identifier: String)
}

extension NotificationManager: MealReminderScheduling {}
