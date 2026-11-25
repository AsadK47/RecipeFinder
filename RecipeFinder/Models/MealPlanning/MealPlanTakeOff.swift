import Foundation

/// Plan's take-off toast: take-offs in a row while the toast is up share one Undo, so the first is never lost.
struct MealPlanTakeOff: Equatable {
    /// The plans as they were before the first take-off in the row — what Undo puts back.
    let undo: [MealPlanModel]
    /// Meals the cook took off in this row: one per tap that took something off. A weekly dinner is one meal,
    /// though its later-week copies go with it.
    let meals: Int
    let message: String

    /// - Parameters:
    ///   - plan: the meal just taken off.
    ///   - changed: the plans this take-off changed, as they were before it (`plansChangedByRemoving`); empty
    ///     when `plan` was already off (a stale second tap), which changes nothing and isn't one more meal.
    ///   - earlier: the pending take-off while the toast is still up; nil when it isn't.
    static func after(taking plan: MealPlanModel,
                      changed: [MealPlanModel],
                      earlier: MealPlanTakeOff?) -> MealPlanTakeOff {
        let before = earlier?.undo ?? []
        // First copy per id wins: it's the state before any of them.
        let undo = before + changed.filter { plan in !before.contains { $0.id == plan.id } }
        let meals = (earlier?.meals ?? 0) + (changed.contains { $0.id == plan.id } ? 1 : 0)
        let single = plan.isRecurring ? "\(plan.recipeName) taken off and stopped repeating"
                                      : "\(plan.recipeName) taken off"
        return MealPlanTakeOff(undo: undo, meals: meals, message: meals > 1 ? "\(meals) meals taken off" : single)
    }
}
