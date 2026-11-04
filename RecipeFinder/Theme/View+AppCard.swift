import SwiftUI

/// Single source of truth for card/tile surfaces so they stay consistent: frosted glass in the given shape.
/// `elevated` adds the drop shadow used by stand-alone cards.
extension View {
    func appCard(cornerRadius: CGFloat = AppTheme.cornerRadius16, elevated: Bool = false) -> some View {
        appCard(in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous), elevated: elevated)
    }

    /// The same surface in any shape — circles for icon buttons, capsules for pills.
    func appCard<S: Shape>(in shape: S, elevated: Bool = false) -> some View {
        modifier(AppCardModifier(shape: shape, elevated: elevated))
    }
}

private struct AppCardModifier<S: Shape>: ViewModifier {
    let shape: S
    let elevated: Bool

    func body(content: Content) -> some View {
        content.background {
            shape
                .fill(.ultraThinMaterial)
                .shadow(
                    color: elevated
                        ? AppTheme.adaptive(light: .black.opacity(0.15), dark: .black.opacity(0.3))
                        : .clear,
                    radius: 10, x: 0, y: 4
                )
        }
    }
}
