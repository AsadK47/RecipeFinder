import Foundation

/// Keeps a recipe screen's tick state attached to items (not row positions) when the item list changes.
enum ChecklistState {

    /// Re-maps ticks from `oldItems` onto `newItems` by matching item keys; unmatched new items start unticked.
    /// Duplicate keys are matched in order, so two identical lines keep their own ticks.
    static func remap(_ state: [Bool], from oldItems: [String], to newItems: [String]) -> [Bool] {
        guard oldItems != newItems else {
            return state.count == newItems.count ? state : Array(repeating: false, count: newItems.count)
        }
        var tickedCounts: [String: Int] = [:]
        for (index, key) in oldItems.enumerated() where state.indices.contains(index) && state[index] {
            tickedCounts[key, default: 0] += 1
        }
        return newItems.map { key in
            guard let remaining = tickedCounts[key], remaining > 0 else { return false }
            tickedCounts[key] = remaining - 1
            return true
        }
    }

    /// Stable content key for an ingredient — the wizard mints new ids on every save, so ids can't be used.
    static func key(for ingredient: Ingredient) -> String {
        "\(ingredient.name.lowercased())|\(ingredient.unit.lowercased())|\(ingredient.baseQuantity)"
    }
}
