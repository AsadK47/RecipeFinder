import SwiftUI

/// The app's single source of truth for a tile / card surface.
///
/// Historically each view hand-rolled its own background (`Color(.systemGray6)`,
/// `Color.white.opacity(...)`, `AppTheme.cardBackground`, bare materials), which is
/// why tiles drifted out of sync across screens. Route every card/tile through
/// `.appCard()` so the surface stays consistent. The look is a frosted translucent
/// fill over the screen's background gradient — matching the settings tiles.
extension View {
    func appCard(cornerRadius: CGFloat = AppTheme.cornerRadius16) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }
}
