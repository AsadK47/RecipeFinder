import SwiftUI

/// Translucent input chrome that blends into frosted `.appCard()` surfaces; pair with `.textFieldStyle(.plain)` instead of `.roundedBorder` (whose solid fill clashes).
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
            // Hairline border so the field stays legible over lighter gradient areas where the translucent fill has too little contrast.
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AppTheme.dividerColor, lineWidth: 0.5)
            )
    }
}
