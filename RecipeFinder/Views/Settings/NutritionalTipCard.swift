import SwiftUI

/// A compact card for a nutritional tip in the tips grid.
struct NutritionalTipCard: View {
    let tip: NutritionalTip
    let action: () -> Void
    
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.spacing16) {
                Text(tip.icon)
                    .font(.system(size: AppTheme.fontSize42))
                
                VStack(alignment: .leading, spacing: AppTheme.spacing6) {
                    Text(tip.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .adaptiveForegroundColor()
                        .multilineTextAlignment(.leading)
                    
                    Text(tip.summary)
                        .font(.caption)
                        .adaptiveForegroundColor(opacity: AppTheme.disabledEmphasisOpacity)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: AppTheme.spacing8) {
                        Text(tip.category.icon)
                            .font(.caption2)
                        Text(tip.category.rawValue)
                            .font(.caption2)
                            .adaptiveForegroundColor(opacity: AppTheme.glassLightOpacity)
                        
                        Text("•")
                            .adaptiveForegroundColor(opacity: AppTheme.shadowDarkOpacity)
                        
                        Text("\(tip.sources.count) sources")
                            .font(.caption2)
                            .adaptiveForegroundColor(opacity: AppTheme.glassLightOpacity)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .adaptiveForegroundColor(opacity: AppTheme.lowEmphasisOpacity)
            }
            .padding()
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                        .fill(AppTheme.adaptiveCard(for: colorScheme))
                } else {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                        .fill(.ultraThinMaterial)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
