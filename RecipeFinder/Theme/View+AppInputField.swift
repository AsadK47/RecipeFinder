import SwiftUI

/// Consistent chrome for a text/menu input on a form card: a translucent fill
/// that blends into the frosted `.appCard()` surface — the same treatment the
/// recipe-name field uses — instead of an opaque box.
///
/// Use this (paired with `.textFieldStyle(.plain)`) rather than
/// `.textFieldStyle(.roundedBorder)`, whose solid white fill clashes with the
/// app's frosted cards. One home for field chrome so inputs can't drift.
extension View {
    func appInputField(cornerRadius: CGFloat = AppTheme.cornerRadius12) -> some View {
        modifier(AppInputFieldModifier(cornerRadius: cornerRadius))
    }
}

private struct AppInputFieldModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, AppTheme.spacing12)
            .padding(.vertical, AppTheme.spacing10)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(AppTheme.dividerOpacity))
            )
            // Hairline border so the field stays legible on any part of the
            // background gradient — the translucent fill alone has too little
            // contrast on the lighter areas. Divider colour adapts to light/dark.
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AppTheme.dividerColor, lineWidth: 0.5)
            )
    }
}
