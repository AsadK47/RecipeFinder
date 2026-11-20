import Foundation

/// What the plan still needs from the shop: the week's shopping summary minus what's at home and what's already on
/// the list (a line already on it counts toward the amount, so adding twice never doubles it), plus the copy for
/// Plan's "Add Week to Groceries" and Groceries' "From your plan" card. Pure — split from `MealPlanningView`.
struct WeekGroceryPlan: Equatable {
    /// Items still to buy, in the summary's order; `quantity` is what's missing after what's on the list.
    let candidates: [WeekShoppingSummary.Item]
    let mealsCovered: Int
    let skippedInKitchen: Int
    /// Summary lines the list already covers in full.
    let skippedOnList: Int
    private let summaryHadItems: Bool
    private let hasMissingRecipes: Bool

    static let empty = WeekGroceryPlan(
        summary: WeekShoppingSummary(items: [], mealsCovered: 0, missingRecipeNames: []), kitchenNames: [])

    /// `kitchenNames` are the names of everything at home (kitchen + inventory); matched after normalising.
    /// `listItems` is the shopping list, ticked or not (ticked means bought); matched by name + unit like `addItem`.
    init(summary: WeekShoppingSummary, kitchenNames: [String], listItems: [ShoppingListModel] = []) {
        let inKitchen = Set(kitchenNames.map { IngredientNormalizer.normalize($0) })
        let toBuy = summary.items.filter { !inKitchen.contains(IngredientNormalizer.normalize($0.name)) }
        var onList: [String: Int] = [:]
        for item in listItems {
            onList[item.sameItemKey, default: 0] += item.quantity
        }
        candidates = toBuy.compactMap { item in
            let missing = item.quantity - (onList[ShoppingListModel.sameItemKey(name: item.name, unit: item.unit)] ?? 0)
            guard missing > 0 else { return nil }
            return WeekShoppingSummary.Item(name: item.name, quantity: missing, unit: item.unit)
        }
        mealsCovered = summary.mealsCovered
        skippedInKitchen = summary.items.count - toBuy.count
        skippedOnList = toBuy.count - candidates.count
        summaryHadItems = !summary.items.isEmpty
        hasMissingRecipes = !summary.missingRecipeNames.isEmpty
    }

    /// The toast to show instead of the confirm dialog when nothing would be added; nil when there is.
    var nothingToAddMessage: String? {
        guard candidates.isEmpty else { return nil }
        if summaryHadItems {
            switch (skippedOnList > 0, skippedInKitchen > 0) {
            case (true, true): return "Everything for your plan is on your list or at home"
            case (true, false): return "Everything for your plan is on your list"
            default: return "You already have everything in your kitchen"
            }
        }
        return hasMissingRecipes ? "Couldn't find this week's recipes" : "No planned meals to shop for"
    }

    var addButtonTitle: String {
        "Add \(Self.items(candidates.count))"
    }

    var confirmMessage: String {
        var parts = ["From \(mealsCovered) planned meal\(mealsCovered == 1 ? "" : "s")."]
        if skippedInKitchen > 0 {
            parts.append("\(skippedInKitchen) already in your kitchen will be skipped.")
        }
        if skippedOnList > 0 {
            parts.append("\(skippedOnList) already on your list.")
        }
        return parts.joined(separator: " ")
    }

    /// The toast after the items were added.
    var addedMessage: String {
        var message = "Added \(Self.items(candidates.count)) from \(mealsCovered) meal\(mealsCovered == 1 ? "" : "s")"
        if skippedInKitchen > 0 {
            message += " · \(skippedInKitchen) already in kitchen"
        }
        return message
    }

    /// The line under Groceries' "From your plan" card title.
    var cardDetail: String {
        var detail = "\(Self.items(candidates.count)) for \(mealsCovered) planned meal\(mealsCovered == 1 ? "" : "s")"
        if skippedInKitchen > 0 {
            detail += " · \(skippedInKitchen) at home"
        }
        return detail
    }

    /// Adds every candidate; `addItem` merges each into a same name + unit line, topping it up to what's needed.
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
