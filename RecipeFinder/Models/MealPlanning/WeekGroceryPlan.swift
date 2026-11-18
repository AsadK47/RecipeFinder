import Foundation

/// What Plan's "Add Week to Groceries" adds: the week's shopping summary minus what's already in the kitchen, and the
/// copy for its confirm dialog and toasts. Pure — split from `MealPlanningView` (Smell Batch D).
struct WeekGroceryPlan: Equatable {
    /// Items still to buy, in the summary's order.
    let candidates: [WeekShoppingSummary.Item]
    let mealsCovered: Int
    let skippedInKitchen: Int
    private let summaryHadItems: Bool
    private let hasMissingRecipes: Bool

    static let empty = WeekGroceryPlan(
        summary: WeekShoppingSummary(items: [], mealsCovered: 0, missingRecipeNames: []), kitchenNames: [])

    /// `kitchenNames` are the names of everything at home (kitchen + inventory); matched after normalising.
    init(summary: WeekShoppingSummary, kitchenNames: [String]) {
        let inKitchen = Set(kitchenNames.map { IngredientNormalizer.normalize($0) })
        candidates = summary.items.filter { !inKitchen.contains(IngredientNormalizer.normalize($0.name)) }
        mealsCovered = summary.mealsCovered
        skippedInKitchen = summary.items.count - candidates.count
        summaryHadItems = !summary.items.isEmpty
        hasMissingRecipes = !summary.missingRecipeNames.isEmpty
    }

    /// The toast to show instead of the confirm dialog when nothing would be added; nil when there is.
    var nothingToAddMessage: String? {
        guard candidates.isEmpty else { return nil }
        if summaryHadItems { return "You already have everything in your kitchen" }
        return hasMissingRecipes ? "Couldn't find this week's recipes" : "No planned meals to shop for"
    }

    var addButtonTitle: String {
        "Add \(candidates.count) item\(candidates.count == 1 ? "" : "s")"
    }

    var confirmMessage: String {
        var parts = ["From \(mealsCovered) planned meal\(mealsCovered == 1 ? "" : "s")."]
        if skippedInKitchen > 0 {
            parts.append("\(skippedInKitchen) already in your kitchen will be skipped.")
        }
        return parts.joined(separator: " ")
    }

    /// The toast after the items were added.
    var addedMessage: String {
        var message = "Added \(candidates.count) item\(candidates.count == 1 ? "" : "s") from \(mealsCovered) meal\(mealsCovered == 1 ? "" : "s")"
        if skippedInKitchen > 0 {
            message += " · \(skippedInKitchen) already in kitchen"
        }
        return message
    }
}
