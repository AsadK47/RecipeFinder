import Foundation

/// Plan's take-off toast: take-offs in a row while the toast is up share one Undo, so the first is never lost.
struct MealPlanTakeOff: Equatable {
    /// The plans as they were before the first take-off in the row — what Undo puts back.
    let undo: [MealPlanModel]
    let message: String

    /// - Parameters:
    ///   - plan: the meal just taken off.
    ///   - changed: the plans this take-off changed, as they were before it (`plansChangedByRemoving`).
    ///   - earlier: the pending Undo while the toast is still up; empty when it isn't.
    ///   - isStillPlanned: whether a plan's id is still on the plan after the take-off (an earlier weekly copy
    ///     that only stopped repeating stays planned, so it isn't counted as taken off).
    static func after(taking plan: MealPlanModel,
                      changed: [MealPlanModel],
                      earlier: [MealPlanModel],
                      isStillPlanned: (MealPlanModel) -> Bool) -> MealPlanTakeOff {
        // First copy per id wins: it's the state before any of them.
        let undo = earlier + changed.filter { plan in !earlier.contains { $0.id == plan.id } }
        guard !earlier.isEmpty else {
            let text = plan.isRecurring ? "\(plan.recipeName) taken off and stopped repeating"
                                        : "\(plan.recipeName) taken off"
            return MealPlanTakeOff(undo: undo, message: text)
        }
        let gone = undo.filter { !isStillPlanned($0) }.count
        return MealPlanTakeOff(undo: undo, message: "\(max(gone, 2)) meals taken off")
    }
}
