import SwiftUI

// Shared confirmation toast: set the bound string to show a bottom accent capsule that animates in and auto-dismisses, keeping look/timing consistent across screens.
extension View {
    /// `action` adds a button to the toast (e.g. Undo); the toast then stays a little longer so it can be reached.
    func toast(
        _ message: Binding<String?>, icon: String = "cart.fill", action: (title: String, perform: () -> Void)? = nil
    ) -> some View {
        modifier(ToastModifier(message: message, icon: icon, action: action))
    }
}

private struct ToastModifier: ViewModifier {
    @Binding var message: String?
    let icon: String
    let action: (title: String, perform: () -> Void)?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message {
                    ToastLabel(text: message, icon: icon, action: action.map { action in
                        (title: action.title, perform: {
                            action.perform()
                            self.message = nil
                        })
                    })
                        .padding(.bottom, AppTheme.spacing20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.appGentle, value: message)
            // `.task(id:)` restarts on message change so rapid updates reset the dismiss timer instead of clearing early.
            .task(id: message) {
                guard message != nil else { return }
                try? await Task.sleep(for: .seconds(action == nil ? 3 : 5))
                message = nil
            }
    }
}

private struct ToastLabel: View {
    let text: String
    let icon: String
    let action: (title: String, perform: () -> Void)?

    var body: some View {
        HStack(spacing: AppTheme.spacing12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.onAccent)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(AppTheme.onAccent)
                .lineLimit(2)
            if let action {
                Button(action.title, action: action.perform)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.onAccent)
                    .accessibilityIdentifier("toast.action")
            }
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
