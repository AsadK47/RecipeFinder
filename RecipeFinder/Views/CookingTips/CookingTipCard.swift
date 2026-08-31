import SwiftUI

/// A rich card for a cooking tip, used in the category grid view.
struct CookingTipCard: View {
    let tip: CookingTipModel
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                HStack(alignment: .top, spacing: AppTheme.spacing12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [colorForCategory(tip.category).opacity(AppTheme.shadowDarkOpacity), colorForCategory(tip.category).opacity(AppTheme.shadowLightOpacity)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: AppTheme.iconSize48, height: AppTheme.height48)
                        
                        Image(systemName: tip.category.icon)
                            .font(.system(size: AppTheme.fontSize22))
                            .foregroundColor(colorForCategory(tip.category))
                    }
                    
                    VStack(alignment: .leading, spacing: AppTheme.spacing6) {
                        Text(tip.title)
                            .font(.headline)
                            .fontWeight(.bold)
                            .adaptiveForegroundColor()
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack(spacing: AppTheme.spacing8) {
                            HStack(spacing: AppTheme.spacing4) {
                                Image(systemName: "bookmark.fill")
                                    .font(.caption2)
                                Text(tip.category.rawValue)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(colorForCategory(tip.category))
                            .padding(.horizontal, AppTheme.spacing8)
                            .padding(.vertical, AppTheme.spacing4)
                            .background(
                                Capsule()
                                    .fill(colorForCategory(tip.category).opacity(AppTheme.cardDarkOpacity))
                            )
                            
                            HStack(spacing: AppTheme.spacing4) {
                                Image(systemName: tip.difficulty.icon)
                                    .font(.caption2)
                                Text(tip.difficulty.rawValue)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.orange)
                            .padding(.horizontal, AppTheme.spacing8)
                            .padding(.vertical, AppTheme.spacing4)
                            .background(
                                Capsule()
                                    .fill(Color.orange.opacity(AppTheme.cardDarkOpacity))
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer(minLength: 4)
                    
                    Button(action: {
                        onToggleFavorite()
                    }) {
                        Image(systemName: tip.isFavorite ? "heart.fill" : "heart")
                            .font(.title3)
                            .foregroundColor(tip.isFavorite ? .pink : .secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Rectangle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(AppTheme.dividerOpacity))
                    .frame(height: AppTheme.height1)
                
                Text(tip.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(AppTheme.lineSpacingNormal)
                
                if !tip.tags.isEmpty {
                    FlowLayout(spacing: AppTheme.spacing6) {
                        ForEach(tip.tags.prefix(3), id: \.self) { tag in
                            HStack(spacing: AppTheme.spacing4) {
                                Image(systemName: "tag.fill")
                                    .font(.system(size: AppTheme.fontSize11))
                                Text(tag)
                                    .font(.caption2)
                            }
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, AppTheme.spacing8)
                            .padding(.vertical, AppTheme.spacing4)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(colorScheme == .dark ? AppTheme.dividerOpacity : 0.05))
                            )
                        }
                    }
                }
                
                HStack {
                    Spacer()
                    
                    HStack(spacing: AppTheme.spacing4) {
                        Text("Read More")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.caption)
                    }
                    .foregroundColor(colorForCategory(tip.category))
                }
            }
            .padding(AppTheme.spacing24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius20)
                        .fill(AppTheme.adaptiveCard(for: colorScheme))
                        .shadow(color: AppTheme.adaptiveShadow(for: colorScheme), radius: 8, x: 0, y: 4)
                } else {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius20)
                        .fill(.ultraThinMaterial)
                        .shadow(color: AppTheme.adaptiveShadow(for: colorScheme), radius: 8, x: 0, y: 4)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius20)
                    .stroke(
                        LinearGradient(
                            colors: [colorForCategory(tip.category).opacity(AppTheme.shadowDarkOpacity), colorForCategory(tip.category).opacity(0.0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func colorForCategory(_ category: CookingTipCategory) -> Color {
        category.displayColor(for: selectedTheme)
    }
}
