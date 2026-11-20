import SwiftUI

// Plan's actions — saving/removing meals, reminders, week navigation and "Add Week to Groceries" — split from
// MealPlanningView (Smell Batch D). The groceries maths and copy are pure and tested (`WeekGroceryPlan`).
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
        return recipes.first { $0.id == mealPlan.recipeId }
    }

    func removeMealPlan(for date: Date, mealTime: MealTime) {
        mealPlanningManager.removeMealPlan(for: date, mealTime: mealTime)
        if mealPlanningManager.mealPlan(for: date, mealTime: mealTime) == nil {
            selectedMealTimes.remove(mealTime)
        }
    }

    func updateSelectedMealTimes(for date: Date) {
        let mealsForDate = mealPlanningManager.mealPlans(for: date)
        selectedMealTimes = Set(mealsForDate.map { $0.mealTime })
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
        HapticManager.shared.success()
    }

    func removeReminder(for mealTime: MealTime) {
        guard var plan = mealPlanningManager.mealPlan(for: selectedDate, mealTime: mealTime) else { return }
        plan.reminderTime = nil
        mealPlanningManager.updateMealPlan(plan)
        HapticManager.shared.light()
    }

    // MARK: - Week to Groceries

    /// Computes what the week would add, skipping items already in the Kitchen, then asks for confirmation rather than bulk-dumping.
    func prepareAddWeek() {
        guard let start = currentWeekStart else { return }
        let summary = mealPlanningManager.weekShoppingSummary(forWeekStarting: start, recipes: recipes)
        let plan = WeekGroceryPlan(
            summary: summary,
            kitchenNames: kitchenManager.items.map(\.name) + kitchenManager.inventoryItems.map(\.name)
        )
        weekPlan = plan

        if let message = plan.nothingToAddMessage {
            weekShoppingFeedback = message
            return
        }
        showAddWeekConfirm = true
    }

    func confirmAddWeek() {
        for item in weekPlan.candidates {
            ShoppingListManager.shared.addItem(name: item.name, quantity: item.quantity, unit: item.unit, category: nil)
        }
        HapticManager.shared.success()
        weekShoppingFeedback = weekPlan.addedMessage
    }

    // MARK: - Plan my week

    /// This week's plans from today on leave at least one dinner open.
    var hasEmptyDinners: Bool {
        guard let start = currentWeekStart else { return false }
        let plans = mealPlanningManager.mealPlansForWeek(starting: start).meals
        return !PlanDeck.emptyDinnerDays(week: daysInCurrentWeek, plans: plans, today: Date()).isEmpty
    }

    func openPlanDeck() {
        guard let start = currentWeekStart else { return }
        let plans = mealPlanningManager.mealPlansForWeek(starting: start).meals
        let expiring = kitchenManager.inventoryItems
            .filter(\.isExpiringSoon)
            .sorted { ($0.daysUntilExpiry ?? .max) < ($1.daysUntilExpiry ?? .max) }
            .map(\.name)
        planDeck = PlanDeck(
            days: PlanDeck.emptyDinnerDays(week: daysInCurrentWeek, plans: plans, today: Date()),
            recipes: recipes, plannedThisWeek: plans, expiringItemNames: expiring,
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

    func closePlanDeck() {
        planDeck = nil
        updateSelectedMealTimes(for: selectedDate)
    }

    // MARK: - Week of dinners

    /// Every plan in the shown week (all meal times).
    var currentWeekPlans: [MealPlanModel] {
        currentWeekStart.map { mealPlanningManager.mealPlansForWeek(starting: $0).meals } ?? []
    }

    /// The shown week as seven dinner photos.
    var weekNights: [WeekDinners.Night] {
        WeekDinners.nights(week: daysInCurrentWeek, plans: currentWeekPlans, recipes: recipes, today: Date())
    }

    /// An empty night's photo: picks that night and opens the recipe picker for its dinner.
    func planDinner(on night: Date) {
        selectedDate = night
        updateSelectedMealTimes(for: night)
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
        updateSelectedMealTimes(for: selectedDate)
        HapticManager.shared.light()
    }
}
