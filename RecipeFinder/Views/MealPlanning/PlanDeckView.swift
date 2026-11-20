import SwiftUI

/// "Plan my week": one big card per empty dinner. Swipe right or tap Plan it to plan the dish for that night; swipe
/// left or tap Not this one for another dish; Busy night deals quick dishes for that night. Each pick is saved as it's
/// made, so closing part-way keeps them.
/// Shown over the planner (not as a cover) so a badge earned by the first plan can still present on top.
struct PlanDeckView: View {
    @Binding var deck: PlanDeck
    let onPlan: (PlanDeck.Pick) -> Void
    /// A dish passed on with Not this one / swipe left (Busy night and Leave open aren't passes).
    let onPass: (RecipeModel) -> Void
    let onClose: () -> Void

    @State private var drag: CGSize = .zero
    /// Which way the last card left, so it flies off on the side it was sent; nil (a busy-night re-deal) fades it.
    @State private var exitEdge: Edge? = .trailing
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
            if let card = deck.current {
                leaveOpen(card)
            }
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
        .offset(x: drag.width, y: drag.height * 0.2)
        .rotationEffect(.degrees(reduceMotion ? 0 : Double(drag.width / 25)))
        .gesture(
            DragGesture()
                .onChanged { value in
                    drag = value.translation
                    exitEdge = value.translation.width < 0 ? .leading : .trailing
                }
                .onEnded { value in
                    if value.translation.width > Self.swipeThreshold {
                        plan()
                    } else if value.translation.width < -Self.swipeThreshold {
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
        .accessibilityAction(named: deck.isCurrentNightBusy ? "Not a busy night" : "Busy night") {
            toggleBusy()
        }
    }

    /// "Plan it" / "Not this one" fades in while dragging, so the cook sees what letting go will do.
    @ViewBuilder
    private var swipeHint: some View {
        let progress = min(abs(drag.width) / Self.swipeThreshold, 1)
        if progress > 0.15 {
            let planning = drag.width > 0
            Label(planning ? "Plan it" : "Not this one", systemImage: planning ? "heart.fill" : "xmark")
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

    /// One centred row in the usual order (owner 2026-11-20): ✕ Not this one · ⚡ Busy (small) · ♥ Plan it (largest).
    private func controls(for card: PlanDeck.Card) -> some View {
        HStack(alignment: .top, spacing: AppTheme.spacing24) {
            DeckControl(title: "Not this one", systemImage: "xmark", diameter: 64, style: .secondary, action: skip)
                .accessibilityIdentifier("planDeck.skip")
            busyToggle
            DeckControl(title: "Plan it", systemImage: "heart.fill", diameter: 76, style: .primary, action: plan)
                .accessibilityIdentifier("planDeck.plan")
        }
        .frame(maxWidth: .infinity)
    }

    /// Secondary, so it sits in the header: leaves this night empty and moves on.
    private func leaveOpen(_ card: PlanDeck.Card) -> some View {
        Button {
            HapticManager.shared.light()
            send(.leading) { $0.skipNight() }
        } label: {
            Text("Skip \(card.day.formatted(.dateTime.weekday(.abbreviated)))")
                .font(.subheadline.weight(.semibold))
                .adaptiveSecondaryForeground()
                .frame(minHeight: 44)
        }
        .accessibilityLabel("Leave \(card.day.formatted(.dateTime.weekday(.wide))) open")
        .accessibilityIdentifier("planDeck.skipNight")
    }

    /// Busy night: the deck deals quick dishes for this night. Accent-filled while on, so the cook sees it's marked.
    private var busyToggle: some View {
        let busy = deck.isCurrentNightBusy
        return DeckControl(title: "Busy night", systemImage: busy ? "bolt.fill" : "bolt", diameter: 52,
                           style: busy ? .primary : .secondary) {
            toggleBusy()
        }
        .accessibilityValue(busy ? "On" : "Off")
        .accessibilityAddTraits(.isToggle)
        .accessibilityHint("Deals quick dishes for this night")
        .accessibilityIdentifier("planDeck.busy")
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
                          removal: exitEdge.map { AnyTransition.move(edge: $0).combined(with: .opacity) } ?? .opacity)
    }

    private func plan() {
        send(.trailing) { deck in
            guard let card = deck.current else { return }
            onPlan(PlanDeck.Pick(day: card.day, recipe: card.recipe))
            deck.plan()
        }
    }

    private func skip() {
        send(.leading) { deck in
            guard let card = deck.current else { return }
            onPass(card.recipe)
            deck.skip()
        }
    }

    /// A re-deal for the same night fades, so it never looks like the dish was planned or passed on.
    private func toggleBusy() {
        send(nil) { $0.setBusy(!$0.isCurrentNightBusy) }
    }

    /// Sets which way the card leaves, then changes the deck on the next main-actor turn: the leaving card takes its
    /// transition from its last render, so the edge must land first. The change is dropped if the card moved on
    /// meanwhile, so a quick double tap can't plan the next night with a dish the cook never saw.
    private func send(_ edge: Edge?, _ change: @escaping (inout PlanDeck) -> Void) {
        guard let cardID = deck.current?.id else { return }
        exitEdge = edge
        Task { @MainActor in
            guard deck.current?.id == cardID else { return }
            withAnimation(.appGentle) { change(&deck) }
            drag = .zero
        }
    }
}

/// A round deck button with its label underneath; 44pt+ at every size.
private struct DeckControl: View {
    enum Style { case primary, secondary }

    let title: String
    let systemImage: String
    let diameter: CGFloat
    let style: Style
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.spacing6) {
                Image(systemName: systemImage)
                    .font(.system(size: diameter * 0.36, weight: .bold))
                    .foregroundStyle(style == .primary ? Color.white : AppTheme.textColor(opacity: 1))
                    .frame(width: diameter, height: diameter)
                    .background {
                        if style == .primary {
                            Circle().fill(AppTheme.accentColor)
                        } else {
                            Circle().fill(.clear).appCard(in: Circle())
                        }
                    }
                Text(title)
                    .font(.caption.weight(.semibold))
                    .adaptiveForegroundColor()
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(minWidth: 72)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}
