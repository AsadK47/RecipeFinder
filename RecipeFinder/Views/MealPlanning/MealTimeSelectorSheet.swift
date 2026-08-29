import SwiftUI

struct MealTimeSelectorSheet: View {
    let selectedDate: Date
    @Binding var selectedMealTimes: Set<MealTime>
    let onContinue: (MealTime) -> Void
    
    @Environment(\.dismiss) var dismiss
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                VStack(spacing: AppTheme.spacing12) {
                    HStack {
                        Spacer()
                        
                        Button(action: { dismiss() }) {
                            HStack(spacing: AppTheme.spacing6) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                Text("Cancel")
                                    .font(.system(size: AppTheme.fontSize16, weight: .semibold))
                            }
                            .adaptiveForegroundColor(opacity: AppTheme.veryHighEmphasisOpacity)
                        }
                    }
                    .padding(.horizontal, AppTheme.spacing20)
                    .padding(.top, AppTheme.spacing20)
                    
                    Text("Plan a Meal")
                        .font(.system(size: AppTheme.fontSize28, weight: .bold))
                        .adaptiveForegroundColor()
                        .shadow(color: .black.opacity(AppTheme.overlayLightOpacity), radius: 2, x: 0, y: 1)
                    
                    HStack(spacing: AppTheme.spacing8) {
                        Image(systemName: "calendar")
                            .font(.subheadline)
                        Text(dateString)
                            .font(.system(size: AppTheme.fontSize16, weight: .medium))
                    }
                    .adaptiveForegroundColor(opacity: AppTheme.nearSolidOpacity)
                }
                .padding(.bottom, AppTheme.spacing20)
                
                ScrollView {
                    VStack(spacing: AppTheme.spacing12) {
                            ForEach(MealTime.allCases, id: \.self) { mealTime in
                                Button(action: {
                                    selectedMealTimes.insert(mealTime)
                                    onContinue(mealTime)
                                    HapticManager.shared.light()
                                }) {
                                    HStack(spacing: AppTheme.spacing16) {
                                        ZStack {
                                            Circle()
                                                .fill(selectedMealTimes.contains(mealTime) 
                                                      ? AppTheme.success.opacity(0.2) 
                                                      : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(AppTheme.dividerOpacity)))
                                                .frame(width: 50, height: AppTheme.height50)
                                            
                                            Image(systemName: mealTime.icon)
                                                .font(.system(size: AppTheme.fontSize22, weight: .semibold))
                                                .foregroundColor(selectedMealTimes.contains(mealTime) ? .green : (colorScheme == .dark ? .white.opacity(AppTheme.cardLightOpacity) : .black.opacity(0.9)))
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
                                        }
                                        
                                        Spacer()
                                        
                                        if selectedMealTimes.contains(mealTime) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title3)
                                                .foregroundColor(.green)
                                        } else {
                                            Image(systemName: "plus.circle")
                                                .font(.title3)
                                                .foregroundColor(colorScheme == .dark ? .white.opacity(AppTheme.lowEmphasisOpacity) : .black.opacity(AppTheme.lowEmphasisOpacity))
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
                                            .stroke(selectedMealTimes.contains(mealTime) 
                                                    ? AppTheme.success.opacity(0.5) 
                                                    : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(AppTheme.dividerOpacity)), 
                                                    lineWidth: selectedMealTimes.contains(mealTime) ? 2 : 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, AppTheme.spacing20)
                        .padding(.bottom, AppTheme.spacing100)
                    }
                }
            }
        }
        
        private var dateString: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d, yyyy"
            return formatter.string(from: selectedDate)
        }
    }
