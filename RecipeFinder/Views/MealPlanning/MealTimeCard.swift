import SwiftUI

struct MealTimeCard: View {
    let mealTime: MealTime
    let recipe: RecipeModel?
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    var onRemove: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: AppTheme.spacing16) {
            ZStack {
                Circle()
                    .fill(colorScheme == .dark ? Color.white.opacity(AppTheme.cardDarkOpacity) : Color.black.opacity(AppTheme.cardDarkOpacity))
                    .frame(width: 52, height: AppTheme.buttonHeightLarge)
                
                Image(systemName: mealTime.icon)
                    .font(.system(size: AppTheme.fontSize22, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(AppTheme.cardLightOpacity) : .black.opacity(0.9))
            }
            
            VStack(alignment: .leading, spacing: AppTheme.spacing6) {
                Text(mealTime.rawValue)
                    .font(.system(size: AppTheme.fontSize18, weight: .semibold))
                    .adaptiveForegroundColor()
                
                HStack(spacing: AppTheme.spacing4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(mealTime.timeRange)
                        .font(.caption)
                }
                .foregroundColor(AppTheme.adaptiveMediumEmphasis(for: colorScheme))
                
                if let recipe = recipe {
                    HStack(spacing: AppTheme.spacing6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text(recipe.name)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .adaptiveForegroundColor(opacity: AppTheme.veryHighEmphasisOpacity)
                } else {
                    HStack(spacing: AppTheme.spacing6) {
                        Image(systemName: "fork.knife")
                            .font(.caption2)
                        Text("Tap to add recipe")
                            .font(.caption)
                    }
                    .adaptiveForegroundColor(opacity: AppTheme.glassLightOpacity)
                }
            }
            
            Spacer()
            
            HStack(spacing: AppTheme.spacing8) {
                if let onRemove, recipe != nil {
                    Button(action: onRemove) {
                        Image(systemName: "trash")
                            .font(.system(size: AppTheme.fontSize14, weight: .semibold))
                            .foregroundColor(.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                Image(systemName: recipe != nil ? "pencil.circle" : "chevron.right")
                    .font(.system(size: AppTheme.fontSize14, weight: .semibold))
                    .adaptiveForegroundColor(opacity: AppTheme.lowEmphasisOpacity)
            }
        }
        .padding(AppTheme.spacing16)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                    .fill(colorScheme == .dark ? Color.white.opacity(AppTheme.glassSubtleOpacity) : Color.white.opacity(AppTheme.cardDarkOpacity))
            } else {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                    .fill(.ultraThinMaterial)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                .stroke(recipe != nil ? AppTheme.success.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
