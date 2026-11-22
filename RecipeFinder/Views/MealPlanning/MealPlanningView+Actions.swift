import SwiftUI

// Plan's actions — saving/removing meals, reminders and week navigation — split from
// MealPlanningView (Smell Batch D). Shopping for the plan lives in Groceries (`PlanGroceriesCard`).
extension MealPlanningView {
    /// One Identifiable target for the recipe-picker / quick-snack sheets so content rebuilds from the value
    /// (`.sheet(item:)`) instead of reading a `currentMealTime` set in the same action — which rendered the
    /// sheet with a nil meal time on first present.
    enum MealPlanSheet: Identifiable {
        case recipeSelection(MealTime)
        case quickSnack(MealTime)

        var id: String {
            switch self {
            case .recipeSelection(let mealTime): "recipe-\(mealTime)"
            case .quickSnack(let mealTime): "snack-\(mealTime)"
            }
        }
    }

    /// A dinner photo's recipe pushed onto Plan's stack: its page, or straight into cooking from the hold menu's Cook.
    struct OpenedDinner: Hashable {
        let recipe: RecipeModel
        let startsCooking: Bool
    }

    /// Identifiable payload driving the meal-reminder time-picker sheet.
    struct ReminderContext: Identifiable {
        let id = UUID()
        let mealTime: MealTime
        let recipeName: String
        let initialTime: Date
    }

    // MARK: - Meal plan actions

    func saveMealPlan(recipe: RecipeModel, for date: Date, mealTime: MealTime) {
        let mealPlan = MealPlanModel(
            recipeId: recipe.id,
            recipeName: recipe.name,
            date: date,
            mealTime: mealTime,
            servings: recipe.currentServings
        )
        mealPlanningManager.addMealPlan(mealPlan)
        selectedMealTimes.insert(mealTime)
        HapticManager.shared.success()
    }

    func getRecipe(for date: Date, mealTime: MealTime) -> RecipeModel? {
        guard let mealPlan = mealPlanningManager.mealPlan(for: date, mealTime: mealTime) else {
            return nil
        }
        return mealPlan.recipe(in: recipes)
    }

    func removeMealPlan(for date: Date, mealTime: MealTime) {
        mealPlanningManager.removeMealPlan(for: date, mealTime: mealTime)
        if mealPlanningManager.mealPlan(for: date, mealTime: mealTime) == nil {
            selectedMealTimes.remove(mealTime)
        }
    }

    /// When the selected day's meal in this slot is eaten (its reminder time, else the slot's usual time).
    func minuteOfDay(_ mealTime: MealTime) -> Int {
        mealPlanningManager.mealPlan(for: selectedDate, mealTime: mealTime)?.minuteOfDay() ?? mealTime.defaultMinuteOfDay
    }

    /// Selects `date`. A dragged order belongs to the day it was made on, so each day opens in time order.
    func openDay(_ date: Date) {
        selectedDate = date
        updateSelectedMealTimes(for: date)
        reorderDayByTime()
    }

    /// Puts the selected day's meals in the order they're eaten (on opening a day, or when a reminder time moves).
    func reorderDayByTime() {
        orderedMealTimes = MealPlanningManager.sortedOrderedMealTimes(
            existing: [], selected: selectedMealTimes, minuteOfDay: minuteOfDay)
    }

    func updateSelectedMealTimes(for date: Date) {
        let mealsForDate = shownPlans(for: date)
        selectedMealTimes = Set(mealsForDate.map { $0.mealTime })
    }

    // MARK: - Clear past plans

    var clearPastTitle: String {
        let count = mealPlanningManager.pastPlanCount(keepingCookedIn: recipes)
        return count == 1 ? "Clear 1 past plan?" : "Clear \(count) past plans?"
    }

    func askToClearPastPlans() {
        guard mealPlanningManager.pastPlanCount(keepingCookedIn: recipes) > 0 else {
            weekShoppingFeedback = "No past plans to clear"
            return
        }
        showClearPastConfirm = true
    }

    func clearPastPlans() {
        withAnimation(.appGentle) {
            mealPlanningManager.clearPastMealPlans(keepingCookedIn: recipes)
            updateSelectedMealTimes(for: selectedDate)
        }
        HapticManager.shared.success()
    }

    // MARK: - Reminders

    func editReminder(for mealTime: MealTime) {
        guard let plan = mealPlanningManager.mealPlan(for: selectedDate, mealTime: mealTime) else { return }
        reminderContext = ReminderContext(
            mealTime: mealTime,
            recipeName: getRecipe(for: selectedDate, mealTime: mealTime)?.name ?? plan.recipeName,
            initialTime: plan.reminderTime ?? mealTime.defaultReminderTime
        )
        HapticManager.shared.light()
    }

    func saveReminder(_ time: Date, for mealTime: MealTime) {
        guard var plan = mealPlanningManager.mealPlan(for: selectedDate, mealTime: mealTime) else { return }
        plan.reminderTime = time
        // Reminders are useless without permission; prompt on first opt-in (no-op if already granted).
        NotificationManager.shared.requestPermission { _ in }
        mealPlanningManager.updateMealPlan(plan)
        reorderDayByTime()
        HapticManager.shared.success()
    }

    func removeReminder(for mealTime: MealTime) {
        guard var plan = mealPlanningManager.mealPlan(for: selectedDate, mealTime: mealTime) else { return }
        plan.reminderTime = nil
        mealPlanningManager.updateMealPlan(plan)
        reorderDayByTime()
        HapticManager.shared.light()
    }

