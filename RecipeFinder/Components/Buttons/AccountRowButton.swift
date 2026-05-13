import SwiftUI

struct AccountRowButton: View {
    let icon: String
    var iconColor: Color = .blue
    let title: String
    var subtitle: String?
    var showChevron: Bool = false
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.spacing16) {
                ZStack {
                    Circle()
                        .fill(iconColor)
                        .frame(width: AppTheme.iconSize40, height: AppTheme.iconSize40)

                    Image(systemName: icon)
                        .font(.system(size: AppTheme.fontSize16 + 2, weight: .semibold))
                        .adaptiveForegroundColor()
                }

                VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: AppTheme.fontSize13, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, AppTheme.spacing16)
            .padding(.vertical, AppTheme.spacing12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
