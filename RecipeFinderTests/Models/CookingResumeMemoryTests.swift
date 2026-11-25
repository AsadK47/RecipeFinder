import SwiftUI
import Testing
@testable import RecipeFinder

@Suite("CookingResumeMemory")
@MainActor
struct CookingResumeMemoryTests {

    private final class Clock {
        var date = Date(timeIntervalSince1970: 1_800_000_000)
    }

    private let recipe = UUID()
    private let content = ["First, gather your ingredients.", "Boil", "Simmer", "onion", "rice"]

    private func memory(_ clock: Clock) -> CookingResumeMemory {
        CookingResumeMemory(now: { clock.date })
    }

    @Test("Reopening a recipe returns the step and ticks it was left on")
    func resumesSamePlace() {
        let m = memory(Clock())
        let place = CookingResumeMemory.Place(index: 2, checkedIngredients: [0, 1])
        m.remember(place, for: recipe, content: content)
        #expect(m.place(for: recipe, content: content, itemCount: 3) == place)
    }

    @Test("Nothing saved means starting from the top")
    func nothingSaved() {
        #expect(memory(Clock()).place(for: recipe, content: content, itemCount: 3) == nil)
    }

    @Test("Each recipe keeps its own place")
    func perRecipe() {
        let m = memory(Clock())
        let other = UUID()
        m.remember(.init(index: 1, checkedIngredients: []), for: recipe, content: content)
        m.remember(.init(index: 2, checkedIngredients: []), for: other, content: content)
        #expect(m.place(for: recipe, content: content, itemCount: 3)?.index == 1)
        #expect(m.place(for: other, content: content, itemCount: 3)?.index == 2)
    }

    @Test("Leaving on the ingredient list with ticks still resumes the ticks")
    func ticksOnFirstItem() {
        let m = memory(Clock())
        m.remember(.init(index: 0, checkedIngredients: [3]), for: recipe, content: content)
        #expect(m.place(for: recipe, content: content, itemCount: 3)?.checkedIngredients == [3])
    }

    @Test("Leaving at the very start clears an older place")
    func startClears() {
        let m = memory(Clock())
        m.remember(.init(index: 2, checkedIngredients: []), for: recipe, content: content)
        m.remember(.init(index: 0, checkedIngredients: []), for: recipe, content: content)
        #expect(m.place(for: recipe, content: content, itemCount: 3) == nil)
    }

    @Test("A recipe edited since leaving starts from the top")
    func editedRecipe() {
        let m = memory(Clock())
        m.remember(.init(index: 2, checkedIngredients: [1]), for: recipe, content: content)
        var edited = content
        edited[1] = "Boil for 10 minutes"
        #expect(m.place(for: recipe, content: edited, itemCount: 3) == nil)
        #expect(m.place(for: recipe, content: content, itemCount: 3) == nil, "a stale place is dropped, not kept")
    }

    @Test("An index past the end is never returned", arguments: [3, 7])
    func outOfRange(index: Int) {
        let m = memory(Clock())
        m.remember(.init(index: index, checkedIngredients: []), for: recipe, content: content)
        #expect(m.place(for: recipe, content: content, itemCount: 3) == nil)
    }

    @Test("A place up to 12 hours old resumes; older starts from the top")
    func expiry() {
        let clock = Clock()
        let m = memory(clock)
        m.remember(.init(index: 1, checkedIngredients: []), for: recipe, content: content)
        clock.date.addTimeInterval(CookingResumeMemory.maxAge)
        #expect(m.place(for: recipe, content: content, itemCount: 3)?.index == 1)
        clock.date.addTimeInterval(1)
        #expect(m.place(for: recipe, content: content, itemCount: 3) == nil)
    }

    @Test("Finishing forgets the place")
    func forget() {
        let m = memory(Clock())
        m.remember(.init(index: 2, checkedIngredients: []), for: recipe, content: content)
        m.forget(recipe)
        #expect(m.place(for: recipe, content: content, itemCount: 3) == nil)
    }

    @Test("The resume fingerprint changes when an ingredient or step changes")
    func fingerprint() {
        func make(_ ingredient: String, steps: [String]) -> RecipeModel {
            RecipeModel(name: "Rice", category: "Main", difficulty: "Basic", prepTime: "5", cookingTime: "10",
                        baseServings: 2, ingredients: [Ingredient(baseQuantity: 1, unit: "cup", name: ingredient)],
                        prePrepInstructions: [], instructions: steps, notes: "")
        }
        let a = make("rice", steps: ["Boil"])
        let b = make("basmati rice", steps: ["Boil"])
        let c = make("rice", steps: ["Boil", "Rest"])
        #expect(CookingModeView.resumeContent(for: a) == CookingModeView.resumeContent(for: a))
        #expect(CookingModeView.resumeContent(for: a) != CookingModeView.resumeContent(for: b))
        #expect(CookingModeView.resumeContent(for: a) != CookingModeView.resumeContent(for: c))
    }

