import SwiftUI

/// Single source of truth for card/tile surfaces so they stay consistent; honours the user's `cardStyle` setting (frosted by default, opaque Solid on request).
extension View {
    func appCard(cornerRadius: CGFloat = AppTheme.cornerRadius16) -> some View {
        modifier(AppCardModifier(cornerRadius: cornerRadius))
    }
}

private struct AppCardModifier: ViewModifier {
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content.background {
            let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            if cardStyle == .solid {
                shape.fill(AppTheme.adaptive(
                    light: AppTheme.cardBackground(for: .light),
                    dark: AppTheme.cardBackground(for: .dark)
                ))
            } else {
                shape.fill(.ultraThinMaterial)
            }
        }
    }
}
