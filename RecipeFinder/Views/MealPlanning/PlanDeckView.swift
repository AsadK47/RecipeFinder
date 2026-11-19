import SwiftUI

/// "Plan my week": one big card per empty dinner. Swipe right or tap Plan it to plan the dish for that night; swipe
/// left or tap Not this one for another dish; swipe up or tap Have it tonight to plan it for tonight while tonight is
/// open (Today then leads with it). Each pick is saved as it's made, so closing part-way keeps them.
/// Shown over the planner (not as a cover) so a badge earned by the first plan can still present on top.
struct PlanDeckView: View {
    @Binding var deck: PlanDeck
    let onPlan: (PlanDeck.Pick) -> Void
    let onClose: () -> Void

    @State private var drag: CGSize = .zero
    /// Which way the last card left, so it flies off on the side it was sent (top for tonight).
    @State private var exitEdge: Edge = .trailing
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private static let swipeThreshold: CGFloat = 110

    /// Smaller at accessibility text sizes so the name, reason and buttons still fit on a small phone.
    private var imageHeight: CGFloat { dynamicTypeSize.isAccessibilitySize ? 150 : 300 }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: AppTheme.spacing16) {
                header
                if let card = deck.current {
                    Spacer(minLength: 0)
                    cardView(card)
                        .id(card.id)
                        .transition(cardTransition)
                    Spacer(minLength: 0)
                    controls(for: card)
                } else {
                    Spacer(minLength: 0)
                    finished
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, AppTheme.spacing20)
            .padding(.vertical, AppTheme.spacing16)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityIdentifier("planDeck")
    }

    // MARK: - Parts

    private var header: some View {
        HStack(alignment: .center, spacing: AppTheme.spacing12) {
            VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                Text("Plan my week")
                    .font(.title2.weight(.bold))
                    .adaptiveForegroundColor()
                    .accessibilityAddTraits(.isHeader)
                if let card = deck.current {
                    let position = deck.position
                    Text("\(card.day.formatted(.dateTime.weekday(.wide))) dinner · \(position.night) of \(position.of)")
                        .font(.subheadline)
                        .adaptiveSecondaryForeground()
                        .accessibilityIdentifier("planDeck.night")
                }
            }
            Spacer(minLength: 0)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.headline)
                    .adaptiveForegroundColor()
                    .frame(width: 44, height: 44)
                    .appCard(in: Circle())
            }
            .accessibilityLabel("Close")
            .accessibilityIdentifier("planDeck.close")
        }
    }

    private func cardView(_ card: PlanDeck.Card) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            RecipeImageView(recipe: card.recipe, imageName: card.recipe.heroImageName, height: imageHeight)
                .frame(maxWidth: .infinity)
                .frame(height: imageHeight)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius12))
                .accessibilityHidden(true)
            Text(card.recipe.name)
                .font(.title3.weight(.bold))
                .adaptiveForegroundColor()
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            if card.recipe.hasTotalTime {
                Label(DurationFormatter.label(minutes: card.recipe.totalMinutes), systemImage: "clock")
                    .font(.subheadline)
                    .adaptiveSecondaryForeground()
            }
            Text(card.reason)
                .font(.subheadline)
                .adaptiveSecondaryForeground()
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppTheme.spacing12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(elevated: true)
        .overlay(alignment: .top) { swipeHint }
        .offset(x: drag.width, y: isDraggingUp ? drag.height : drag.height * 0.2)
        .rotationEffect(.degrees(reduceMotion || isDraggingUp ? 0 : Double(drag.width / 25)))
        .gesture(
            DragGesture()
                .onChanged { value in
                    drag = value.translation
                    exitEdge = isDraggingUp ? .top : value.translation.width < 0 ? .leading : .trailing
                }
                .onEnded { value in
                    let width = value.translation.width, height = value.translation.height
                    if isDraggingUp, height < -Self.swipeThreshold {
                        planTonight()
                    } else if abs(width) >= abs(height), width > Self.swipeThreshold {
                        plan()
                    } else if abs(width) >= abs(height), width < -Self.swipeThreshold {
                        skip()
                    } else {
                        withAnimation(.appGentle) { drag = .zero }
                    }
                }
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("planDeck.card")
        .accessibilityAction(named: "Plan it") { plan() }
        .accessibilityAction(named: "Not this one") { skip() }
        .accessibilityActions {
            if deck.canPlanTonight { Button("Have it tonight", action: planTonight) }
        }
    }

    /// A mostly-upward drag, and only while up can send the card to tonight — otherwise it stays a sideways card.
    private var isDraggingUp: Bool {
        deck.canPlanTonight && drag.height < 0 && abs(drag.height) > abs(drag.width)
    }

    /// "Plan it" / "Not this one" / "Tonight" fades in while dragging, so the cook sees what letting go will do.
    @ViewBuilder
    private var swipeHint: some View {
        let up = isDraggingUp
        let progress = min(abs(up ? drag.height : drag.width) / Self.swipeThreshold, 1)
        if progress > 0.15 {
            let planning = up || drag.width > 0
            Label(up ? "Tonight" : planning ? "Plan it" : "Not this one",
                  systemImage: up ? "moon.stars.fill" : planning ? "heart.fill" : "xmark")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, AppTheme.spacing16)
                .padding(.vertical, AppTheme.spacing8)
                .background(Capsule().fill(planning ? AppTheme.accentColor : AppTheme.destructiveFill))
                .opacity(progress)
                .padding(.top, AppTheme.spacing24)
                .accessibilityHidden(true)
        }
    }

    private func controls(for card: PlanDeck.Card) -> some View {
        VStack(spacing: AppTheme.spacing12) {
            HStack(spacing: AppTheme.spacing12) {
                PrimaryButton("Not this one", systemImage: "xmark", fillWidth: true, variant: .secondary, action: skip)
                    .accessibilityIdentifier("planDeck.skip")
                PrimaryButton("Plan it", systemImage: "heart.fill", fillWidth: true, action: plan)
                    .accessibilityIdentifier("planDeck.plan")
            }
            if deck.canPlanTonight {
                PrimaryButton("Have it tonight", systemImage: "moon.stars.fill", fillWidth: true, variant: .secondary,
                              action: planTonight)
                    .accessibilityIdentifier("planDeck.tonight")
            }
            Button {
                HapticManager.shared.light()
                send(.leading) { $0.skipNight() }
            } label: {
                Text("Leave \(card.day.formatted(.dateTime.weekday(.wide))) open")
                    .font(.subheadline.weight(.semibold))
                    .adaptiveSecondaryForeground()
                    .frame(minHeight: 44)
            }
            .accessibilityIdentifier("planDeck.skipNight")
        }
    }

    private var finished: some View {
        let copy = deck.finishedCopy
        return VStack(spacing: AppTheme.spacing16) {
            IconBadge(systemName: "calendar.badge.checkmark", tint: AppTheme.accentColor, diameter: 72, style: .solid)
                .accessibilityHidden(true)
            Text(copy.title)
                .font(.title2.weight(.bold))
                .adaptiveForegroundColor()
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("planDeck.finished")
            Text(copy.message)
                .font(.body)
                .adaptiveSecondaryForeground()
                .multilineTextAlignment(.center)
            PrimaryButton("Done", systemImage: "checkmark", fillWidth: true, action: onClose)
                .accessibilityIdentifier("planDeck.done")
        }
        .padding(AppTheme.spacing24)
        .frame(maxWidth: .infinity)
        .appCard(elevated: true)
    }

    // MARK: - Actions

    private var cardTransition: AnyTransition {
        reduceMotion
            ? .opacity
            : .asymmetric(insertion: .scale(scale: 0.92).combined(with: .opacity),
                          removal: .move(edge: exitEdge).combined(with: .opacity))
    }

    private func plan() {
        send(.trailing) { deck in
            guard let card = deck.current else { return }
            onPlan(PlanDeck.Pick(day: card.day, recipe: card.recipe))
            deck.plan()
        }
    }

    private func skip() {
        send(.leading) { $0.skip() }
    }

    private func planTonight() {
        guard deck.canPlanTonight else {
            withAnimation(.appGentle) { drag = .zero }
            return
        }
        send(.top) { deck in
            let before = deck.picks.count
            deck.planTonight()
            if let pick = deck.picks.dropFirst(before).first { onPlan(pick) }
        }
    }

    /// Sets which way the card leaves, then changes the deck on the next main-actor turn: the leaving card takes its
    /// transition from its last render, so the edge must land first. The change is dropped if the card moved on
    /// meanwhile, so a quick double tap can't plan the next night with a dish the cook never saw.
    private func send(_ edge: Edge, _ change: @escaping (inout PlanDeck) -> Void) {
        guard let cardID = deck.current?.id else { return }
        exitEdge = edge
        Task { @MainActor in
            guard deck.current?.id == cardID else { return }
            withAnimation(.appGentle) { change(&deck) }
            drag = .zero
        }
    }
}
