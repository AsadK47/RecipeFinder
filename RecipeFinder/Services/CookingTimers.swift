import SwiftUI

/// Where a cooking timer's "it's done" alert goes; a seam so tests check scheduling without notifications.
@MainActor
protocol CookingTimerAlerting {
    func schedule(id: String, title: String, body: String, after seconds: TimeInterval)
    func cancel(id: String)
}

/// Alerts as local notifications (shown as a banner in the foreground too), honouring Settings → timer alerts.
struct NotificationCookingTimerAlerts: CookingTimerAlerting {
    func schedule(id: String, title: String, body: String, after seconds: TimeInterval) {
        guard (UserDefaults.standard.object(forKey: "timerNotifications") as? Bool) ?? true, seconds > 0 else { return }
        NotificationManager.shared.requestPermission { _ in }
        NotificationManager.shared.scheduleTimerNotification(title: title, body: body, timeInterval: seconds, identifier: id)
    }

    func cancel(id: String) {
        NotificationManager.shared.cancelNotification(identifier: id)
    }
}

/// Behavioural seam for cooking mode's named timers, injected through `@Environment(\.cookingTimers)`.
@MainActor
protocol CookingTiming: AnyObject, Observable {
    var timers: [CookingTimerBoard.Timer] { get }
    @discardableResult func start(name: String, minutes: Int, key: String?) -> CookingTimerBoard.Timer?
    func timer(forKey key: String, now: Date) -> CookingTimerBoard.Timer?
    func togglePause(_ id: UUID)
    func addMinute(_ id: UUID)
    func stop(_ id: UUID)
}

private struct CookingTimingKey: EnvironmentKey {
    // SwiftUI reads environment defaults on the main actor.
    static var defaultValue: any CookingTiming {
        MainActor.assumeIsolated { CookingTimers.shared }
    }
}

extension EnvironmentValues {
    var cookingTimers: any CookingTiming {
        get { self[CookingTimingKey.self] }
        set { self[CookingTimingKey.self] = newValue }
    }
}

/// The app's running cooking timers. Kept for the app session (not persisted), so they stay on screen as the cook
/// moves between steps, leaves cooking mode or opens another recipe; each alert is scheduled up front so it still
/// fires with the app in the background.
@MainActor
@Observable
final class CookingTimers: CookingTiming {
    static let shared = CookingTimers()

    private(set) var board = CookingTimerBoard()
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let alerts: any CookingTimerAlerting

    init(now: @escaping () -> Date = Date.init, alerts: any CookingTimerAlerting = NotificationCookingTimerAlerts()) {
        self.now = now
        self.alerts = alerts
    }

    var timers: [CookingTimerBoard.Timer] { board.timers }

    /// Pausing a finished timer changes nothing, so it must not re-arm or cancel anything either.
    static func alertID(_ id: UUID) -> String { "cooking-timer-\(id.uuidString)" }

    @discardableResult
    func start(name: String, minutes: Int, key: String?) -> CookingTimerBoard.Timer? {
        let date = now()
        if let key, let existing = board.timer(forKey: key, now: date) { return existing }
        guard let timer = board.start(name: name, seconds: minutes * 60, key: key, now: date) else { return nil }
        scheduleAlert(for: timer)
        return timer
    }

    func timer(forKey key: String, now: Date) -> CookingTimerBoard.Timer? {
        board.timer(forKey: key, now: now)
    }

    /// One timer per step of a recipe — two recipes' "step 3" are different timers.
    static func stepKey(recipeID: UUID, index: Int) -> String { "\(recipeID.uuidString)#\(index)" }

    func togglePause(_ id: UUID) {
        let date = now()
        guard let before = board.timer(id), !before.isDone(at: date),
              let timer = board.togglePause(id, now: date) else { return }
        if timer.isPaused { alerts.cancel(id: Self.alertID(id)) } else { scheduleAlert(for: timer) }
    }

    func addMinute(_ id: UUID) {
        guard let timer = board.add(seconds: 60, to: id, now: now()), !timer.isPaused else { return }
        scheduleAlert(for: timer)  // same identifier replaces the earlier alert
    }

    func stop(_ id: UUID) {
        board.remove(id)
        alerts.cancel(id: Self.alertID(id))
    }

    private func scheduleAlert(for timer: CookingTimerBoard.Timer) {
        let left = timer.remaining(at: now())
        guard left > 0 else { return }
        alerts.schedule(
            id: Self.alertID(timer.id),
            title: "⏰ \(timer.name) is ready",
            body: "Your \(timer.name.lowercased()) timer has finished.",
            after: TimeInterval(left)
        )
    }
}
