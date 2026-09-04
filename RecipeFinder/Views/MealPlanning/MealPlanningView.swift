import SwiftUI

struct MealPlanningView: View {
    @Binding var recipes: [RecipeModel]
    @ObservedObject private var mealPlanningManager = MealPlanningManager.shared
    @State private var selectedDate: Date = Date()
    @State private var showMealTimeSelector = false
    @State private var selectedMealTimes: Set<MealTime> = []
    @State private var showRecipeSelector = false
    @State private var showQuickSnackSheet = false
    @State private var currentMealTime: MealTime?
    @State private var viewMode: ViewMode = .calendar
    @State private var showMonthYearPicker = false
    @State private var weekShoppingFeedback: String?

    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @Environment(\.colorScheme) var colorScheme

    /// Pure date math for the calendar and weekly views; see `MealPlanCalendar`.
    private let mealCalendar = MealPlanCalendar()

    enum ViewMode {
        case calendar
        case weeklyView
    }

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

                viewModePicker
                    .padding(.top, AppTheme.spacing16)

                ScrollView {
                    VStack(spacing: AppTheme.spacing32) {
                        if viewMode == .calendar {
                            calendarView
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            weeklyPlanView
                                .transition(.scale.combined(with: .opacity))
                        }

                        if !selectedMealTimes.isEmpty {
                            selectedMealsSection
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        } else if Calendar.current.isDate(selectedDate, inSameDayAs: Date()) || hasMealPlans(for: selectedDate) || selectedDate > Date().addingTimeInterval(-86400) {
                            selectedDayEmptyState
                                .transition(.opacity)
                        } else {
                            emptyStateView
                                .transition(.opacity)
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
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewMode)
        .sheet(isPresented: $showMealTimeSelector) {
            MealTimeSelectorSheet(
                selectedDate: selectedDate,
                selectedMealTimes: $selectedMealTimes,
                onContinue: { mealTime in
                    currentMealTime = mealTime
                    showMealTimeSelector = false
                    if mealTime == .snack {
                        showQuickSnackSheet = true
                    } else {
                        showRecipeSelector = true
                    }
                }
            )
        }
        .sheet(isPresented: $showRecipeSelector) {
            RecipeSelectionSheet(
                recipes: $recipes,
                mealTime: currentMealTime,
                onSelectExisting: { recipe in
                    if let mealTime = currentMealTime {
                        saveMealPlan(recipe: recipe, for: selectedDate, mealTime: mealTime)
                    }
                    showRecipeSelector = false
                    currentMealTime = nil
                }
            )
        }
        .sheet(isPresented: $showQuickSnackSheet) {
            QuickSnackSheet(recipes: $recipes) { snackRecipe in
                if let mealTime = currentMealTime {
                    saveMealPlan(recipe: snackRecipe, for: selectedDate, mealTime: mealTime)
                }
                showQuickSnackSheet = false
                currentMealTime = nil
            }
        }
        .sheet(isPresented: $showMonthYearPicker) {
            MonthYearPickerSheet(selectedDate: $selectedDate)
        }
    }

    // MARK: - Sections

    private var viewModePicker: some View {
        GeometryReader { geometry in
            HStack(spacing: AppTheme.spacing12) {
                ForEach([ViewMode.calendar, ViewMode.weeklyView], id: \.self) { mode in
                    Button(action: {
                        viewMode = mode
                        HapticManager.shared.light()
                    }) {
                        HStack(spacing: AppTheme.spacing6) {
                            Image(systemName: mode == .calendar ? "calendar" : "list.bullet")
                                .font(.system(size: AppTheme.fontSize14, weight: .semibold))
                            Text(mode == .calendar ? "Calendar" : "Weekly")
                                .font(.system(size: AppTheme.fontSize14, weight: .semibold))
                        }
                        .foregroundColor(viewMode == mode ? AppTheme.textColor(for: colorScheme) : AppTheme.textColor(for: colorScheme, opacity: 0.6))
                        .padding(.horizontal, AppTheme.spacing16)
                        .padding(.vertical, AppTheme.spacing10)
                        .background {
                            if viewMode == mode {
                                Capsule()
                                    .fill(colorScheme == .dark ? Color.white.opacity(AppTheme.overlayLightOpacity) : Color.black.opacity(0.15))
                            } else {
                                Capsule()
                                    .stroke(colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(AppTheme.shadowDarkOpacity), lineWidth: 1)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppTheme.spacing20)
            .padding(.bottom, max(20, geometry.size.height * 0.025))
        }
        .frame(height: AppTheme.height50)
    }

    private var calendarView: some View {
        MonthCalendarView(
            selectedDate: selectedDate,
            days: compactDaysInMonth,
            monthYearString: monthYearString,
            cardStyle: cardStyle,
            colorScheme: colorScheme,
            selectedTheme: selectedTheme,
            hasPlannedMeals: { hasMealPlans(for: $0) },
            onPreviousMonth: previousMonth,
            onNextMonth: nextMonth,
            onShowMonthPicker: {
                showMonthYearPicker = true
                HapticManager.shared.light()
            },
            onSelectDay: { date in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedDate = date
                    updateSelectedMealTimes(for: date)
                    showMealTimeSelector = true
                }
                HapticManager.shared.light()
            }
        )
    }

    private var weeklyPlanView: some View {
        WeeklyPlanView(
            days: daysInCurrentWeek,
            weekRangeString: weekRangeString,
            weekHasPlannedMeals: weekHasPlannedMeals,
            weekShoppingFeedback: weekShoppingFeedback,
            cardStyle: cardStyle,
            colorScheme: colorScheme,
            selectedTheme: selectedTheme,
            onPreviousWeek: previousWeek,
            onNextWeek: nextWeek,
            onAddMeal: { date in
                selectedDate = date
                showMealTimeSelector = true
                HapticManager.shared.light()
            },
            onAddWeekToShoppingList: addWeekToShoppingList
        )
    }

    private var selectedMealsSection: some View {
        PlannedMealsSection(
            mealTimes: Array(selectedMealTimes).sorted(by: { $0.sortOrder < $1.sortOrder }),
            selectedDateString: selectedDateString,
            cardStyle: cardStyle,
            colorScheme: colorScheme,
            selectedTheme: selectedTheme,
            recipeFor: { getRecipe(for: selectedDate, mealTime: $0) },
            onSelectMealTime: { mealTime in
                currentMealTime = mealTime
                showRecipeSelector = true
                HapticManager.shared.light()
            },
            onRemove: { mealTime in
                withAnimation {
                    removeMealPlan(for: selectedDate, mealTime: mealTime)
                }
                HapticManager.shared.success()
            },
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

    private func hasMealPlans(for date: Date) -> Bool {
        return mealPlanningManager.hasMealPlans(for: date)
    }

    private func updateSelectedMealTimes(for date: Date) {
        let mealsForDate = mealPlanningManager.mealPlans(for: date)
        selectedMealTimes = Set(mealsForDate.map { $0.mealTime })
    }

    private func addWeekToShoppingList() {
        guard let start = currentWeekStart else { return }

        let summary = mealPlanningManager.weekShoppingSummary(forWeekStarting: start, recipes: recipes)

        for item in summary.items {
            ShoppingListManager.shared.addItem(name: item.name, quantity: item.quantity, category: nil)
        }

        guard !summary.isEmpty else { return }

        if summary.items.isEmpty {
            HapticManager.shared.error()
            showWeekShoppingFeedback("Couldn't find this week's recipes in your collection")
            return
        }

        HapticManager.shared.success()

        var message = "Added \(summary.items.count) item\(summary.items.count == 1 ? "" : "s") from \(summary.mealsCovered) meal\(summary.mealsCovered == 1 ? "" : "s")"
        if !summary.missingRecipeNames.isEmpty {
            message += " · \(summary.missingRecipeNames.count) recipe\(summary.missingRecipeNames.count == 1 ? "" : "s") not found"
        }
        showWeekShoppingFeedback(message)
    }

    private func showWeekShoppingFeedback(_ message: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            weekShoppingFeedback = message
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.animationDelayFeedback) {
            withAnimation(.easeOut(duration: AppTheme.animationDuration08)) {
                weekShoppingFeedback = nil
            }
        }
    }

    private func previousMonth() {
        selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
        HapticManager.shared.light()
    }

    private func nextMonth() {
        selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
        HapticManager.shared.light()
    }

    private func previousWeek() {
        selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
        HapticManager.shared.light()
    }

    private func nextWeek() {
        selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
        HapticManager.shared.light()
    }

    // MARK: - Derived date values

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }

    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: selectedDate)
    }

    private var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: selectedDate)
    }

    private var weekRangeString: String {
        guard let range = mealCalendar.weekRange(containing: selectedDate) else {
            return ""
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        let startString = formatter.string(from: range.start)
        let endString = formatter.string(from: range.end)

        return "\(startString) - \(endString)"
    }

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

    private var compactDaysInMonth: [Date?] {
        mealCalendar.monthGrid(containing: selectedDate)
    }
}

#Preview {
    MealPlanningView(recipes: .constant([]))
}
