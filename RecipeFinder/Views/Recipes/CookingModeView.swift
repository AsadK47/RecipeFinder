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
    @Environment(\.recipeTimer) private var timerManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("measurementSystem") private var measurementSystem: MeasurementSystem = .metric

    // MARK: - Cooking items (ingredients + pre-prep + steps combined in order)

    // Pure, unit-tested model owns the ordering + index math; the view just renders it.
    private typealias CookingItem = CookingPlan.Item
    private var plan: CookingPlan { CookingPlan(prePrep: recipe.prePrepInstructions, steps: recipe.instructions) }
    private var cookingItems: [CookingItem] { plan.items }

    private var current: CookingItem { plan.items[currentIndex] }
    private var isFirst: Bool { plan.isFirst(currentIndex) }
    private var isLast:  Bool { plan.isLast(currentIndex) }

    // Minutes extracted from the current step's text — drives the timer button.
    private var stepTimerMinutes: Int? {
        switch current {
        case .prePrep(_, let text), .step(_, let text):
            return Self.cookTimerMinutes(in: text)
        default: return nil
        }
    }

    // Only counts numbers followed by a time unit, so "350°F"/"2 eggs" aren't read as durations. Compiled once (read every body eval).
    // `nonisolated`: pure string parsing with no UI/state — it has no business inheriting the View's @MainActor isolation,
    // so the view body and unit tests can both call it off any actor without a concurrency warning.
    nonisolated private static let cookTimerRegex = try? NSRegularExpression(
        pattern: #"(\d+(?:\.\d+)?)\s*(hours?|hrs?|minutes?|mins?|seconds?|secs?)\b"#,
        options: [.caseInsensitive]
    )

    /// Minutes for the step's FIRST duration. A compound like "1 hour 30 minutes" is combined, but separate mentions
    /// ("chill 6 hours, up to 48 hours"; "broil 4-5 minutes… within 6 minutes") are not summed into one huge timer.
    nonisolated static func cookTimerMinutes(in text: String) -> Int? {
        guard let regex = cookTimerRegex else { return nil }
        let ns = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
        guard let first = matches.first else { return nil }

        func minutes(of match: NSTextCheckingResult) -> (value: Double, rank: Int) {
            let value = Double(ns.substring(with: match.range(at: 1))) ?? 0
            let unit = ns.substring(with: match.range(at: 2)).lowercased()
            if unit.hasPrefix("h") { return (value * 60, 2) }
            if unit.hasPrefix("s") { return (value / 60, 0) }
            return (value, 1)
        }

        var (totalMinutes, lastRank) = minutes(of: first)
        var previousEnd = first.range.location + first.range.length
        for match in matches.dropFirst() {
            // Continue only for an adjacent, smaller unit ("1 hour 30 minutes", "1 hr and 15 mins").
            let gap = ns.substring(with: NSRange(location: previousEnd, length: match.range.location - previousEnd))
            let joiner = gap.trimmingCharacters(in: .whitespaces).lowercased()
            let part = minutes(of: match)
            guard joiner.isEmpty || joiner == "and" || joiner == ",", part.rank < lastRank else { break }
            totalMinutes += part.value
            lastRank = part.rank
            previousEnd = match.range.location + match.range.length
        }
        let rounded = Int(totalMinutes.rounded())
        return rounded > 0 ? rounded : nil
    }

    /// Records the cook (streak + badges, via `onFinish`) and leaves. Shared by the "Finish" button and by
    /// "Done" when the user is already on the last step, so reaching the end credits the cook either way.
    private func finishCooking() {
        guard !isFinished else { return }
        BadgeManager.shared.unlockBadge(.headChef)
        onFinish?()
        withAnimation(.appSpring) { isFinished = true }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            if isFinished {
                Spacer(minLength: 0)
                finishedCard
                Spacer(minLength: 0)
            } else {
                progressBar
                Spacer(minLength: 0)
                contentCard
                Spacer(minLength: 0)
                navigationRow
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
            UIApplication.shared.isIdleTimerDisabled = true
            CookingSession.shared.start(
                recipeName: recipe.name,
                items: cookingItems.map { item in
                    switch item {
                    case .ingredientList:        return "First, gather your ingredients."
                    case .prePrep(_, let text):  return text
                    case .step(_, let text):     return text
                    }
                }
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
            withAnimation(.appSpring) { currentIndex += 1 }
            HapticManager.shared.selection()
        }
        .onReceive(NotificationCenter.default.publisher(for: .cookingModePreviousStep)) { _ in
            guard !isFirst else { return }
            withAnimation(.appSpring) { currentIndex -= 1 }
            HapticManager.shared.selection()
        }
        .sheetScaffold(recipe.name)
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(.white.opacity(0.2))
                    .frame(height: 4)
                RoundedRectangle(cornerRadius: 2)
                    .fill(.white.opacity(0.85))
                    .frame(
                        width: geo.size.width * CGFloat(plan.progress(currentIndex)),
                        height: 4
                    )
                    .animation(.appGentle, value: currentIndex)
            }
        }
        .frame(height: 4)
        .padding(.top, AppTheme.spacing8)
        .padding(.bottom, AppTheme.spacing16)
    }

    // MARK: - Content card

    @ViewBuilder
    private var contentCard: some View {
        if current.isIngredientList {
            ingredientsCard
        } else {
            stepCard
        }
    }

    private var ingredientsCard: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                Text("Gather your ingredients")
                    .font(.title2.weight(.bold))
                    .adaptiveForegroundColor()
                    .padding(.bottom, AppTheme.spacing8)

                ForEach(recipe.ingredients.indices, id: \.self) { i in
                    let ingredient = recipe.ingredients[i]
                    let isChecked = completedItems.contains(i)
                    Button {
                        withAnimation(.appSnappy) {
                            if isChecked { completedItems.remove(i) } else { completedItems.insert(i) }
                        }
                        HapticManager.shared.selection()
                    } label: {
                        HStack(spacing: AppTheme.spacing16) {
                            Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(isChecked ? .green : .white.opacity(0.6))
                                .frame(width: AppTheme.iconSize28)

                            // Same amount text as the recipe screen (it used to differ: "13 g" vs "12½ g").
                            let amount = IngredientRowView.amount(for: ingredient, scaleFactor: recipe.scaleFactor, system: measurementSystem)
                            let qty = [amount.quantity, amount.unit].compactMap { $0 }.joined(separator: " ")
                            Text(qty.isEmpty ? ingredient.displayName : "\(qty) \(ingredient.displayName)")
                                .font(.body)
                                .adaptiveForegroundColor()
                                .strikethrough(isChecked, color: .secondary)
                                .opacity(isChecked ? 0.5 : 1)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, AppTheme.spacing10)
                        .padding(.horizontal, AppTheme.spacing16)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius10)
                                .fill(.white.opacity(isChecked ? 0.05 : 0.1))
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, AppTheme.spacing8)
        }
    }

    private var stepCard: some View {
        VStack(spacing: AppTheme.spacing20) {
            stepHeader

            ScrollView {
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

    // MARK: - Navigation row

    private var navigationRow: some View {
        HStack(spacing: AppTheme.spacing16) {
            if !isFirst {
                Button {
                    withAnimation(.appSpring) { currentIndex -= 1 }
                    HapticManager.shared.selection()
                } label: {
                    HStack(spacing: AppTheme.spacing8) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.body.weight(.semibold))
                    .adaptiveForegroundColor()
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(RoundedRectangle(cornerRadius: AppTheme.cornerRadius12).fill(.ultraThinMaterial))
                }
                .buttonStyle(.plain)
            }

            Button {
                if isLast {
                    finishCooking()
                } else {
                    withAnimation(.appSpring) { currentIndex += 1 }
                    HapticManager.shared.selection()
                }
            } label: {
                HStack(spacing: AppTheme.spacing8) {
                    Text(isLast ? "Finish" : "Next")
                    if !isLast { Image(systemName: "chevron.right") }
                    if isLast  { Image(systemName: "checkmark") }
                }
                .font(.body.weight(.semibold))
                .adaptiveForegroundColor()
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                        .fill(isLast ? Color.green.opacity(0.4) : AppTheme.accentColor.opacity(0.35))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.top, AppTheme.spacing16)
    }

    // MARK: - Done screen

    /// The end of the cook gets its own moment (peak-end) rather than the cover just vanishing.
    private var finishedCard: some View {
        VStack(spacing: AppTheme.spacing20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)
                .accessibilityHidden(true)

            VStack(spacing: AppTheme.spacing8) {
                Text("Nice cooking!")
                    .font(.title.weight(.bold))
                    .adaptiveForegroundColor()
                Text("\(recipe.name) is logged to your cook history.")
                    .font(.body)
                    .adaptiveSecondaryForeground()
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: AppTheme.spacing12) {
                PrimaryButton("Done", systemImage: "checkmark", fillWidth: true) {
                    dismiss()
                }
            }
            .padding(.top, AppTheme.spacing8)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("cooking.finished")
    }

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
