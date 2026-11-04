import SwiftUI

struct FilterChip: View {
    let label: String
    let icon: String
    let onRemove: () -> Void

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
                    .foregroundStyle(AppTheme.adaptiveHighEmphasis)
            })
        }
        .foregroundStyle(AppTheme.adaptiveEmphasis())
        .padding(.horizontal, AppTheme.spacing12)
        .padding(.vertical, AppTheme.spacing6)
        .background(
            Capsule()
                .fill(AppTheme.adaptiveFilterChip)
        )
    }
}
