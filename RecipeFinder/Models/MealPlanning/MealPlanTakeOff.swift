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
    ///   - calendar: groups a weekly dinner's copies by weekday.
    static func after(taking plan: MealPlanModel,
                      changed: [MealPlanModel],
                      earlier: [MealPlanModel],
                      calendar: Calendar = .current,
                      isStillPlanned: (MealPlanModel) -> Bool) -> MealPlanTakeOff {
        // First copy per id wins: it's the state before any of them.
        let undo = earlier + changed.filter { plan in !earlier.contains { $0.id == plan.id } }
        let single = plan.isRecurring ? "\(plan.recipeName) taken off and stopped repeating"
                                      : "\(plan.recipeName) taken off"
        guard !earlier.isEmpty else { return MealPlanTakeOff(undo: undo, message: single) }
        // A second tap on a meal already off changes nothing, so it mustn't read as one more.
        let gone = meals(in: undo.filter { !isStillPlanned($0) }, calendar: calendar)
        return MealPlanTakeOff(undo: undo, message: gone > 1 ? "\(gone) meals taken off" : single)
    }

    /// One weekly dinner is one meal to the cook, though taking it off also deletes its later-week copies:
    /// weekly plans on the same weekday and meal time count once — the series `MealPlanningManager.SeriesKey`
    /// stops together — and one-offs each count.
    private static func meals(in plans: [MealPlanModel], calendar: Calendar) -> Int {
        struct Weekly: Hashable { let weekday: Int; let mealTime: MealTime }
        let weekly = Set(plans.filter(\.isRecurring).map {
            Weekly(weekday: calendar.component(.weekday, from: $0.date), mealTime: $0.mealTime)
        })
        return plans.filter { !$0.isRecurring }.count + weekly.count
    }
}
