import SwiftUI

struct MealPlanningView: View {
    @Environment(\.recipeStore) private var recipeStore
    private var recipes: [RecipeModel] { recipeStore.recipes }
    @Environment(\.mealPlanning) private var mealPlanningManager
    @Environment(\.kitchen) private var kitchenManager
    @State private var selectedDate: Date = Date()
    @State private var showMealTimeSelector = false
    @State private var selectedMealTimes: Set<MealTime> = []
    @State private var mealPlanSheet: MealPlanSheet?

    /// One Identifiable target for the recipe-picker / quick-snack sheets so content rebuilds from the value
    /// (`.sheet(item:)`) instead of reading a `currentMealTime` set in the same action — which rendered the
    /// sheet with a nil meal time on first present.
    private enum MealPlanSheet: Identifiable {
        case recipeSelection(MealTime)
        case quickSnack(MealTime)

        var id: String {
            switch self {
            case .recipeSelection(let mealTime): "recipe-\(mealTime)"
            case .quickSnack(let mealTime): "snack-\(mealTime)"
            }
        }
    }
    @State private var weekShoppingFeedback: String?
    /// Display order for the selected day's meal cards; persists drag order within a day.
    @State private var orderedMealTimes: [MealTime] = []
    @State private var pantryExpirySuggestions: [PantryExpirySuggestions.Match] = []
    /// Non-nil while the user is picking a time slot for a pantry-suggested recipe.
    @State private var pendingSuggestedRecipe: RecipeModel?
    /// Deduped items awaiting confirmation before being added to Groceries.
    @State private var weekAddCandidates: [WeekShoppingSummary.Item] = []
    @State private var weekMealsCovered = 0
    @State private var weekSkippedInKitchen = 0
    @State private var showAddWeekConfirm = false
    /// Non-nil while the meal-reminder time picker is presented.
    @State private var reminderContext: ReminderContext?

    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @Environment(\.colorScheme) var colorScheme

    private let mealCalendar = MealPlanCalendar()

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                MealPlannerHeader(
                    onAddMeal: {
                        HapticManager.shared.light()
                        showMealTimeSelector = true
                    },
                    onClearOldPlans: {
                        selectedMealTimes.removeAll()
                        mealPlanningManager.clearOldMealPlans()
                        HapticManager.shared.light()
                    }
                )

