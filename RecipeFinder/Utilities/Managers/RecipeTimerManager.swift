import SwiftUI

/// Behavioural seam for the recipe cook-timer so views depend on this protocol
/// rather than the `RecipeTimerManager` singleton — and tests can inject a fake.
@MainActor
protocol RecipeTiming: AnyObject, Observable {
    var durationSeconds: Int { get }
    var remainingSeconds: Int { get }
    var isRunning: Bool { get }
    var isPaused: Bool { get }
    var isActive: Bool { get }
    var displayTime: String { get }
    func start(hours: Int, minutes: Int, seconds: Int)
    func pause()
    func resume()
    func togglePause()
    func stop()
}

private struct RecipeTimingKey: EnvironmentKey {
    // SwiftUI reads environment defaults on the main actor during view updates,
    // so assuming main-actor isolation here is safe; the real app injects the
    // shared instance at the composition root regardless.
    static var defaultValue: any RecipeTiming {
        MainActor.assumeIsolated { RecipeTimerManager.shared }
    }
}

extension EnvironmentValues {
    /// Injected cook-timer. Defaults to the shared singleton; override with
    /// `.environment(\.recipeTimer, fake)` in tests/previews.
    var recipeTimer: any RecipeTiming {
        get { self[RecipeTimingKey.self] }
        set { self[RecipeTimingKey.self] = newValue }
    }
}

@MainActor
@Observable
final class RecipeTimerManager: RecipeTiming {
    static let shared = RecipeTimerManager()

    private(set) var durationSeconds: Int = 0
    private(set) var remainingSeconds: Int = 0
    private(set) var isRunning: Bool = false
    private(set) var isPaused: Bool = false

    @ObservationIgnored private var endDate: Date?
    @ObservationIgnored private var ticker: Timer?
    @ObservationIgnored private let defaults: UserDefaults

    private enum Keys {
        static let duration = "recipeTimer.duration"
        static let remaining = "recipeTimer.remaining"
        static let isRunning = "recipeTimer.isRunning"
        static let isPaused = "recipeTimer.isPaused"
        static let endDate = "recipeTimer.endDate"
    }

    /// Production entry point — uses `UserDefaults.standard`.
    private convenience init() {
        self.init(defaults: .standard)
    }

    /// Designated init; injectable `defaults` lets tests run against isolated storage.
    init(defaults: UserDefaults) {
        self.defaults = defaults
        restoreState()
        startTickerIfNeeded()
    }

    var isActive: Bool {
        isRunning || isPaused
    }

    var displayTime: String {
        formatTime(remainingSeconds)
    }

    func start(hours: Int, minutes: Int, seconds: Int) {
        let total = max(0, (hours * 3600) + (minutes * 60) + seconds)
        guard total > 0 else { return }

        // Request permission here — the user has just started a timer so the
        // purpose is obvious. The system only shows the dialog once; subsequent
        // calls are no-ops once the user has responded.
        let notificationsEnabled = (defaults.object(forKey: "timerNotifications") as? Bool) ?? true
        if notificationsEnabled {
            NotificationManager.shared.requestPermission { _ in }
        }

        durationSeconds = total
        remainingSeconds = total
        isRunning = true
        isPaused = false
        endDate = Date().addingTimeInterval(TimeInterval(total))

        startTickerIfNeeded()
        persistState()
        HapticManager.shared.success()
    }

    func pause() {
        guard isRunning, !isPaused else { return }

        syncRemainingFromEndDate()
        isPaused = true
        isRunning = false
        endDate = nil

        persistState()
        HapticManager.shared.light()
    }

    func resume() {
        guard isPaused, remainingSeconds > 0 else { return }

        isPaused = false
        isRunning = true
        endDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))

        startTickerIfNeeded()
        persistState()
        HapticManager.shared.light()
    }

    func togglePause() {
        if isPaused {
            resume()
        } else {
            pause()
        }
    }

    func stop() {
        durationSeconds = 0
        remainingSeconds = 0
        isRunning = false
        isPaused = false
        endDate = nil

        persistState()
        HapticManager.shared.light()
    }

    private func tick() {
        guard isRunning, !isPaused else { return }

        syncRemainingFromEndDate()

        if remainingSeconds <= 0 {
            completeTimer()
        }
    }

    private func syncRemainingFromEndDate() {
        guard let endDate else { return }
        remainingSeconds = max(0, Int(ceil(endDate.timeIntervalSinceNow)))
    }

    private func completeTimer() {
        stopTicker()
        isRunning = false
        isPaused = false
        remainingSeconds = 0
        endDate = nil

        persistState()
        HapticManager.shared.celebrate()
        // Respect the user's notification preference before firing.
        let notificationsEnabled = (defaults.object(forKey: "timerNotifications") as? Bool) ?? true
        if notificationsEnabled {
            NotificationManager.shared.sendImmediateNotification(
                title: "⏰ Timer Complete!",
                body: "Your recipe timer has finished.",
                identifier: "recipe-timer-complete"
            )
        }
    }

    private func startTickerIfNeeded() {
        guard ticker == nil else { return }
        ticker = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }

    private func persistState() {
        defaults.set(durationSeconds, forKey: Keys.duration)
        defaults.set(remainingSeconds, forKey: Keys.remaining)
        defaults.set(isRunning, forKey: Keys.isRunning)
        defaults.set(isPaused, forKey: Keys.isPaused)
        defaults.set(endDate, forKey: Keys.endDate)
    }

    private func restoreState() {
        durationSeconds = defaults.integer(forKey: Keys.duration)
        remainingSeconds = defaults.integer(forKey: Keys.remaining)
        isRunning = defaults.bool(forKey: Keys.isRunning)
        isPaused = defaults.bool(forKey: Keys.isPaused)
        endDate = defaults.object(forKey: Keys.endDate) as? Date

        if isRunning {
            syncRemainingFromEndDate()
            if remainingSeconds <= 0 {
                isRunning = false
                isPaused = false
                endDate = nil
            }
        }

        if !isActive {
            stopTicker()
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}
