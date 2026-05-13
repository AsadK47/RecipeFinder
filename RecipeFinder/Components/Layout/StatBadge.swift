import SwiftUI

struct StatBadge: View {
    let icon: String
    let count: Int
    let label: String

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: AppTheme.spacing4) {
            HStack(spacing: AppTheme.spacing4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text("\(count)")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            .foregroundColor(colorScheme == .dark ? .white : .primary)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.spacing8)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius8)
                .fill(Color.secondary.opacity(AppTheme.shadowLightOpacity))
        )
    }
}
