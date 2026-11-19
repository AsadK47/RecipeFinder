import Foundation

// MARK: - CookingResumeMemory

/// Where the cook left off in cooking mode, per recipe, so closing it mid-cook and opening it again picks up at the
/// same step with the same ingredients ticked. Held in memory for this app session only: it survives leaving cooking
/// mode, switching tabs and backgrounding, not a relaunch (persisting it would be new on-device data — Needs owner).
@MainActor
final class CookingResumeMemory {

    static let shared = CookingResumeMemory()

    /// After this long the cook has most likely moved on; reopening starts from the top.
    static let maxAge: TimeInterval = 12 * 60 * 60

    struct Place: Equatable {
        let index: Int
        let checkedIngredients: Set<Int>
    }

    private struct Entry {
        let place: Place
        let content: [String]
        let savedAt: Date
    }

    private var entries: [UUID: Entry] = [:]
    private let now: () -> Date

    init(now: @escaping () -> Date = Date.init) {
        self.now = now
    }

    /// `content` fingerprints the recipe as cooked (its cooking-mode lines + ingredient names): a recipe edited in
    /// between won't resume at an index that now means a different step or ingredient.
    func remember(_ place: Place, for recipeID: UUID, content: [String]) {
        guard place.index > 0 || !place.checkedIngredients.isEmpty else {
            entries[recipeID] = nil  // still at the very start — nothing to resume
            return
        }
        entries[recipeID] = Entry(place: place, content: content, savedAt: now())
    }

    /// The saved place, or nil when there is none, the recipe changed, it's out of range or older than `maxAge`.
    func place(for recipeID: UUID, content: [String], itemCount: Int) -> Place? {
        guard let entry = entries[recipeID] else { return nil }
        guard entry.content == content,
              (0..<itemCount).contains(entry.place.index),
              now().timeIntervalSince(entry.savedAt) <= Self.maxAge else {
            entries[recipeID] = nil
            return nil
        }
        return entry.place
    }

    /// Called when the cook finishes: the next cook of this recipe starts from the top.
    func forget(_ recipeID: UUID) {
        entries[recipeID] = nil
    }
}
