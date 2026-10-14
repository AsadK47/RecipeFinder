import SwiftUI

// Full-screen cooking mode: large text, screen stays awake, per-step timers.
struct CookingModeView: View {
    let recipe: RecipeModel
    var onFinish: (() -> Void)?

    // MARK: - State

    @State private var currentIndex: Int = 0
    @State private var completedItems: Set<Int> = []
    @State private var showTimerSheet = false
    @Environment(\.recipeTimer) private var timerManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
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

    nonisolated static func cookTimerMinutes(in text: String) -> Int? {
        guard let regex = cookTimerRegex else { return nil }
        let ns = text as NSString
        var totalMinutes = 0.0
        for match in regex.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
            let value = Double(ns.substring(with: match.range(at: 1))) ?? 0
            let unit = ns.substring(with: match.range(at: 2)).lowercased()
            if unit.hasPrefix("h") {
                totalMinutes += value * 60
            } else if unit.hasPrefix("s") {
                totalMinutes += value / 60
            } else {
                totalMinutes += value
            }
        }
        let rounded = Int(totalMinutes.rounded())
        return rounded > 0 ? rounded : nil
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    progressBar
                    Spacer(minLength: 0)
                    contentCard
                    Spacer(minLength: 0)
                    navigationRow
                }
                .padding(.horizontal, AppTheme.spacing20)
                .padding(.bottom, AppTheme.spacing32)
            }
            .navigationTitle(recipe.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .font(.body.weight(.semibold))
                        .adaptiveForegroundColor()
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
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { currentIndex += 1 }
                HapticManager.shared.selection()
            }
            .onReceive(NotificationCenter.default.publisher(for: .cookingModePreviousStep)) { _ in
                guard !isFirst else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { currentIndex -= 1 }
                HapticManager.shared.selection()
            }
        }
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
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentIndex)
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
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            if isChecked { completedItems.remove(i) } else { completedItems.insert(i) }
                        }
                        HapticManager.shared.selection()
                    } label: {
                        HStack(spacing: AppTheme.spacing16) {
                            Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(isChecked ? .green : .white.opacity(0.6))
                                .frame(width: AppTheme.iconSize28)

                            let qty = ingredient.formattedWithUnit(for: recipe.scaleFactor, system: measurementSystem)
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
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { currentIndex -= 1 }
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
                    BadgeManager.shared.unlockBadge(.headChef)
                    onFinish?()
                    dismiss()
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { currentIndex += 1 }
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
                        .fill(isLast ? Color.green.opacity(0.4) : AppTheme.accentColor(for: selectedTheme).opacity(0.35))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.top, AppTheme.spacing16)
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
