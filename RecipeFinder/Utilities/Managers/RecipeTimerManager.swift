import Foundation

@MainActor
final class RecipeTimerManager: ObservableObject {
    static let shared = RecipeTimerManager()

    @Published private(set) var durationSeconds: Int = 0
    @Published private(set) var remainingSeconds: Int = 0
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var isPaused: Bool = false

    private var endDate: Date?
    private var ticker: Timer?

    private enum Keys {
        static let duration = "recipeTimer.duration"
        static let remaining = "recipeTimer.remaining"
        static let isRunning = "recipeTimer.isRunning"
        static let isPaused = "recipeTimer.isPaused"
        static let endDate = "recipeTimer.endDate"
    }

    private init() {
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
        NotificationManager.shared.sendImmediateNotification(
            title: "⏰ Timer Complete!",
            body: "Your recipe timer has finished.",
            identifier: "recipe-timer-complete"
        )
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
        let defaults = UserDefaults.standard
        defaults.set(durationSeconds, forKey: Keys.duration)
        defaults.set(remainingSeconds, forKey: Keys.remaining)
        defaults.set(isRunning, forKey: Keys.isRunning)
        defaults.set(isPaused, forKey: Keys.isPaused)
        defaults.set(endDate, forKey: Keys.endDate)
    }

    private func restoreState() {
        let defaults = UserDefaults.standard

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
