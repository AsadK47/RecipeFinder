import SwiftUI

// Full-screen cooking mode: large text, screen stays awake, per-step timers.
struct CookingModeView: View {
    let recipe: RecipeModel
    /// Logs the cook; the caller follows up with its Made it sheet (rating + photo) once this cover dismisses.
    var onFinish: (() -> Void)?

    // MARK: - State

    @State private var currentIndex: Int = 0
    /// Set when the cook is logged — swaps the steps for a done screen instead of closing abruptly.
    @State private var isFinished = false
    @State private var completedItems: Set<Int> = []
    @State private var showTimerSheet = false
    /// Ingredients each item uses — matched once per cook, not on every redraw.
    @State private var stepIngredients: [[StepIngredientMatcher.Use]] = []
    @Environment(\.recipeTimer) private var timerManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Cooking items (ingredients + pre-prep + steps combined in order)

    // Pure, unit-tested model owns the ordering, index math and timer parsing; the view just renders it.
    private typealias CookingItem = CookingPlan.Item
    private var plan: CookingPlan { CookingPlan(prePrep: recipe.prePrepInstructions, steps: recipe.instructions) }

    private var current: CookingItem { plan.items[currentIndex] }
    private var isFirst: Bool { plan.isFirst(currentIndex) }
    private var isLast:  Bool { plan.isLast(currentIndex) }

    // Minutes extracted from the current step's text — drives the timer button.
    private var stepTimerMinutes: Int? { plan.timerMinutes(at: currentIndex) }

    private var currentStepIngredients: [StepIngredientMatcher.Use] {
        stepIngredients.indices.contains(currentIndex) ? stepIngredients[currentIndex] : []
    }

    /// Records the cook (streak + badges, via `onFinish`) and leaves. Shared by the "Finish" button and by
    /// "Done" when the user is already on the last step, so reaching the end credits the cook either way.
    private func finishCooking() {
        guard !isFinished else { return }
        BadgeManager.shared.unlockBadge(.headChef)
        onFinish?()
        withAnimation(.appSpring) { isFinished = true }
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

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            if isFinished {
                Spacer(minLength: 0)
                CookingFinishedCard(recipeName: recipe.name) { dismiss() }
                Spacer(minLength: 0)
            } else {
                CookingProgressBar(progress: plan.progress(currentIndex))
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
                    if isFinished { dismiss() } else if isLast { finishCooking() } else { dismiss() }
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
            UIApplication.shared.isIdleTimerDisabled = true
            CookingSession.shared.start(
                recipeName: recipe.name,
                items: plan.sessionLines
            )
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            CookingSession.shared.end()
        }
        // Restore idle timer if interrupted (call/PiP/alert) and onDisappear never fires.
        .onChange(of: scenePhase) { _, phase in
            UIApplication.shared.isIdleTimerDisabled = (phase == .active)
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
                Button {
                    // Don't clobber a timer already running from an earlier step.
                    if !timerManager.isActive {
                        timerManager.start(hours: 0, minutes: minutes, seconds: 0)
                    }
                    showTimerSheet = true
                    HapticManager.shared.success()
                } label: {
                    Label(timerManager.isActive ? "Timer running" : "Start \(minutes)-minute timer", systemImage: "timer")
                        .font(.headline)
                        .padding(.horizontal, AppTheme.spacing24)
                        .padding(.vertical, AppTheme.spacing14)
                        .frame(maxWidth: .infinity)
                        .background(Capsule().fill(.ultraThinMaterial))
                        .adaptiveForegroundColor()
                }
                .buttonStyle(.plain)
            }
        }
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
