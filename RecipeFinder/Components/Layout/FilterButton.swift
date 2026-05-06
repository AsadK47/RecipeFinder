import SwiftUI

struct FilterButton: View {
    let label: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme

    private enum Layout {
        static let checkmarkSize: CGFloat = 18
        static let labelLineLimit: Int = 1
    }

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: AppTheme.spacing8) {
                Image(systemName: icon)
                    .font(.system(size: AppTheme.fontSize16))
                    .foregroundColor(isSelected ? AppTheme.textColor(for: colorScheme) : color)

                Text(label)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? AppTheme.textColor(for: colorScheme) : AppTheme.adaptiveEmphasis(for: colorScheme))
                    .lineLimit(Layout.labelLineLimit)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: Layout.checkmarkSize))
                        .adaptiveForegroundColor()
                }
            }
            .padding(AppTheme.spacing12)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .fill(isSelected ? color : AppTheme.adaptiveFilterChip(for: colorScheme))
            )
        }
    }
}
