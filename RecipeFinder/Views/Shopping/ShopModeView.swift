import SwiftUI
import UIKit

/// Opens shop mode for one store filter (nil = every store).
struct ShopModeRequest: Identifiable {
    let id = UUID()
    let store: String?
}

/// "I'm in the shop": the list as big one-thumb rows in aisle order (a tick dims the row in place), the screen kept
/// awake, and one Done that puts this store's basket At home. Close leaves and keeps the ticks.
struct ShopModeView: View {
    let store: String?

    @Environment(\.shopping) private var shopping
    @Environment(\.kitchen) private var kitchen
    @Environment(\.dismiss) private var dismiss
    @State private var trip = ShopTrip.empty
    /// Categories of the rows ticked on this trip, in tick order — what the aisle order learns from on the way out.
    @State private var tickedAisles: [String] = []
    @State private var awake = ScreenAwakeHold(
        read: { UIApplication.shared.isIdleTimerDisabled },
        write: { UIApplication.shared.isIdleTimerDisabled = $0 }
    )

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 0) {
                header
                ScrollView {
                    LazyVStack(spacing: AppTheme.spacing10) {
                        if trip.isDone { allInBasket }
                        if trip.total == 0 { nothingToGet }
                        ForEach(trip.rows) { row($0) }
                    }
                    .padding(.horizontal, AppTheme.cardHorizontalPadding)
                    .padding(.bottom, AppTheme.spacing20)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(trip.doneTitle, systemImage: "checkmark", fillWidth: true, action: finish)
                .accessibilityHint("Ticked items move to At home")
                .accessibilityIdentifier("shop.done")
                .padding(.horizontal, AppTheme.cardHorizontalPadding)
                .padding(.vertical, AppTheme.spacing8)
        }
        .animation(.appSpring, value: trip)
        .onAppear {
            trip = ShopTrip(items: shopping.items, store: store, aisleOrder: shopping.aisleOrder)
            awake.begin()
        }
        .onDisappear {
            awake.end()
            // Learned on the way out (Done or ✕), so the rows don't reshuffle mid-trip.
            shopping.learnAisleOrder(ticked: tickedAisles, store: store)
        }
        .onChange(of: shopping.items) { _, items in
            trip = ShopTrip(items: items, store: store, aisleOrder: shopping.aisleOrder)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            HStack {
                Text(store.map { "In \($0)" } ?? "In the shop")
                    .font(.title2.weight(.bold))
                    .adaptiveForegroundColor()
                    .accessibilityAddTraits(.isHeader)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .adaptiveForegroundColor()
                        .frame(width: 44, height: 44)
                        .appCard(in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
                .accessibilityHint("Your ticks stay on the list")
                .accessibilityIdentifier("shop.close")
            }
            ProgressView(value: Double(trip.inBasket.count), total: Double(max(trip.total, 1)))
                .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.accentColor))
                .accessibilityHidden(true)
            Text(trip.progressText)
                .font(.subheadline)
                .adaptiveSecondaryForeground()
                .accessibilityIdentifier("shop.progress")
        }
        .padding(.horizontal, AppTheme.cardHorizontalPadding)
        .padding(.vertical, AppTheme.spacing12)
    }

    private var allInBasket: some View {
        HStack(spacing: AppTheme.spacing12) {
            IconBadge(systemName: "checkmark.seal.fill", tint: AppTheme.accentColor, diameter: 40)
                .accessibilityHidden(true)
            Text("Everything's in the basket")
                .font(.headline)
                .adaptiveForegroundColor()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .appCard()
    }

    private var nothingToGet: some View {
        Text("Nothing on the list here")
            .font(.headline)
            .adaptiveSecondaryForeground()
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.spacing20)
    }

    private func row(_ item: ShoppingListModel) -> some View {
        Button { toggle(item) } label: {
            HStack(spacing: AppTheme.spacing16) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 34))
                    .foregroundStyle(item.isChecked ? AppTheme.accentColor : AppTheme.adaptiveEmphasis())
                Text(item.name)
                    .font(.title3.weight(.semibold))
                    .strikethrough(item.isChecked)
                    .adaptiveForegroundColor()
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(ShopTrip.amount(item))
                    .font(.title3)
                    .adaptiveSecondaryForeground()
                    .lineLimit(1)
                    .fixedSize()
            }
            .padding(.horizontal, AppTheme.spacing20)
            .padding(.vertical, AppTheme.spacing12)
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
            .contentShape(Rectangle())
            .appCard(elevated: !item.isChecked)
            .opacity(item.isChecked ? 0.6 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.name)
        .accessibilityValue(item.isChecked ? "In the basket, \(ShopTrip.amount(item))" : ShopTrip.amount(item))
        .accessibilityAddTraits(item.isChecked ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("shop.row")
    }

    private func toggle(_ item: ShoppingListModel) {
        guard let index = shopping.items.firstIndex(where: { $0.id == item.id }) else { return }
        if !item.isChecked { tickedAisles.append(item.category) }
        shopping.toggleItem(at: index)
    }

    private func finish() {
        shopping.putAway(trip.basketIDs, into: kitchen)
        dismiss()
    }
}
