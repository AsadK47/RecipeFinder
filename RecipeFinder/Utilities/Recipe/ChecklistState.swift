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

    /// Ingredient ticks: exact matches first, then by name and unit — so editing a ticked ingredient's amount keeps
    /// its tick (and its place in "Got it") instead of dropping it.
    static func remap(_ state: [Bool], from oldIngredients: [Ingredient], to newIngredients: [Ingredient]) -> [Bool] {
        let oldKeys = oldIngredients.map { key(for: $0) }
        let newKeys = newIngredients.map { key(for: $0) }
        guard oldKeys != newKeys else { return remap(state, from: oldKeys, to: newKeys) }
        var exactCounts: [String: Int] = [:]
        var looseCounts: [String: Int] = [:]
        for (index, ingredient) in oldIngredients.enumerated() where state.indices.contains(index) && state[index] {
            exactCounts[key(for: ingredient), default: 0] += 1
            looseCounts[looseKey(for: ingredient), default: 0] += 1
        }
        var result = Array(repeating: false, count: newIngredients.count)
        for (index, ingredient) in newIngredients.enumerated() {
            let exact = key(for: ingredient)
            guard let remaining = exactCounts[exact], remaining > 0 else { continue }
            exactCounts[exact] = remaining - 1
            looseCounts[looseKey(for: ingredient), default: 0] -= 1
            result[index] = true
        }
        for (index, ingredient) in newIngredients.enumerated() where !result[index] {
            let loose = looseKey(for: ingredient)
            guard let remaining = looseCounts[loose], remaining > 0 else { continue }
            looseCounts[loose] = remaining - 1
            result[index] = true
        }
        return result
    }

    private static func looseKey(for ingredient: Ingredient) -> String {
        "\(ingredient.name.lowercased())|\(ingredient.unit.lowercased())"
    }

    /// Stable content key for an ingredient — the wizard mints new ids on every save, so ids can't be used.
    static func key(for ingredient: Ingredient) -> String {
        "\(ingredient.name.lowercased())|\(ingredient.unit.lowercased())|\(ingredient.baseQuantity)"
    }
}
