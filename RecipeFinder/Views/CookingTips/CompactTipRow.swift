import SwiftUI

/// A compact single-line row for a cooking tip, used in the list view.
struct CompactTipRow: View {
    let tip: CookingTipModel
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.spacing12) {
                Image(systemName: tip.category.icon)
                    .font(.body)
                    .foregroundColor(colorForCategory(tip.category))
                    .frame(width: AppTheme.iconSize32)
                
                VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                    Text(tip.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .adaptiveForegroundColor()
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                    
                    HStack(spacing: AppTheme.spacing8) {
                        Text(tip.category.rawValue)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: AppTheme.spacing4) {
                            Image(systemName: tip.difficulty.icon)
                                .font(.caption2)
                            Text(tip.difficulty.rawValue)
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)
                    }
                }
                
                Spacer(minLength: 8)
                
                Button(action: {
                    onToggleFavorite()
                }) {
                    Image(systemName: tip.isFavorite ? "heart.fill" : "heart")
                        .font(.body)
                        .foregroundColor(tip.isFavorite ? .pink : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, AppTheme.spacing16)
            .padding(.vertical, AppTheme.spacing8)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .fill(AppTheme.adaptiveGlass(for: colorScheme))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func colorForCategory(_ category: CookingTipCategory) -> Color {
        category.displayColor(for: selectedTheme)
    }
}
