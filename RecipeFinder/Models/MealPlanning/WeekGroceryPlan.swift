import Foundation

/// What the plan still needs from the shop: the week's shopping summary minus what's at home and what's already on
/// the list (a line already on it counts toward the amount, so adding twice never doubles it), plus the copy for
/// Groceries' "From your plan" card. Pure.
struct WeekGroceryPlan: Equatable {
    /// Items still to buy, in the summary's order; `quantity` is what's missing after what's on the list.
    let candidates: [WeekShoppingSummary.Item]
    let mealsCovered: Int
    let skippedInKitchen: Int
    /// Things to buy (name + unit) the list already covers in full.
    let skippedOnList: Int

    static let empty = WeekGroceryPlan(
        summary: WeekShoppingSummary(items: [], mealsCovered: 0, missingRecipeNames: []), kitchenNames: [])

    /// `kitchenNames` are the names of everything at home (kitchen + inventory); matched after normalising.
    /// `listItems` is the shopping list, ticked or not (ticked means bought). Lines are matched by normalised name +
    /// canonical unit, so "200 g" and "100 grams" are one line; a line asks for at most `maxQuantity`, what
    /// `ShoppingListManager.addItem` can hold, so a big week can't leave a line the list can never cover.
    init(summary: WeekShoppingSummary, kitchenNames: [String], listItems: [ShoppingListModel] = []) {
        let inKitchen = Set(kitchenNames.map { IngredientNormalizer.normalize($0) })
        let toBuy = summary.items.filter { !inKitchen.contains(IngredientNormalizer.normalize($0.name)) }
        var needed: [String: WeekShoppingSummary.Item] = [:]
        var order: [String] = []
        for item in toBuy {
            let key = Self.key(name: item.name, unit: item.unit)
            if let first = needed[key] {
                needed[key] = .init(name: first.name, quantity: first.quantity + item.quantity, unit: first.unit)
            } else {
                needed[key] = item
                order.append(key)
            }
        }
        var onList: [String: Int] = [:]
        for item in listItems {
            onList[Self.key(name: item.name, unit: item.unit), default: 0] += item.quantity
        }
        candidates = order.compactMap { key in
            guard let item = needed[key] else { return nil }
            let missing = min(item.quantity, Self.maxQuantity) - (onList[key] ?? 0)
            guard missing > 0 else { return nil }
            return WeekShoppingSummary.Item(name: item.name, quantity: missing, unit: item.unit)
        }
        mealsCovered = summary.mealsCovered
        skippedInKitchen = summary.items.count - toBuy.count
        skippedOnList = order.count - candidates.count
        candidateKeys = Set(candidates.map { Self.key(name: $0.name, unit: $0.unit) })
    }

    /// The most one shopping line holds (`ShoppingListManager.addItem` refuses or caps above it).
    static let maxQuantity = 999

    /// One key per thing to buy, whatever the spelling or unit synonym.
    private let candidateKeys: Set<String>

    private static func key(name: String, unit: String) -> String {
        "\(IngredientNormalizer.normalize(name).nameKey)|\(UnitConversion.canonicalUnit(unit))"
    }

    /// Whether the card should show again after the cook said "Not now" to `dismissed`: only when the plan needs
    /// something it didn't then, so a deleted item doesn't bring the card straight back.
    func needsMore(than dismissed: WeekGroceryPlan?) -> Bool {
        guard let dismissed else { return !candidates.isEmpty }
        return !candidateKeys.isSubset(of: dismissed.candidateKeys)
    }

    var addButtonTitle: String {
        "Add \(Self.items(candidates.count))"
    }

    /// The line under Groceries' "From your plan" card title.
    var cardDetail: String {
        var detail = "\(Self.items(candidates.count)) for \(mealsCovered) planned meal\(mealsCovered == 1 ? "" : "s")"
        if skippedInKitchen > 0 {
            detail += " · \(skippedInKitchen) at home"
        }
        return detail
    }

    /// Adds every candidate; `addItem` merges each into a same name + unit line, topping it up to what's needed
    /// (a ticked line is bought, so it becomes an unticked line for what's still missing).
    @MainActor
    func add(to shopping: any ShoppingListManaging) {
        for item in candidates {
            shopping.addItem(name: item.name, quantity: item.quantity, unit: item.unit, category: nil)
        }
    }

    private static func items(_ count: Int) -> String {
        "\(count) item\(count == 1 ? "" : "s")"
    }
}
