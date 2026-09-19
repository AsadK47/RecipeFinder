import Foundation

// MARK: - Notification names

extension Notification.Name {
    static let cookingModeNextStep     = Notification.Name("CookingMode.nextStep")
    static let cookingModePreviousStep = Notification.Name("CookingMode.previousStep")
}

// MARK: - CookingSession

/// Shared state for the active cooking session, used by AppIntents to
/// advance/retreat steps via voice ("Hey Siri, next step").
///
/// `CookingModeView` starts/ends the session and keeps `currentIndex` in sync
/// via `setIndex(_:)`. Intents call `advance()` / `retreat()`, which update the
/// session index and post a notification so the live view follows.
///
/// The `init()` is internal so test code can create isolated instances.
@MainActor
final class CookingSession {

    static let shared = CookingSession()

    init() {}

    // MARK: - State

    private var items: [String] = []
    private(set) var currentIndex: Int = 0
    private(set) var recipeName: String?

    var isActive: Bool { recipeName != nil }
    var stepCount: Int { items.count }

    var currentStepText: String? {
        guard items.indices.contains(currentIndex) else { return nil }
        return items[currentIndex]
    }

    // MARK: - Lifecycle

    func start(recipeName: String, items: [String]) {
        self.recipeName = recipeName
        self.items = items
        self.currentIndex = 0
    }

    func end() {
        recipeName = nil
        items = []
        currentIndex = 0
    }

    // MARK: - Navigation

    /// Called by the view on every manual step change to keep session in sync.
    func setIndex(_ index: Int) {
        guard items.indices.contains(index) else { return }
        currentIndex = index
    }

    /// Called by intents to advance one step. Posts a notification so the live
    /// `CookingModeView` follows without needing to observe this object.
    func advance() {
        guard currentIndex < items.count - 1 else { return }
        currentIndex += 1
        NotificationCenter.default.post(name: .cookingModeNextStep, object: nil)
    }

    /// Called by intents to retreat one step.
    func retreat() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        NotificationCenter.default.post(name: .cookingModePreviousStep, object: nil)
    }
}
