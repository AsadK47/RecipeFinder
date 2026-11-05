import Foundation

// MARK: - CookingSession

/// Shared active-cooking-session state driven by voice AppIntents; `CookingModeView` syncs via `setIndex(_:)`, intents call `advance()`/`retreat()` which post notifications so the view follows.
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

    /// Called by intents to advance one step; posts a notification so `CookingModeView` follows without observing this object.
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
