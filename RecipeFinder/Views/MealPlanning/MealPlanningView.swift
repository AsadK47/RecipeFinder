import SwiftUI

struct MealPlanningView: View {
    @Binding var recipes: [RecipeModel]
    @ObservedObject private var mealPlanningManager = MealPlanningManager.shared
    @Environment(\.kitchen) private var kitchenManager
    @State private var selectedDate: Date = Date()
    @State private var showMealTimeSelector = false
    @State private var selectedMealTimes: Set<MealTime> = []
    @State private var showRecipeSelector = false
    @State private var showQuickSnackSheet = false
    @State private var currentMealTime: MealTime?
    @State private var weekShoppingFeedback: String?
    /// Display order for the selected day's meal cards; persists drag order within a day.
    @State private var orderedMealTimes: [MealTime] = []
    @State private var pantryExpirySuggestions: [PantryExpirySuggestions.Match] = []
    /// Non-nil while the user is picking a time slot for a pantry-suggested recipe.
    @State private var pendingSuggestedRecipe: RecipeModel?

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
        .sheet(isPresented: $showMealTimeSelector) {
            MealTimeSelectorSheet(
                selectedDate: selectedDate,
                selectedMealTimes: $selectedMealTimes,
                onContinue: { mealTime in
                    currentMealTime = mealTime
                    showMealTimeSelector = false
                    if let suggested = pendingSuggestedRecipe {
                        saveMealPlan(recipe: suggested, for: selectedDate, mealTime: mealTime)
                        pendingSuggestedRecipe = nil
                    } else if mealTime == .snack {
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
            onToggleRecurring: { mealTime in
                if let plan = mealPlanningManager.mealPlan(for: selectedDate, mealTime: mealTime) {
                    mealPlanningManager.toggleRecurring(plan)
                }
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

    private var weekShoppingSection: some View {
        VStack(spacing: AppTheme.spacing8) {
            Button(action: addWeekToShoppingList) {
                HStack(spacing: AppTheme.spacing8) {
                    Image(systemName: "cart.badge.plus")
                    Text("Add Week to Shopping List")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .adaptiveForegroundColor()
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.spacing12)
                .background(AppTheme.accentColor(for: selectedTheme))
                .cornerRadius(AppTheme.cornerRadius12)
            }
            .buttonStyle(PlainButtonStyle())

            if let feedback = weekShoppingFeedback {
                HStack(spacing: AppTheme.spacing8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(feedback)
                        .font(.caption)
                        .adaptiveForegroundColor(opacity: AppTheme.highEmphasisOpacity)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
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

    private func hasMealPlans(for date: Date) -> Bool {
        mealPlanningManager.hasMealPlans(for: date)
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

    // DateFormatter construction is expensive (Obj-C runtime init). Static lets are
    // created once and reused; body runs on every @ObservedObject change so this matters.
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

#Preview {
    MealPlanningView(recipes: .constant([]))
}
