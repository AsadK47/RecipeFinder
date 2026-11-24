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

/// The toast's dismiss timer, kept out of the view so it can be tested.
enum ToastDismissal {
    /// Waits `duration`, then clears the toast if it still shows `shown`. A cancelled wait still clears (the view
    /// left, so an old Undo can't come back later) unless a newer message replaced it (`.task(id:)` restarted).
    @MainActor
    static func run(showing shown: String, for duration: Duration, current: () -> String?, clear: () -> Void) async {
        try? await Task.sleep(for: duration) // Cancellation ends the wait early; the check below decides.
        guard current() == shown else { return }
        clear()
    }
}

/// What VoiceOver hears when a toast appears; it can't see the capsule slide in.
enum ToastAnnouncement {
    static func text(for message: String, actionTitle: String?) -> String? {
        actionTitle.map { "\(message). \($0) available" }
    }
}

private struct ToastModifier: ViewModifier {
    @Binding var message: String?
    let icon: String
    let action: (title: String, perform: () -> Void)?
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverOn

    /// A toast with a button stays long enough to reach it — much longer with VoiceOver, which has to find it first.
    private var shownFor: Duration {
        guard action != nil else { return .seconds(3) }
        return voiceOverOn ? .seconds(15) : .seconds(6)
    }

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
                guard let shown = message else { return }
                if let announcement = ToastAnnouncement.text(for: shown, actionTitle: action?.title) {
                    AccessibilityNotification.Announcement(announcement).post()
                }
                await ToastDismissal.run(showing: shown, for: shownFor, current: { message }, clear: { message = nil })
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
