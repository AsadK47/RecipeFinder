import SwiftUI

struct MealPlanningView: View {
    @Environment(\.recipeStore) var recipeStore
    var recipes: [RecipeModel] { recipeStore.recipes }
    @Environment(\.mealPlanning) var mealPlanningManager
    @Environment(\.kitchen) var kitchenManager
    @State var selectedDate: Date = Date()
    @State var showMealTimeSelector = false
    @State var selectedMealTimes: Set<MealTime> = []
    @State var mealPlanSheet: MealPlanSheet?
    @State var weekShoppingFeedback: String?
    /// Display order for the selected day's meal cards; persists drag order within a day.
    @State private var orderedMealTimes: [MealTime] = []
    @State private var pantryExpirySuggestions: [PantryExpirySuggestions.Match] = []
    /// Non-nil while the user is picking a time slot for a pantry-suggested recipe.
    @State private var pendingSuggestedRecipe: RecipeModel?
    /// The week's items to buy (minus what's at home) and their copy, awaiting confirmation.
    @State var weekPlan = WeekGroceryPlan.empty
    @State var showAddWeekConfirm = false
    /// Non-nil while the meal-reminder time picker is presented.
    @State var reminderContext: ReminderContext?
    /// Non-nil while "Plan my week" is dealing cards.
    @State var planDeck: PlanDeck?
    /// Set by tapping a dinner photo: pushes the recipe straight into cooking mode.
    @State var cookingRecipe: RecipeModel?

    let mealCalendar = MealPlanCalendar()

    var body: some View {
        // A stack of its own so a dinner photo can push its recipe into cooking (same as Today's "Cook this").
        NavigationStack {
            planner
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(item: $cookingRecipe) { recipe in
                    RecipeDetailView(recipe: recipe, startsCooking: true)
                }
        }
    }

    private var planner: some View {
        ZStack {
            AppBackground()

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

                        if hasEmptyDinners {
                            PrimaryButton("Plan my week", systemImage: "rectangle.stack.fill", fillWidth: true,
                                          action: openPlanDeck)
                                .accessibilityIdentifier("plan.planMyWeek")
                        }

                        weekDinnersSection

                        if !pantryExpirySuggestions.isEmpty {
                            ExpiryRecipeSuggestionsSection(
                                suggestions: pantryExpirySuggestions,
                                onPlan: { recipe in
                                    pendingSuggestedRecipe = recipe
                                    showMealTimeSelector = true
                                    HapticManager.shared.light()
                                }
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        switch dayContent {
                        case .plannedMeals:
                            selectedMealsSection
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        case .emptyDay:
                            selectedDayEmptyState
                                .transition(.opacity)
                        case .emptyPast:
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
            // The deck is drawn over the planner, not presented, so keep VoiceOver from reaching what's under it.
            .accessibilityHidden(planDeck != nil)

            if let shown = planDeck {
                // Not `Binding($planDeck)`: that binding force-reads the optional, and the deck's removal animation
                // reads it again after Close set it to nil (crashed). Writes after Close are dropped too, so a card
                // change still in flight can't reopen the deck.
                PlanDeckView(
                    deck: Binding(get: { planDeck ?? shown }, set: { if planDeck != nil { planDeck = $0 } }),
                    onPlan: savePick, onClose: closePlanDeck
                )
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }
        }
        .toolbar(planDeck == nil ? .visible : .hidden, for: .tabBar)
        .animation(.appGentle, value: planDeck == nil)
        .appNavigationChrome()
        .animation(.appGentle, value: selectedMealTimes)
        .animation(.appGentle, value: pantryExpirySuggestions.count)
        .confirmationDialog("Add to Groceries", isPresented: $showAddWeekConfirm, titleVisibility: .visible) {
            Button(weekPlan.addButtonTitle) {
                confirmAddWeek()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(weekPlan.confirmMessage)
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

    private var weekDinnersSection: some View {
        WeekDinnersView(
            nights: weekNights,
            onCook: { cookingRecipe = $0 },
            onPlan: planDinner,
            onMove: moveDinner,
            onRemove: removeDinner
        )
    }

    private var selectedMealsSection: some View {
        PlannedMealsSection(
            mealTimes: $orderedMealTimes,
            selectedDateString: selectedDateString,
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

    // MARK: - Derived values

    // FormatStyle follows the user's locale (field order, month names); fixed dateFormat strings didn't.
    private var monthYearString: String { selectedDate.formatted(.dateTime.month(.wide).year()) }
    private var selectedDateString: String { selectedDate.formatted(.dateTime.month(.abbreviated).day().year()) }
    private var shortDateString: String { selectedDate.formatted(.dateTime.month(.abbreviated).day()) }

    var currentWeekStart: Date? {
        mealCalendar.weekRange(containing: selectedDate)?.start
    }

    private var dayContent: MealPlanDayContent {
        MealPlanDayContent.make(hasSelectedMeals: !selectedMealTimes.isEmpty,
                                hasPlans: mealPlanningManager.hasMealPlans(for: selectedDate),
                                date: selectedDate, now: Date())
    }

    private var weekHasPlannedMeals: Bool {
        guard let start = currentWeekStart else { return false }
        return mealPlanningManager.mealPlansForWeek(starting: start).meals.contains { !$0.isCompleted }
    }

    var daysInCurrentWeek: [Date] {
        mealCalendar.daysInWeek(containing: selectedDate)
    }
}

#Preview {
    MealPlanningView()
}
