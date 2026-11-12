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

private let streakLogger = AppLogger.logger(category: "CookingStreakManager")

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
    @ObservationIgnored private let cookDateStore: any CookDateStoring
    /// False only when moving the blob into Core Data failed this launch: keep reading/writing the blob so nothing is
    /// lost, and the next launch retries the move (it writes whatever the store is missing).
    @ObservationIgnored private var usesEntities = false

    private init() {
        self.storage = .shared
        self.cookDateStore = CoreDataCookDateStore(persistence: .shared)
        self.reminders = NotificationManager.shared
        load()
    }

    init(
        storage: LocalStore,
        cookDateStore: any CookDateStoring,
        reminders: any StreakReminderScheduling = NotificationManager.shared
    ) {
        self.storage = storage
        self.cookDateStore = cookDateStore
        self.reminders = reminders
        load()
    }

    @discardableResult
    func recordCook(on date: Date = Date()) -> Bool {
        let weeksBefore = streak.currentWeeks
        cookDates.append(date)
        persist(added: [date])
        recompute()
        return streak.currentWeeks > weeksBefore
    }

    func reload() {
        load()
    }

    /// Every recorded cook date, for backups.
    var recordedCookDates: [Date] { cookDates }

    /// Restores cook dates from a backup: unions with what's here (same instant counted once), never removes.
    func merge(cookDates incoming: [Date]) {
        let known = Set(cookDates)
        let added = Array(Set(incoming).subtracting(known)).sorted()
        guard !added.isEmpty else { return }
        cookDates = (cookDates + added).sorted()
        persist(added: added)
        recompute()
    }

    /// Erase & Reset: removes every stored cook (the blob is cleared with the rest of `LocalStore` by the caller).
    func removeAllCookDates() {
        do {
            try cookDateStore.deleteAllCookDates()
        } catch {
            streakLogger.error("❌ Failed to delete cook dates: \(error.localizedDescription)")
        }
        storage.removeObject(forKey: saveKey)
        load()
    }

    private func load() {
        let result = LegacyBlobMigration.run(
            blobKey: saveKey, as: Date.self, storage: storage,
            fetch: { try cookDateStore.fetchCookDates() },
            insert: { try cookDateStore.addCookDates($0) }
        )
        usesEntities = result != .failed
        if usesEntities {
            do {
                cookDates = try cookDateStore.fetchCookDates()
            } catch {
                streakLogger.error("❌ Failed to read cook dates, using the old copy: \(error.localizedDescription)")
                usesEntities = false
            }
        }
        if !usesEntities {
            cookDates = storage.decodable([Date].self, forKey: saveKey) ?? []
        }
        recompute()
    }

    private func persist(added: [Date]) {
        guard usesEntities else {
            storage.setEncodable(cookDates, forKey: saveKey)
            return
        }
        do {
            try cookDateStore.addCookDates(added)
        } catch {
            streakLogger.error("❌ Failed to save cook dates: \(error.localizedDescription)")
        }
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