                ScrollView {
                    VStack(spacing: AppTheme.spacing20) {
                        weekStripView

                        if !pantryExpirySuggestions.isEmpty {
                            ExpiryRecipeSuggestionsSection(
                                suggestions: pantryExpirySuggestions,
                                cardStyle: cardStyle,
                                colorScheme: colorScheme,
                                selectedTheme: selectedTheme,
                                onPlan: { recipe in
                                    pendingSuggestedRecipe = recipe
                                    showMealTimeSelector = true
                                    HapticManager.shared.light()
                                }
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        if !selectedMealTimes.isEmpty {
                            selectedMealsSection
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        } else if Calendar.current.isDate(selectedDate, inSameDayAs: Date())
                            || hasMealPlans(for: selectedDate)
                            || selectedDate > Date().addingTimeInterval(-86400) {
                            selectedDayEmptyState
                                .transition(.opacity)
                        } else {
                            emptyStateView
                                .transition(.opacity)
                        }

                        if weekHasPlannedMeals {
                            weekShoppingSection
                        }
                    }
                    .padding(.top, AppTheme.spacing16)
                    .padding(.horizontal, AppTheme.spacing20)
                    .padding(.bottom, AppTheme.spacing100)
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedMealTimes)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: pantryExpirySuggestions.count)
        .confirmationDialog("Add to Groceries", isPresented: $showAddWeekConfirm, titleVisibility: .visible) {
            Button("Add \(weekAddCandidates.count) item\(weekAddCandidates.count == 1 ? "" : "s")") {
                confirmAddWeek()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(weekAddConfirmMessage)
        }
        .toast($weekShoppingFeedback)
        .onAppear {
            if let start = currentWeekStart {
                mealPlanningManager.propagateRecurring(toWeekStarting: start)
            }
            updateSelectedMealTimes(for: selectedDate)
            orderedMealTimes = MealPlanningManager.sortedOrderedMealTimes(
                existing: [], selected: selectedMealTimes)
            updatePantryExpirySuggestions()
        }
        .onChange(of: selectedMealTimes) { _, newMealTimes in
            orderedMealTimes = MealPlanningManager.sortedOrderedMealTimes(
                existing: orderedMealTimes, selected: newMealTimes)
        }
        .onChange(of: kitchenManager.inventoryItems) { _, _ in
            updatePantryExpirySuggestions()
        }
        .onChange(of: recipes.count) { _, _ in
            updatePantryExpirySuggestions()
        }
        .sheet(isPresented: $showMealTimeSelector, onDismiss: { pendingSuggestedRecipe = nil }) {
            MealTimeSelectorSheet(
                selectedDate: selectedDate,
                selectedMealTimes: $selectedMealTimes,
                onContinue: { mealTime in
                    showMealTimeSelector = false
                    if let suggested = pendingSuggestedRecipe {
                        saveMealPlan(recipe: suggested, for: selectedDate, mealTime: mealTime)
                        pendingSuggestedRecipe = nil
                    } else if mealTime == .snack {
                        mealPlanSheet = .quickSnack(mealTime)
                    } else {
                        mealPlanSheet = .recipeSelection(mealTime)
                    }
                }
            )
        }
        .sheet(item: $mealPlanSheet) { sheet in
            switch sheet {
            case .recipeSelection(let mealTime):
                RecipeSelectionSheet(
                    mealTime: mealTime,
                    onSelectExisting: { recipe in
                        saveMealPlan(recipe: recipe, for: selectedDate, mealTime: mealTime)
                        mealPlanSheet = nil
                    }
                )
            case .quickSnack(let mealTime):
                QuickSnackSheet { snackRecipe in
                    saveMealPlan(recipe: snackRecipe, for: selectedDate, mealTime: mealTime)
                    mealPlanSheet = nil
                }
            }
        }
        .sheet(item: $reminderContext) { context in
            MealReminderSheet(
                mealTime: context.mealTime,
                recipeName: context.recipeName,
                initialTime: context.initialTime,
                onSave: { time in
                    saveReminder(time, for: context.mealTime)
                    reminderContext = nil
                },
                onCancel: { reminderContext = nil }
            )
        }
    }

    // MARK: - Sections

    private var weekStripView: some View {
        WeekStripView(
            week: daysInCurrentWeek,
            selectedDate: selectedDate,
            monthYearString: monthYearString,
            cardStyle: cardStyle,
            colorScheme: colorScheme,
            selectedTheme: selectedTheme,
            mealTimesFor: { date in
                mealPlanningManager.mealPlans(for: date).map { $0.mealTime }
            },
            onSelectDate: { date in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedDate = date
                    updateSelectedMealTimes(for: date)
                }
                HapticManager.shared.light()
            },
            onPreviousWeek: previousWeek,
            onNextWeek: nextWeek
        )
    }

    private var selectedMealsSection: some View {
        PlannedMealsSection(
            mealTimes: $orderedMealTimes,
            selectedDateString: selectedDateString,
            cardStyle: cardStyle,
            colorScheme: colorScheme,
            selectedTheme: selectedTheme,
            recipeFor: { getRecipe(for: selectedDate, mealTime: $0) },
            mealPlanFor: { mealPlanningManager.mealPlan(for: selectedDate, mealTime: $0) },
            onSelectMealTime: { mealTime in
                mealPlanSheet = .recipeSelection(mealTime)
                HapticManager.shared.light()
            },
            onRemove: { mealTime in
                withAnimation {
                    removeMealPlan(for: selectedDate, mealTime: mealTime)
                }
                HapticManager.shared.success()
            },
            onToggleRecurring: { mealTime in
                if let plan = mealPlanningManager.mealPlan(for: selectedDate, mealTime: mealTime) {
                    mealPlanningManager.toggleRecurring(plan)
                }
            },
            onEditReminder: editReminder,
            onRemoveReminder: removeReminder,
            onAddAnother: {
                showMealTimeSelector = true
                HapticManager.shared.light()
            }
        )
    }

