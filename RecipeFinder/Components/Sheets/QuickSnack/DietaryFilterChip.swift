import SwiftUI

struct DietaryFilterChip: View {
    let filter: DietaryTag
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.spacing4) {
                Text(filter.icon)
                    .font(.caption)
                Text(filter.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, AppTheme.spacing12)
            .padding(.vertical, AppTheme.spacing6)
            .background(
                isSelected ?
                Color.green.opacity(AppTheme.highEmphasisOpacity) :
                Color.white.opacity(AppTheme.overlayLightOpacity)
            )
            .adaptiveForegroundColor()
            .cornerRadius(AppTheme.cornerRadius16)
        }
    }
}
