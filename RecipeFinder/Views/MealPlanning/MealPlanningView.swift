import SwiftUI

struct MealPlanningView: View {
    @Environment(\.recipeStore) var recipeStore
    var recipes: [RecipeModel] { recipeStore.recipes }
    @Environment(\.mealPlanning) var mealPlanningManager
    @Environment(\.kitchen) var kitchenManager
    @State var selectedDate: Date = Date()
    /// Today as of the last look, so coming back after midnight moves a planner left on "today" to the new day.
    @State private var lastToday: Date = Date()
    @Environment(\.scenePhase) private var scenePhase
    @State var showMealTimeSelector = false
    @State var selectedMealTimes: Set<MealTime> = []
    @State var mealPlanSheet: MealPlanSheet?
    @State var weekShoppingFeedback: String?
    /// Display order for the selected day's meal cards: by time of day, or as dragged (kept until the day changes).
    @State var orderedMealTimes: [MealTime] = []
    @State private var pantryExpirySuggestions: [PantryExpirySuggestions.Match] = []
    /// Non-nil while the user is picking a time slot for a pantry-suggested recipe.
    @State private var pendingSuggestedRecipe: RecipeModel?
    @State var showClearPastConfirm = false
    /// The take-offs in a row while the toast is up: one Undo for them all (owner 2026-11-22: no confirm pop-ups).
    @State var pendingTakeOff: MealPlanTakeOff?
    @State var removalToast: String?
    /// After Undo: names meals that stayed off because another meal holds their slot now.
    @State var undoNote: String?
    /// Waits before showing `undoNote`; a new take-off calls it off so the note can't cover its toast.
    @State var undoNoteDelay = DelayedToast()
    /// Non-nil while the meal-reminder time picker is presented.
    @State var reminderContext: ReminderContext?
    /// Non-nil while "Plan my week" is dealing cards.
    @State var planDeck: PlanDeck?
    /// Set by a dinner photo: tap pushes its recipe page, the hold menu's Cook pushes it straight into cooking.
    @State var openedDinner: OpenedDinner?

    let mealCalendar = MealPlanCalendar()
    /// Set by a tapped Sunday nudge: show that day's week, then clear it.
    var weekRequest: Binding<Date?> = .constant(nil)
    /// Set by Today's "Plan the week": open the deck, then clear it.
    var deckRequest: Binding<Bool> = .constant(false)

    var body: some View {
        // A stack of its own so a dinner photo can push its recipe (or, from Cook, cooking — like Today's "Cook this").
        NavigationStack {
            planner
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(item: $openedDinner) { dinner in
                    RecipeDetailView(recipe: dinner.recipe, startsCooking: dinner.startsCooking)
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
                    onClearOldPlans: askToClearPastPlans
                )

                ScrollView {
                    VStack(spacing: AppTheme.spacing20) {
                        weekStripView

                        if let week = deckWeek {
                            PrimaryButton(deckTitle(for: week), systemImage: "rectangle.stack.fill", fillWidth: true,
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
                    }
                    .padding(.top, AppTheme.spacing16)
                    .padding(.horizontal, AppTheme.spacing20)
                    .padding(.bottom, AppTheme.spacing100)
                }
            }
            // The deck is drawn over the planner, not presented, so keep VoiceOver from reaching what's under it; the
            // planner fades out under it so only the card and its controls show (owner 2026-11-20: "background noise").
            .accessibilityHidden(planDeck != nil)
            .opacity(planDeck == nil ? 1 : 0)

            if let shown = planDeck {
                // Not `Binding($planDeck)`: that binding force-reads the optional, and the deck's removal animation
                // reads it again after Close set it to nil (crashed). Writes after Close are dropped too, so a card
                // change still in flight can't reopen the deck.
                PlanDeckView(
                    deck: Binding(get: { planDeck ?? shown }, set: { if planDeck != nil { planDeck = $0 } }),
                    onPlan: savePick, onPass: rememberPass, onClose: closePlanDeck
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
        .confirmationDialog(clearPastTitle, isPresented: $showClearPastConfirm, titleVisibility: .visible) {
            Button("Clear Past Plans", role: .destructive, action: clearPastPlans)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Takes plans you didn't cook off your planner. Dinners you cooked stay in your week.")
        }
        .toast($weekShoppingFeedback)
        .toast($removalToast, icon: "trash", action: (title: "Undo", perform: undoTakeOff))
        .toast($undoNote, icon: "calendar.badge.exclamationmark")
        .onAppear {
            rollOverToToday()
            if let start = currentWeekStart {
                mealPlanningManager.propagateRecurring(toWeekStarting: start)
            }
            updateSelectedMealTimes(for: selectedDate)
            orderedMealTimes = MealPlanningManager.sortedOrderedMealTimes(
                existing: [], selected: selectedMealTimes, minuteOfDay: minuteOfDay)
            updatePantryExpirySuggestions()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { rollOverToToday() }
        }
        .onChange(of: deckRequest.wrappedValue, initial: true) { _, requested in
            guard requested else { return }
            deckRequest.wrappedValue = false
            if planDeck == nil { openPlanDeck() }
        }
        .onChange(of: weekRequest.wrappedValue, initial: true) { _, date in
            guard let date else { return }
            showWeek(of: date)
            weekRequest.wrappedValue = nil
        }
        .onChange(of: selectedMealTimes) { _, newMealTimes in
            orderedMealTimes = MealPlanningManager.sortedOrderedMealTimes(
                existing: orderedMealTimes, selected: newMealTimes, minuteOfDay: minuteOfDay)
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
                shownPlans(for: date).map { $0.mealTime }
            },
            onSelectDate: { date in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    openDay(date)
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
            onOpen: { openedDinner = OpenedDinner(recipe: $0, startsCooking: false) },
            onCook: { openedDinner = OpenedDinner(recipe: $0, startsCooking: true) },
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
                if let plan = mealPlanningManager.mealPlan(for: selectedDate, mealTime: mealTime) { takeOff(plan) }
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

    private func rollOverToToday() {
        let now = Date()
        if let today = mealCalendar.rolledOver(selected: selectedDate, lastToday: lastToday, now: now) {
            showWeek(of: today)
        }
        lastToday = now
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
                                hasPlans: !shownPlans(for: selectedDate).isEmpty,
                                date: selectedDate, now: Date())
    }

    var daysInCurrentWeek: [Date] {
        mealCalendar.daysInWeek(containing: selectedDate)
    }
}

#Preview {
    MealPlanningView()
}
