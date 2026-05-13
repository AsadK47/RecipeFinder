import SwiftUI

struct ChefTypeCard: View {
    let chefType: ChefType
    let isSelected: Bool
    let selectedTheme: AppTheme.ThemeType
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.spacing8) {
                Image(systemName: chefType.icon)
                    .font(.system(size: AppTheme.fontSize32))
                    .foregroundColor(isSelected ? AppTheme.accentColor(for: selectedTheme) : .secondary)

                Text(chefType.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .adaptiveForegroundColor()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.spacing16)
            .background {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .fill(isSelected
                          ? AppTheme.accentColor(for: selectedTheme).opacity(AppTheme.cardDarkOpacity)
                          : Color.secondary.opacity(AppTheme.shadowLightOpacity))
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                        .strokeBorder(AppTheme.accentColor(for: selectedTheme), lineWidth: 2)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
