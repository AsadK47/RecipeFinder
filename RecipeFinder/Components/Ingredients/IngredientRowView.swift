import SwiftUI

struct IngredientRowView: View {
    let ingredient: Ingredient
    let isChecked: Bool
    let toggle: () -> Void
    var scaleFactor: Double = 1.0
    var measurementSystem: MeasurementSystem = .metric
    var onAddToShopping: (() -> Void)?
    var isInShoppingList: Bool = false
    var onTapQuantity: (() -> Void)?
    var onSubstitute: (() -> Void)?

    /// Pulses the circle once on appear, to show the row can be ticked (instead of hint text).
    var pulses: Bool = false
    var onPulsed: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulseTrigger = 0

    private enum Timing {
        static let springResponse: Double = 0.3
        static let springDamping: Double = 0.6
        static let pulseDelay: Duration = .milliseconds(700)
    }

    var body: some View {
        let amount = Self.amount(for: ingredient, scaleFactor: scaleFactor, system: measurementSystem)
        HStack(alignment: .center, spacing: AppTheme.spacing12) {
            // The whole row (circle, amount, name) is one tick target; amounts are edited from the pencil or by
            // long-pressing the row.
            Button(action: {
                withAnimation(.spring(response: Timing.springResponse, dampingFraction: Timing.springDamping)) {
                    toggle()
                }
            }) {
                HStack(alignment: .center, spacing: AppTheme.spacing12) {
                    tickCircle
                    rowText(amount: amount)
                        .opacity(isChecked ? 0.5 : 1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(isChecked ? "Got it" : "")
            .accessibilityAddTraits(isChecked ? .isSelected : [])
            .accessibilityHint(isChecked ? "Double tap to put it back" : "Double tap to tick it off")
            .accessibilityIdentifier("recipe.ingredient.row")

            trailingButtons(amount: amount)
                .opacity(isChecked ? 0.5 : 1)
        }
        .padding(.vertical, AppTheme.spacing8)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .contextMenu {
            if let onTapQuantity {
                Button("Edit amount", systemImage: "pencil", action: onTapQuantity)
            }
        }
        .task(id: pulses) {
            guard pulses, !reduceMotion else { return }
            do {
                try await Task.sleep(for: Timing.pulseDelay)
            } catch {
                return  // left the screen before the pulse; it plays next time
            }
            pulseTrigger += 1
            onPulsed()
        }
    }

    private var tickCircle: some View {
        Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
            .font(.title3)
            .foregroundStyle(isChecked ? AppTheme.accentColor : AppTheme.adaptiveHighEmphasis)
            .contentTransition(.symbolEffect(.replace))
            .keyframeAnimator(initialValue: CGFloat(1), trigger: pulseTrigger) { content, scale in
                content.scaleEffect(scale)
            } keyframes: { _ in
                KeyframeTrack {
                    SpringKeyframe(CGFloat(1.3), duration: 0.25)
                    SpringKeyframe(CGFloat(1), duration: 0.3)
                    SpringKeyframe(CGFloat(1.3), duration: 0.25)
                    SpringKeyframe(CGFloat(1), duration: 0.3)
                }
            }
            .frame(minWidth: 28, minHeight: 44)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func rowText(amount: (quantity: String?, unit: String?)) -> some View {
        // Fixed-width amount column so names align. A line with no amount at all ("fresh coriander") drops the
        // column and runs full width as plain text — an empty column read as broken.
        if amount.quantity != nil || amount.unit != nil {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                if let quantity = amount.quantity {
                    Text(quantity)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }

                if let unit = amount.unit {
                    Text(unit)
                        .font(.caption)
                        .adaptiveSecondaryForeground()
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(width: 72, alignment: .leading)
        }

        VStack(alignment: .leading, spacing: AppTheme.spacing2) {
            let parts = ingredient.displayParts
            Text(parts.name)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            if let prep = parts.note {
                Text(prep)
                    .font(.caption)
                    .adaptiveSecondaryForeground()
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func trailingButtons(amount: (quantity: String?, unit: String?)) -> some View {
        // Hidden once ticked: the cook already has it, and "Got it" reads calmer without editing prompts.
        if !isChecked, Self.showsAddAmount(for: ingredient, amount: amount, canEdit: onTapQuantity != nil) {
            // Amount-less rows keep a visible way into the editor beside the long-press menu.
            Button(action: { onTapQuantity?() }) {
                Label("Add amount", systemImage: "plus.circle")
                    .font(.caption.weight(.semibold))
                    .labelStyle(.titleAndIcon)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tint)
            .accessibilityLabel("Add amount for \(ingredient.mainIngredientName)")
        }

        if let onSubstitute {
            Button(action: onSubstitute) {
                Image(systemName: "arrow.2.squarepath")
                    .font(.system(size: AppTheme.fontSize16))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Find substitute for \(ingredient.mainIngredientName)")
        }

        if let onAddToShopping {
            Button(action: {
                onAddToShopping()
                HapticManager.shared.light()
            }) {
                Image(systemName: isInShoppingList ? "cart.fill" : "cart.badge.plus")
                    .font(.system(size: AppTheme.fontSize16))
                    .foregroundStyle(isInShoppingList ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(isInShoppingList)
        }
    }

    /// The amount column exactly as shown — one function shared by the row and the bundled-recipe render audit.
    static func amount(for ingredient: Ingredient, scaleFactor: Double, system: MeasurementSystem) -> (quantity: String?, unit: String?) {
        let converted = UnitConversion.convert(
            value: ingredient.scaledQuantity(for: scaleFactor),
            unit: ingredient.unit,
            to: system,
            ingredientName: ingredient.name
        )
        let quantity = converted.quantity > 0 ? FractionFormatter.format(prettyQuantity(converted.quantity)) : nil
        let unit = converted.unit.isEmpty ? nil : displayUnit(converted.unit, quantity: converted.quantity)
        return (quantity, unit)
    }

    /// An "Add amount" button replaces the dropped amount column when a needed amount is missing and editing is wired.
    nonisolated static func showsAddAmount(for ingredient: Ingredient, amount: (quantity: String?, unit: String?), canEdit: Bool) -> Bool {
        canEdit && amount.quantity == nil && amount.unit == nil && ingredient.isMissingAmount
    }

    // Snaps converted quantities to cooking-sensible precision so conversions don't surface ugly values like "14.79 ml".
    /// Nearest of the fractions cooks use — eighths/quarters OR thirds, whichever is closer (⅓ used to become ⅜).
    static func prettyQuantity(_ q: Double) -> Double {
        guard q > 0 else { return q }
        if q >= 100 { return (q / 5).rounded() * 5 }
        if q >= 10 { return q.rounded() }
        let binary = q >= 1 ? (q * 4).rounded() / 4 : (q * 8).rounded() / 8
        let thirds = (q * 3).rounded() / 3
        return abs(thirds - q) < abs(binary - q) ? thirds : binary
    }

    /// "L" (not "l", which reads as "I") and plural cups ("2 cups", not "2 cup").
    static func displayUnit(_ unit: String, quantity: Double) -> String {
        let lower = unit.lowercased()
        if lower == "l" { return "L" }
        if lower == "cup", quantity > 1 { return "cups" }
        return lower
    }
}
