import SwiftUI

struct FilterChip: View {
    let label: String
    let icon: String
    let onRemove: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: AppTheme.spacing6) {
            Image(systemName: icon)
                .font(.caption2)
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
            Button(action: onRemove, label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(AppTheme.adaptiveHighEmphasis(for: colorScheme))
            })
        }
        .foregroundColor(AppTheme.adaptiveEmphasis(for: colorScheme))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(AppTheme.adaptiveFilterChip(for: colorScheme))
        )
    }
}

// Filter Button Component
struct FilterButton: View {
    let label: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
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
                    .foregroundColor(isSelected ? AppTheme.textColor(for: colorScheme) : (AppTheme.adaptiveEmphasis(for: colorScheme)))
                    .lineLimit(1)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: AppTheme.fontSize16 + 2))
                        .adaptiveForegroundColor()
                }
            }
            .padding(AppTheme.spacing12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color : AppTheme.adaptiveFilterChip(for: colorScheme))
            )
        }
    }
}
