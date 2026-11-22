import SwiftUI

// Full-screen cooking mode: large text, screen stays awake, per-step timers.
struct CookingModeView: View {
    let recipe: RecipeModel
    /// Logs the cook and says whether it counted; the caller then shows its Made it sheet (rating + photo) once
    /// this cover dismisses. False = already cooked today (one cook a day), so there's no sheet to close into.
    var onFinish: (() -> Bool)?

    // MARK: - State

    @State private var currentIndex: Int = 0
    /// Set once Finish is tapped, so leaving doesn't save a place to resume.
    @State private var isFinished = false
    /// Already cooked today: a short done screen instead of closing with no word.
    @State private var showDoneCard = false
    @State private var completedItems: Set<Int> = []
    @State private var showTimerSheet = false
    /// Ingredients each item uses — matched once per cook, not on every redraw.
    @State private var stepIngredients: [[StepIngredientMatcher.Use]] = []
    @Environment(\.recipeTimer) private var timerManager
    @Environment(\.cookingTimers) private var cookingTimers
    @Environment(\.cookingResume) private var resumeMemory
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    /// Restores what the screen was on the way out, so Settings' Keep Screen Awake survives a cook.
    @State private var awake = ScreenAwakeHold(
        read: { UIApplication.shared.isIdleTimerDisabled },
        write: { UIApplication.shared.isIdleTimerDisabled = $0 }
    )

    // MARK: - Cooking items (ingredients + pre-prep + steps combined in order)

    // Pure, unit-tested model owns the ordering, index math and timer parsing; the view just renders it.
    private typealias CookingItem = CookingPlan.Item
    private var plan: CookingPlan { CookingPlan(prePrep: recipe.prePrepInstructions, steps: recipe.instructions) }

    private var current: CookingItem { plan.items[currentIndex] }
    private var isFirst: Bool { plan.isFirst(currentIndex) }
    private var isLast:  Bool { plan.isLast(currentIndex) }

    // Minutes extracted from the current step's text — drives the timer button.
    private var stepTimerMinutes: Int? { plan.timerMinutes(at: currentIndex) }

    /// One timer per step of this recipe: the step's button can't start a second copy while one is on.
    private var stepTimerKey: String { CookingTimers.stepKey(recipeID: recipe.id, index: currentIndex) }

    private var stepTimerName: String {
        let (label, _) = stepLabelAndTotal
        return CookingTimerName.name(
            for: current.displayText,
            uses: currentStepIngredients,
            ingredients: recipe.ingredients,
            fallback: "\(label) \(stepPositionInPhase)"
        )
    }

    private var currentStepIngredients: [StepIngredientMatcher.Use] {
        stepIngredients.indices.contains(currentIndex) ? stepIngredients[currentIndex] : []
    }

    /// Records the cook (streak + badges, via `onFinish`) and leaves. Shared by the "Finish" button and by
    /// "Done" when the user is already on the last step, so reaching the end credits the cook either way.
    private func finishCooking() {
        guard !isFinished else { return }
        isFinished = true
        resumeMemory.forget(recipe.id)
        BadgeManager.shared.unlockBadge(.headChef)
        // A logged cook closes straight into the caller's Made it sheet; one already counted today has no sheet.
        if onFinish?() ?? true {
            dismiss()
        } else {
            withAnimation(.appSpring) { showDoneCard = true }
        }
    }

    private func goBack() {
        withAnimation(.appSpring) { currentIndex -= 1 }
        HapticManager.shared.selection()
    }

    private func goNext() {
        if isLast {
            finishCooking()
        } else {
            withAnimation(.appSpring) { currentIndex += 1 }
            HapticManager.shared.selection()
        }
    }

    /// What a saved place is valid for: the cooking-mode lines plus ingredient names, so an edit resets it.
    static func resumeContent(for recipe: RecipeModel) -> [String] {
        let plan = CookingPlan(prePrep: recipe.prePrepInstructions, steps: recipe.instructions)
        return plan.sessionLines + recipe.ingredients.map(\.name)
    }

    /// Picks up where this recipe was left earlier in this app session (step + ticked ingredients).
    private func restorePlace() {
        let content = Self.resumeContent(for: recipe)
        guard let place = resumeMemory.place(for: recipe.id, content: content, itemCount: plan.count) else { return }
        currentIndex = place.index
        completedItems = place.checkedIngredients
    }