    @Test("Cooking mode's environment seam defaults to the app's shared memory")
    func environmentDefaultsToShared() {
        #expect(EnvironmentValues().cookingResume === CookingResumeMemory.shared)
    }

    @Test("The environment seam hands back an injected test memory, not the shared one")
    func environmentAcceptsInjectedMemory() {
        let injected = memory(Clock())
        var values = EnvironmentValues()
        values.cookingResume = injected
        #expect(values.cookingResume === injected)
        #expect(values.cookingResume !== CookingResumeMemory.shared)
    }
}

/// Hosts the real `CookingModeView` in a window with a fake memory, so the view's own wiring is under test: these fail
/// if cooking mode goes back to `CookingResumeMemory.shared` (the seam tests above only see the EnvironmentKey).
@Suite("CookingModeView uses the injected resume memory", .serialized)
@MainActor
struct CookingModeResumeWiringTests {

    private final class FakeMemory: CookingResuming {
        var saved: CookingResumeMemory.Place?
        private(set) var lookups: [(id: UUID, content: [String])] = []
        private(set) var remembered: [(place: CookingResumeMemory.Place, id: UUID)] = []
        private(set) var forgotten: [UUID] = []

        func remember(_ place: CookingResumeMemory.Place, for recipeID: UUID, content: [String]) {
            remembered.append((place, recipeID))
        }
        func place(for recipeID: UUID, content: [String], itemCount: Int) -> CookingResumeMemory.Place? {
            lookups.append((recipeID, content))
            return saved
        }
        func forget(_ recipeID: UUID) { forgotten.append(recipeID) }
    }

    private struct SilentAlerts: CookingTimerAlerting {
        func schedule(id: String, title: String, body: String, after seconds: TimeInterval) {}
        func cancel(id: String) {}
    }

    private let recipe = RecipeModel(
        name: "Rice", category: "Main", difficulty: "Basic", prepTime: "5", cookingTime: "10", baseServings: 2,
        ingredients: [Ingredient(baseQuantity: 1, unit: "cup", name: "rice")],
        prePrepInstructions: [], instructions: ["Rinse", "Boil", "Rest"], notes: ""
    )

    private func host(_ memory: FakeMemory) throws -> UIWindow {
        // Every manager the screen reads is injected, so no test touches the shared UserDefaults or timers.
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let view = CookingModeView(recipe: recipe)
            .environment(\.cookingResume, memory)
            .environment(\.recipeTimer, RecipeTimerManager(defaults: defaults))
            .environment(\.cookingTimers, CookingTimers(alerts: SilentAlerts()))
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        let window = scene.map { UIWindow(windowScene: $0) } ?? UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIHostingController(rootView: view)
        window.isHidden = false
        window.layoutIfNeeded()
        return window
    }

    private func close(_ window: UIWindow) {
        window.rootViewController = nil
        window.isHidden = true
    }

    /// Lets SwiftUI run `onAppear` / `onDisappear` (they fire on the main run loop, after layout); a timeout fails.
    private func waitUntil(_ what: Comment, _ condition: () -> Bool) async throws {
        for _ in 0..<100 where !condition() {
            try await Task.sleep(for: .milliseconds(50))
        }
        #expect(condition(), what)
    }

    @Test("Opening cooking mode looks up the place in the injected memory and resumes at it")
    func opensAtInjectedPlace() async throws {
        let memory = FakeMemory()
        memory.saved = .init(index: 2, checkedIngredients: [0])
        let window = try host(memory)
        try await waitUntil("cooking mode appeared") { !memory.lookups.isEmpty && CookingSession.shared.currentIndex == 2 }

        #expect(memory.lookups.map(\.id) == [recipe.id])
        #expect(memory.lookups.first?.content == CookingModeView.resumeContent(for: recipe))
        #expect(CookingSession.shared.currentIndex == 2)

        // Leave no cooking session or screen-awake hold behind for other tests.
        close(window)
        try await waitUntil("cooking mode closed") { !CookingSession.shared.isActive }
    }

    @Test("Leaving cooking mode mid-cook saves the place to the injected memory")
    func leavingRemembersInInjectedMemory() async throws {
        let memory = FakeMemory()
        memory.saved = .init(index: 1, checkedIngredients: [0])
        let window = try host(memory)
        try await waitUntil("cooking mode appeared") { !memory.lookups.isEmpty }
        close(window)
        try await waitUntil("cooking mode closed") { !memory.remembered.isEmpty && !CookingSession.shared.isActive }

        #expect(memory.remembered.map(\.id) == [recipe.id])
        #expect(memory.remembered.first?.place == .init(index: 1, checkedIngredients: [0]))
        #expect(memory.forgotten.isEmpty)
    }
}