    // MARK: - Plan my week

    /// The week the deck plans (see `PlanDeck.weekToPlan`); nil hides the button.
    var deckWeek: Date? {
        let today = Date()
        // Plans from this week's start on (past weeks never count); four weeks ahead is as far as the deck looks.
        guard let thisWeek = mealCalendar.weekRange(containing: today)?.start,
              let shown = currentWeekStart else { return nil }
        let first = max(thisWeek, shown)
        let plans = (0...4).flatMap { offset in
            Calendar.current.date(byAdding: .weekOfYear, value: offset, to: first)
                .map { mealPlanningManager.mealPlansForWeek(starting: $0).meals } ?? []
        }
        // Weekly dinners count for weeks not yet filled with their copies, so the deck never opens on a full week.
        return PlanDeck.weekToPlan(showing: selectedDate, plans: plans + mealPlanningManager.recurringMealPlans,
                                   today: today)
    }

    /// "Plan my week" for the shown week, else names the week it will plan.
    func deckTitle(for week: Date) -> String {
        guard let shown = currentWeekStart, Calendar.current.isDate(week, inSameDayAs: shown) else {
            return "Plan week of \(week.formatted(.dateTime.day().month(.abbreviated)))"
        }
        return "Plan my week"
    }

    func openPlanDeck() {
        guard let week = deckWeek else { return }
        if let shown = currentWeekStart, !Calendar.current.isDate(week, inSameDayAs: shown) {
            // The shown week is planned (or past): move to the week being planned, so its dinners show under the deck.
            showWeek(of: week)
        }
        guard let start = currentWeekStart else { return }
        let plans = mealPlanningManager.mealPlansForWeek(starting: start).meals
        let expiring = kitchenManager.inventoryItems
            .filter(\.isExpiringSoon)
            .sorted { ($0.daysUntilExpiry ?? .max) < ($1.daysUntilExpiry ?? .max) }
            .map(\.name)
        planDeck = PlanDeck(
            days: PlanDeck.emptyDinnerDays(week: daysInCurrentWeek, plans: plans, today: Date()),
            recipes: recipes, plannedThisWeek: plans, expiringItemNames: expiring,
            recentlyPassed: mealPlanningManager.recentlyPassedDinners(),
            seed: UInt64.random(in: .min ... .max)
        )
        HapticManager.shared.light()
    }

    /// Saved as each card is planned, so closing part-way keeps what was picked.
    func savePick(_ pick: PlanDeck.Pick) {
        mealPlanningManager.addMealPlan(MealPlanModel(
            recipeId: pick.recipe.id, recipeName: pick.recipe.name, date: pick.day,
            mealTime: .dinner, servings: pick.recipe.currentServings
        ))
    }

    /// Saved as each card is passed on, like picks, so a closed or killed app keeps it.
    func rememberPass(_ recipe: RecipeModel) {
        mealPlanningManager.rememberPassedDinner(recipe.id)
    }

    func closePlanDeck() {
        planDeck = nil
        updateSelectedMealTimes(for: selectedDate)
    }

    // MARK: - Week of dinners

    /// Every plan in the shown week (all meal times).
    var currentWeekPlans: [MealPlanModel] {
        currentWeekStart.map { mealPlanningManager.mealPlansForWeek(starting: $0).meals } ?? []
    }

    /// A day's plans as Plan shows them: past days only what was cooked (`MealPlanModel.isShown`).
    func shownPlans(for date: Date) -> [MealPlanModel] {
        let now = Date()
        return mealPlanningManager.mealPlans(for: date).filter { $0.isShown(now: now, recipes: recipes) }
    }

    /// The shown week as seven dinner photos.
    var weekNights: [WeekDinners.Night] {
        let now = Date()
        // A past night shows its dinner only if it was cooked; an uncooked one is just a dimmed, empty night.
        return WeekDinners.nights(week: daysInCurrentWeek,
                                  plans: currentWeekPlans.filter { $0.isShown(now: now, recipes: recipes) },
                                  recipes: recipes, today: now)
    }

    /// An empty night's photo: picks that night and opens the recipe picker for its dinner.
    func planDinner(on night: Date) {
        openDay(night)
        mealPlanSheet = .recipeSelection(.dinner)
    }

    /// Hold → move: the dinner takes the new night; a dinner already there swaps back to the old one.
    func moveDinner(_ dinner: MealPlanModel, to night: Date) {
        let changed = WeekDinners.move(dinner, to: night, plans: currentWeekPlans, today: Date())
        guard !changed.isEmpty else { return }
        withAnimation(.appGentle) {
            for plan in changed { mealPlanningManager.updateMealPlan(plan) }
            updateSelectedMealTimes(for: selectedDate)
        }
    }

    func removeDinner(_ dinner: MealPlanModel) {
        withAnimation(.appGentle) {
            removeMealPlan(for: dinner.date, mealTime: .dinner)
            updateSelectedMealTimes(for: selectedDate)
        }
    }

    // MARK: - Week navigation

    func previousWeek() {
        moveWeek(by: -1)
    }

    func nextWeek() {
        moveWeek(by: 1)
    }

    private func moveWeek(by weeks: Int) {
        showWeek(of: Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: selectedDate) ?? selectedDate)
    }

    func showWeek(of date: Date) {
        selectedDate = date
        if let start = currentWeekStart {
            mealPlanningManager.propagateRecurring(toWeekStarting: start)
        }
        openDay(date)
        HapticManager.shared.light()
    }
}
