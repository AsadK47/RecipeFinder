import Foundation

/// Plan's take-off toast: take-offs in a row while the toast is up share one Undo, so the first is never lost.
struct MealPlanTakeOff: Equatable {
    /// The plans as they were before the first take-off in the row — what Undo puts back.
    let undo: [MealPlanModel]
    /// Meals the cook took off in this row: one per tap that took something off. A weekly dinner is one meal,
    /// though its later-week copies go with it.
    let meals: Int
    /// The meal the toast names when one came off: the last tap that took something off.
    let named: MealPlanModel
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
        let tookOff = changed.contains { $0.id == plan.id }
        let meals = (earlier?.meals ?? 0) + (tookOff ? 1 : 0)
        // A stale tap on another meal mustn't rename the one that came off.
        let named = tookOff ? plan : (earlier?.named ?? plan)
        let single = named.isRecurring ? "\(named.recipeName) taken off and stopped repeating"
                                       : "\(named.recipeName) taken off"
        return MealPlanTakeOff(undo: undo, meals: meals, named: named,
                               message: meals > 1 ? "\(meals) meals taken off" : single)
    }
}