    private func rememberPlace() {
        guard !isFinished else { return }
        resumeMemory.remember(
            .init(index: currentIndex, checkedIngredients: completedItems),
            for: recipe.id,
            content: Self.resumeContent(for: recipe)
        )
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            if showDoneCard {
                Spacer(minLength: 0)
                CookingFinishedCard(recipeName: recipe.name) { dismiss() }
                Spacer(minLength: 0)
            } else {
                CookingProgressBar(progress: plan.progress(currentIndex))
                CookingTimerStrip()
                Spacer(minLength: 0)
                contentCard
                Spacer(minLength: 0)
                CookingNavigationRow(isFirst: isFirst, isLast: isLast, onBack: goBack, onNext: goNext)
            }
        }
        .padding(.horizontal, AppTheme.spacing20)
        .padding(.bottom, AppTheme.spacing32)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                // On the last step, Done counts as finishing — otherwise a user who cooked all the way
                // through but tapped Done (not the green Finish) would silently lose streak/badge credit.
                Button("Done") {
                    if showDoneCard { dismiss() } else if isLast { finishCooking() } else { dismiss() }
                }
                    .font(.body.weight(.semibold))
                    .adaptiveForegroundColor()
                    .accessibilityIdentifier("cooking.done")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                timerToolbarButton
            }
        }
        .sheet(isPresented: $showTimerSheet) {
            CookTimerView()
        }
        .onAppear {
            stepIngredients = plan.ingredientUses(from: recipe.ingredients)
            restorePlace()
            awake.begin()
            CookingSession.shared.start(
                recipeName: recipe.name,
                items: plan.sessionLines
            )
            CookingSession.shared.setIndex(currentIndex)
        }
        .onDisappear {
            rememberPlace()
            awake.end()
            CookingSession.shared.end()
        }
        // Restore idle timer if interrupted (call/PiP/alert) and onDisappear never fires.
        .onChange(of: scenePhase) { _, phase in
            awake.sceneChanged(isActive: phase == .active)
        }
        .onChange(of: currentIndex) { _, new in
            CookingSession.shared.setIndex(new)
        }
        .onReceive(NotificationCenter.default.publisher(for: .cookingModeNextStep)) { _ in
            guard !isLast else { return }
            goNext()
        }
        .onReceive(NotificationCenter.default.publisher(for: .cookingModePreviousStep)) { _ in
            guard !isFirst else { return }
            goBack()
        }
        .sheetScaffold(recipe.name)
    }

    // MARK: - Content card

    @ViewBuilder
    private var contentCard: some View {
        if current.isIngredientList {
            CookingIngredientChecklist(recipe: recipe, completed: $completedItems)
        } else {
            stepCard
        }
    }

    private var stepCard: some View {
        VStack(spacing: AppTheme.spacing20) {
            stepHeader

            ScrollView {
                VStack(spacing: AppTheme.spacing16) {
                    Text(current.displayText)
                        .font(.title2)
                        .fontWeight(.medium)
                        .adaptiveForegroundColor()
                        .lineSpacing(6)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppTheme.spacing24)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                                .fill(.ultraThinMaterial)
                        )

                    let used = currentStepIngredients
                    if !used.isEmpty {
                        CookingStepIngredients(uses: used, ingredients: recipe.ingredients, scaleFactor: recipe.scaleFactor)
                    }
                }
            }

            if let minutes = stepTimerMinutes {
                // Ticks so the button frees up the moment the step's timer finishes.
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    stepTimerButton(minutes: minutes, running: cookingTimers.timer(forKey: stepTimerKey, now: context.date))
                }
            }
        }
    }

    private func stepTimerButton(minutes: Int, running: CookingTimerBoard.Timer?) -> some View {
        Button {
            // While the step's timer is on, the pill above is where it's paused or stopped.
            guard running == nil else { return }
            withAnimation(.appSnappy) {
                _ = cookingTimers.start(name: stepTimerName, minutes: minutes, key: stepTimerKey)
            }
            HapticManager.shared.success()
        } label: {
            Label(Self.stepTimerTitle(minutes: minutes, running: running), systemImage: running == nil ? "timer" : "checkmark")
                .font(.headline)
                .padding(.horizontal, AppTheme.spacing24)
                .padding(.vertical, AppTheme.spacing14)
                .frame(maxWidth: .infinity)
                .adaptiveForegroundColor()
                .appCard(in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("cooking.startTimer")
    }

    static func stepTimerTitle(minutes: Int, running: CookingTimerBoard.Timer?) -> String {
        guard let running else { return "Start \(minutes)-minute timer" }
        return running.isPaused ? "\(running.name) timer paused" : "\(running.name) timer is on"
    }

    private var stepHeader: some View {
        HStack {
            let (label, total) = stepLabelAndTotal
            Text(label)
                .font(.subheadline.weight(.semibold))
                .adaptiveSecondaryForeground()
            Spacer()
            Text("\(stepPositionInPhase) of \(total)")
                .font(.subheadline.monospacedDigit())
                .adaptiveSecondaryForeground()
                .accessibilityIdentifier("cooking.stepPosition")
        }
    }

    private var stepLabelAndTotal: (String, Int) { plan.phaseLabel(at: currentIndex) }
    private var stepPositionInPhase: Int { plan.positionInPhase(at: currentIndex) }

    // MARK: - Timer toolbar button

    @ViewBuilder
    private var timerToolbarButton: some View {
        Button {
            showTimerSheet = true
            HapticManager.shared.light()
        } label: {
            Image(systemName: timerManager.isActive ? "timer.circle.fill" : "timer")
                .adaptiveForegroundColor()
        }
    }
}
