import SwiftUI

// Shared CTA capsule so always-enabled actions share one look; bespoke disabled/loading buttons keep their own styling.
// `.primary` is the themed accent fill; `.secondary` is a frosted card capsule for lesser actions beside or instead of a primary.
struct PrimaryButton: View {
    enum Size { case regular, compact }
    enum Variant { case primary, secondary }

    let title: String
    let systemImage: String?
    let fillWidth: Bool
    let size: Size
    let variant: Variant
    let action: () -> Void

    init(
        _ title: String,
        systemImage: String? = nil,
        fillWidth: Bool = false,
        size: Size = .regular,
        variant: Variant = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.fillWidth = fillWidth
        self.size = size
        self.variant = variant
        self.action = action
    }

    var body: some View {
        Button {
            HapticManager.shared.light()
            action()
        } label: {
            surface(
                label
                    .font(size == .compact ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                    .adaptiveForegroundColor()
                    .padding(.horizontal, size == .compact ? AppTheme.spacing12 : AppTheme.spacing20)
                    .padding(.vertical, size == .compact ? AppTheme.spacing6 : AppTheme.spacing12)
                    .frame(maxWidth: fillWidth ? .infinity : nil)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func surface(_ content: some View) -> some View {
        switch variant {
        case .primary: content.background(Capsule().fill(AppTheme.accentColor))
        case .secondary: content.appCard(in: Capsule())
        }
    }

    @ViewBuilder
    private var label: some View {
        if let systemImage {
            if size == .compact {
                // Tighter icon gap than Label's default so the small pill doesn't look gappy.
                HStack(spacing: AppTheme.spacing6) {
                    Image(systemName: systemImage).font(.caption)
                    Text(title)
                }
            } else {
                Label(title, systemImage: systemImage)
            }
        } else {
            Text(title)
        }
    }
}
