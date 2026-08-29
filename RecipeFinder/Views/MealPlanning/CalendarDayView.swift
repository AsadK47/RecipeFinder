import SwiftUI

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasPlannedMeals: Bool
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: AppTheme.spacing4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: AppTheme.fontSize16, weight: isSelected ? .bold : (isToday ? .semibold : .regular)))
                .foregroundColor(textColor)
            
            if hasPlannedMeals {
                Circle()
                    .fill(Color.green)
                    .frame(width: 4, height: AppTheme.height4)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: AppTheme.height50)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .fill(Color.white)
                    .shadow(color: Color.white.opacity(AppTheme.shadowDarkOpacity), radius: 8, x: 0, y: 4)
            } else if isToday {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .stroke(colorScheme == .dark ? Color.white.opacity(AppTheme.glassLightOpacity) : Color.black.opacity(AppTheme.glassLightOpacity), lineWidth: 2)
            }
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    private var textColor: Color {
        if isSelected {
            return Color.blue
        } else if isToday {
            return AppTheme.adaptiveEmphasis(for: colorScheme)
        } else {
            return colorScheme == .dark ? .white.opacity(AppTheme.highEmphasisOpacity) : .black.opacity(AppTheme.highEmphasisOpacity)
        }
    }
}
