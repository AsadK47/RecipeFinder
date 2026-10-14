import Foundation

/// Pure, testable model of a cooking-mode session: the ordered items (ingredient list → pre-prep → steps)
/// and every index-derived value the view renders — progress fraction, "Step N of M", first/last. Keeping the
/// off-by-one-prone arithmetic here (not trapped in `CookingModeView`'s private computed properties) means it
/// can be unit-tested directly.
struct CookingPlan: Equatable {
    enum Item: Equatable {
        case ingredientList
        case prePrep(index: Int, text: String)
        case step(index: Int, text: String)

        var isIngredientList: Bool {
            if case .ingredientList = self { return true }
            return false
        }

        var displayText: String {
            switch self {
            case .ingredientList:       return ""
            case .prePrep(_, let text): return text
            case .step(_, let text):    return text
            }
        }
    }

    let items: [Item]
    private let prePrepCount: Int
    private let stepCount: Int

    init(prePrep: [String], steps: [String]) {
        var items: [Item] = [.ingredientList]
        for (i, text) in prePrep.enumerated() { items.append(.prePrep(index: i, text: text)) }
        for (i, text) in steps.enumerated() { items.append(.step(index: i, text: text)) }
        self.items = items
        self.prePrepCount = prePrep.count
        self.stepCount = steps.count
    }

    var count: Int { items.count }

    func isFirst(_ index: Int) -> Bool { index == 0 }
    func isLast(_ index: Int) -> Bool { index == count - 1 }

    /// Fraction complete for the progress bar: item `index` (0-based) counts as done, so index 0 of N → 1/N.
    func progress(_ index: Int) -> Double {
        guard count > 0 else { return 0 }
        return Double(index + 1) / Double(count)
    }

    /// Section label + how many items that section has, for the current item ("Step", 8).
    func phaseLabel(at index: Int) -> (label: String, total: Int) {
        guard items.indices.contains(index) else { return ("", 0) }
        switch items[index] {
        case .ingredientList: return ("", 0)
        case .prePrep:        return ("Pre-Prep", prePrepCount)
        case .step:           return ("Step", stepCount)
        }
    }

    /// 1-based position within its own section (pre-prep or step); 0 for the ingredient list.
    func positionInPhase(at index: Int) -> Int {
        guard items.indices.contains(index) else { return 0 }
        switch items[index] {
        case .ingredientList:          return 0
        case .prePrep(let i, _), .step(let i, _): return i + 1
        }
    }
}
