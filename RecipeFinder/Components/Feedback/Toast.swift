import SwiftUI

/// The app's single confirmation toast — a bottom accent capsule used for
/// "added to Groceries" style feedback. Set the bound string to show it; the
/// modifier animates it in and auto-dismisses, clearing the binding for you.
///
/// Screens previously each hand-rolled this capsule plus a `DispatchQueue`
/// auto-clear (recipe detail, collections, meal planning), which drifted in
/// look and timing. Route feedback through `.toast(_:)` so it stays consistent.
extension View {
    func toast(_ message: Binding<String?>, icon: String = "cart.fill") -> some View {
        modifier(ToastModifier(message: message, icon: icon))
    }
}

private struct ToastModifier: ViewModifier {
    @Binding var message: String?
    let icon: String

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message {
                    ToastLabel(text: message, icon: icon)
                        .padding(.bottom, AppTheme.spacing20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: message)
            // `.task(id:)` restarts whenever the message changes, so rapid
            // updates reset the dismiss timer instead of clearing early.
            .task(id: message) {
                guard message != nil else { return }
                try? await Task.sleep(for: .seconds(3))
                message = nil
            }
    }
}

private struct ToastLabel: View {
    let text: String
    let icon: String

    var body: some View {
        HStack(spacing: AppTheme.spacing12) {
            Image(systemName: icon)
                .adaptiveForegroundColor()
            Text(text)
                .font(.subheadline)
                .adaptiveForegroundColor()
        }
        .padding(.horizontal, AppTheme.spacing20)
        .padding(.vertical, AppTheme.spacing12)
        .background(
            Capsule()
                .fill(AppTheme.accentColor)
                .shadow(color: .black.opacity(AppTheme.overlayLightOpacity), radius: 8, y: 4)
        )
    }
}
