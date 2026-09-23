import SwiftUI

/// The app's primary call-to-action button — a themed accent capsule.
///
/// Screens previously hand-rolled prominent actions with mixed shapes (capsules,
/// rounded rectangles at radius 12 and 16) and foregrounds. Route always-enabled
/// primary actions through this so they share one look. Buttons with bespoke
/// disabled/loading states keep their own styling for now.
struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    var fillWidth: Bool = false
    let action: () -> Void

    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal

    init(_ title: String, systemImage: String? = nil, fillWidth: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.fillWidth = fillWidth
        self.action = action
    }

    var body: some View {
        Button {
            HapticManager.shared.light()
            action()
        } label: {
            label
                .font(.subheadline.weight(.semibold))
                .adaptiveForegroundColor()
                .padding(.horizontal, AppTheme.spacing20)
                .padding(.vertical, AppTheme.spacing12)
                .frame(maxWidth: fillWidth ? .infinity : nil)
                .background(Capsule().fill(AppTheme.accentColor(for: selectedTheme)))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var label: some View {
        if let systemImage {
            Label(title, systemImage: systemImage)
        } else {
            Text(title)
        }
    }
}
