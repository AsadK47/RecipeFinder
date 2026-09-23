import SwiftUI

/// The app's single source of truth for a tile / card surface.
///
/// Historically each view hand-rolled its own background (`Color(.systemGray6)`,
/// `Color.white.opacity(...)`, `AppTheme.cardBackground`, bare materials), which is
/// why tiles drifted out of sync across screens. Route every card/tile through
/// `.appCard()` so the surface stays consistent.
///
/// Honours the user's `cardStyle` appearance setting — frosted translucent by
/// default, or an opaque solid fill (matching `CardView`) when they choose Solid.
/// It previously hardcoded `.ultraThinMaterial`, so `.appCard()` tiles silently
/// ignored the Solid setting while hand-rolled tiles respected it.
extension View {
    func appCard(cornerRadius: CGFloat = AppTheme.cornerRadius16) -> some View {
        modifier(AppCardModifier(cornerRadius: cornerRadius))
    }
}

private struct AppCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content.background {
            let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            if cardStyle == .solid {
                shape.fill(AppTheme.cardBackground(for: colorScheme))
            } else {
                shape.fill(.ultraThinMaterial)
            }
        }
    }
}
