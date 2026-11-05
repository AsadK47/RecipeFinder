import SwiftUI

/// Behavioural seam so views depend on this protocol, not the `CookingStreakManager` singleton, and tests can inject a fake.
@MainActor
protocol CookingStreakTracking: AnyObject, Observable {
    var streak: CookingStreak { get }
    /// Records a cook; returns `true` if it extended the weekly streak (a new week was counted), so the UI can celebrate.
    @discardableResult func recordCook(on date: Date) -> Bool
    func reload()
}

extension CookingStreakTracking {
    /// Record a cook at the current moment. (A protocol requirement can't carry a default arg.)
    @discardableResult func recordCookToday() -> Bool { recordCook(on: Date()) }
}

private struct CookingStreakTrackingKey: EnvironmentKey {
    static var defaultValue: any CookingStreakTracking {
        MainActor.assumeIsolated { CookingStreakManager.shared }
    }
}

extension EnvironmentValues {
    /// Injected cooking-streak tracker; defaults to the shared singleton, override with `.environment(\.cookingStreak, fake)`.
    var cookingStreak: any CookingStreakTracking {
        get { self[CookingStreakTrackingKey.self] }
        set { self[CookingStreakTrackingKey.self] = newValue }
    }
}

/// Owns the cook-date log and derives the weekly cooking streak. Recording is called from the
/// single cook choke point (`RecipeDetailView.recordCook`, which cooking-mode's finish also routes through).
@MainActor
@Observable
final class CookingStreakManager: CookingStreakTracking {
    static let shared = CookingStreakManager()

    private(set) var streak: CookingStreak = .empty

    @ObservationIgnored private let storage: LocalStore
    @ObservationIgnored private let reminders: any StreakReminderScheduling
    @ObservationIgnored private let saveKey = "cookDatesLog"
    @ObservationIgnored private let reminderId = "cooking-streak-lapse"
    @ObservationIgnored private var cookDates: [Date] = []

    private init() {
        self.storage = .shared
        self.reminders = NotificationManager.shared
        load()
    }

    init(storage: LocalStore, reminders: any StreakReminderScheduling = NotificationManager.shared) {
        self.storage = storage
        self.reminders = reminders
        load()
    }

    @discardableResult
    func recordCook(on date: Date = Date()) -> Bool {
        let weeksBefore = streak.currentWeeks
        cookDates.append(date)
        storage.setEncodable(cookDates, forKey: saveKey)
        recompute()
        return streak.currentWeeks > weeksBefore
    }

    func reload() {
        load()
    }

    private func load() {
        if let decoded = storage.decodable([Date].self, forKey: saveKey) {
            cookDates = decoded
        } else {
            cookDates = []
        }
        recompute()
    }

    private func recompute() {
        streak = CookingStreak.compute(cookDates: cookDates)
        syncReminder()
    }

    /// Cancels any pending lapse nudge, then schedules a fresh one only when the streak is at risk.
    /// Cooking this week clears the at-risk state, so the reminder is cancelled; a new week re-arms it.
    private func syncReminder() {
        reminders.cancelNotification(identifier: reminderId)
        if let fire = CookingStreak.lapseReminder(for: streak, now: Date()) {
            reminders.scheduleStreakReminder(weeks: streak.currentWeeks, at: fire, identifier: reminderId)
        }
    }
}