    private var selectedDayEmptyState: some View {
        SelectedDayEmptyStateView(
            selectedDateString: selectedDateString,
            shortDateString: shortDateString,
            cardStyle: cardStyle,
            colorScheme: colorScheme,
            onAddMeal: {
                showMealTimeSelector = true
                HapticManager.shared.light()
            }
        )
    }

    private var emptyStateView: some View {
        MealPlanEmptyStateView(
            onPlanMeal: {
                showMealTimeSelector = true
                HapticManager.shared.light()
            }
        )
    }

    private var weekShoppingSection: some View {
        PrimaryButton("Add Week to Groceries", systemImage: "cart.badge.plus", fillWidth: true, action: prepareAddWeek)
    }

    // MARK: - Pantry suggestions

    private func updatePantryExpirySuggestions() {
        let currentRecipes = recipes
        let currentInventory = kitchenManager.inventoryItems
        Task {
            let matches = await Task.detached(priority: .userInitiated) {
                PantryExpirySuggestions.matches(recipes: currentRecipes, inventoryItems: currentInventory)
            }.value
            pantryExpirySuggestions = matches
        }
    }

    // MARK: - Meal plan actions

    private func saveMealPlan(recipe: RecipeModel, for date: Date, mealTime: MealTime) {
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

    private func getRecipe(for date: Date, mealTime: MealTime) -> RecipeModel? {
        guard let mealPlan = mealPlanningManager.mealPlan(for: date, mealTime: mealTime) else {
            return nil
        }
        return recipes.first { $0.id == mealPlan.recipeId }
    }

    private func removeMealPlan(for date: Date, mealTime: MealTime) {
        mealPlanningManager.removeMealPlan(for: date, mealTime: mealTime)
        if mealPlanningManager.mealPlan(for: date, mealTime: mealTime) == nil {
            selectedMealTimes.remove(mealTime)
        }
    }

    // MARK: - Reminders

    private func editReminder(for mealTime: MealTime) {
        guard let plan = mealPlanningManager.mealPlan(for: selectedDate, mealTime: mealTime) else { return }
        reminderContext = ReminderContext(
            mealTime: mealTime,
            recipeName: getRecipe(for: selectedDate, mealTime: mealTime)?.name ?? plan.recipeName,
            initialTime: plan.reminderTime ?? mealTime.defaultReminderTime
        )
        HapticManager.shared.light()
    }

    private func saveReminder(_ time: Date, for mealTime: MealTime) {
        guard var plan = mealPlanningManager.mealPlan(for: selectedDate, mealTime: mealTime) else { return }
        plan.reminderTime = time
        // Reminders are useless without permission; prompt on first opt-in (no-op if already granted).
        NotificationManager.shared.requestPermission { _ in }
        mealPlanningManager.updateMealPlan(plan)
        HapticManager.shared.success()
    }

    private func removeReminder(for mealTime: MealTime) {
        guard var plan = mealPlanningManager.mealPlan(for: selectedDate, mealTime: mealTime) else { return }
        plan.reminderTime = nil
        mealPlanningManager.updateMealPlan(plan)
        HapticManager.shared.light()
    }

    private func hasMealPlans(for date: Date) -> Bool {
        mealPlanningManager.hasMealPlans(for: date)
    }

    private func updateSelectedMealTimes(for date: Date) {
        let mealsForDate = mealPlanningManager.mealPlans(for: date)
        selectedMealTimes = Set(mealsForDate.map { $0.mealTime })
    }

    /// Computes what the week would add, skipping items already in the Kitchen, then asks for confirmation rather than bulk-dumping.
    private func prepareAddWeek() {
        guard let start = currentWeekStart else { return }
        let summary = mealPlanningManager.weekShoppingSummary(forWeekStarting: start, recipes: recipes)

        let inKitchen = Set(
            (kitchenManager.items.map(\.name) + kitchenManager.inventoryItems.map(\.name))
                .map { IngredientNormalizer.normalize($0) }
        )
        let candidates = summary.items.filter { !inKitchen.contains(IngredientNormalizer.normalize($0.name)) }

        weekAddCandidates = candidates
        weekMealsCovered = summary.mealsCovered
        weekSkippedInKitchen = summary.items.count - candidates.count

        guard !candidates.isEmpty else {
            let message: String
            if summary.items.isEmpty {
                message = summary.missingRecipeNames.isEmpty
                    ? "No planned meals to shop for"
                    : "Couldn't find this week's recipes"
            } else {
                message = "You already have everything in your kitchen"
            }
            showWeekShoppingFeedback(message)
            return
        }

        showAddWeekConfirm = true
    }

    private func confirmAddWeek() {
        for item in weekAddCandidates {
            ShoppingListManager.shared.addItem(name: item.name, quantity: item.quantity, unit: item.unit, category: nil)
        }
        HapticManager.shared.success()

        var message = "Added \(weekAddCandidates.count) item\(weekAddCandidates.count == 1 ? "" : "s") from \(weekMealsCovered) meal\(weekMealsCovered == 1 ? "" : "s")"
        if weekSkippedInKitchen > 0 {
            message += " · \(weekSkippedInKitchen) already in kitchen"
        }
        showWeekShoppingFeedback(message)
    }

    private var weekAddConfirmMessage: String {
        var parts = ["From \(weekMealsCovered) planned meal\(weekMealsCovered == 1 ? "" : "s")."]
        if weekSkippedInKitchen > 0 {
            parts.append("\(weekSkippedInKitchen) already in your kitchen will be skipped.")
        }
        return parts.joined(separator: " ")
    }

    private func showWeekShoppingFeedback(_ message: String) {
        weekShoppingFeedback = message
    }

    private func previousWeek() {
        selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
        propagateRecurringForCurrentWeek()
        updateSelectedMealTimes(for: selectedDate)
        HapticManager.shared.light()
    }

    private func nextWeek() {
        selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
        propagateRecurringForCurrentWeek()
        updateSelectedMealTimes(for: selectedDate)
        HapticManager.shared.light()
    }

    private func propagateRecurringForCurrentWeek() {
        guard let start = mealCalendar.weekRange(containing: selectedDate)?.start else { return }
        mealPlanningManager.propagateRecurring(toWeekStarting: start)
    }

    // MARK: - Derived date values

    // DateFormatter init is expensive; static lets are built once and reused since body runs on every change.
    private static let monthYearFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f
    }()
    private static let mediumDateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMM d, yyyy"; return f
    }()
    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMM d"; return f
    }()

    private var monthYearString: String { Self.monthYearFormatter.string(from: selectedDate) }
    private var selectedDateString: String { Self.mediumDateFormatter.string(from: selectedDate) }
    private var shortDateString: String { Self.shortDateFormatter.string(from: selectedDate) }

    private var currentWeekStart: Date? {
        mealCalendar.weekRange(containing: selectedDate)?.start
    }

    private var weekHasPlannedMeals: Bool {
        guard let start = currentWeekStart else { return false }
        return mealPlanningManager.mealPlansForWeek(starting: start).meals.contains { !$0.isCompleted }
    }

    private var daysInCurrentWeek: [Date] {
        mealCalendar.daysInWeek(containing: selectedDate)
    }
}

/// Identifiable payload driving the meal-reminder time-picker sheet.
private struct ReminderContext: Identifiable {
    let id = UUID()
    let mealTime: MealTime
    let recipeName: String
    let initialTime: Date
}

#Preview {
    MealPlanningView()
}
