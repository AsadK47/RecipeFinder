import SwiftUI

struct WeekDayRow: View {
    let date: Date
    let isToday: Bool
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    let onAddMeal: () -> Void
    
    private var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        HStack(spacing: AppTheme.spacing12) {
            VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                Text(dayString)
                    .font(.system(size: AppTheme.fontSize16, weight: .semibold))
                    .adaptiveForegroundColor()
                
                if isToday {
                    Text("Today")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            HStack(spacing: AppTheme.spacing8) {
                ForEach(["☀️", "🍽️", "🌙"], id: \.self) { icon in
                    Button(action: onAddMeal) {
                        Circle()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(AppTheme.dividerOpacity))
                            .frame(width: AppTheme.iconSize32, height: 32)
                            .overlay {
                                Text(icon)
                                    .font(.caption)
                                    .opacity(AppTheme.glassLightOpacity)
                            }
                    }
                }
            }
            
            Button(action: onAddMeal) {
                Image(systemName: "plus.circle")
                    .font(.title3)
                    .foregroundColor(AppTheme.adaptiveMediumEmphasis(for: colorScheme))
            }
        }
        .padding(AppTheme.spacing12)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .fill(isToday ? (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(AppTheme.dividerOpacity)) : (colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05)))
            } else {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .fill(isToday ? (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(AppTheme.dividerOpacity)) : Color.clear)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                .stroke(isToday ? AppTheme.success.opacity(0.5) : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(AppTheme.dividerOpacity)), lineWidth: isToday ? 2 : 1)
        )
    }
}
