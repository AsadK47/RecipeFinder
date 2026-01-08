import SwiftUI

struct CookingTipDetailView: View {
    let tip: CookingTipModel
    let onToggleFavorite: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    @State private var isFavorite: Bool
    
    init(tip: CookingTipModel, onToggleFavorite: @escaping () -> Void) {
        self.tip = tip
        self.onToggleFavorite = onToggleFavorite
        _isFavorite = State(initialValue: tip.isFavorite)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: AppTheme.spacing32) {
                        // Title with blended card background
                        VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                            // Category and Difficulty Badges
                            HStack {
                                HStack(spacing: AppTheme.spacing8) {
                                    Image(systemName: tip.category.icon)
                                        .font(.subheadline)
                                    Text(tip.category.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                .adaptiveForegroundColor()
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(colorForCategory(tip.category))
                                )
                                
                                Spacer()
                                
                                HStack(spacing: AppTheme.spacing6) {
                                    Image(systemName: tip.difficulty.icon)
                                        .font(.caption)
                                    Text(tip.difficulty.rawValue)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                                .adaptiveForegroundColor()
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(.orange)
                                )
                            }
                            
                            // Title
                            Text(tip.title)
                                .font(.system(size: AppTheme.fontSizeTitle1, weight: .bold))
                                .adaptiveForegroundColor()
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(AppTheme.spacing24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background {
                            if cardStyle == .solid {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(AppTheme.adaptiveCard(for: colorScheme))
                            } else {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // Content Card
                        contentCard
                            .padding(.horizontal, 20)
                        
                        // Tags
                        if !tip.tags.isEmpty {
                            tagsSection
                                .padding(.horizontal, 20)
                        }
                        
                        // Date
                        HStack {
                            Image(systemName: "calendar")
                                .font(.caption)
                            Text("Added \(tip.createdDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
                .scrollBounceBehavior(.basedOnSize, axes: .vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    AnimatedHeartButton(isFavorite: $isFavorite) {
                        onToggleFavorite()
                    }
                }
            }
        }
    }
    
    // MARK: - Content Card
    
    private var contentCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing16) {
            // Icon
            ZStack {
                Circle()
                    .fill(colorForCategory(tip.category).opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: tip.category.icon)
                    .font(.system(size: AppTheme.fontSizeTitle1))
                    .foregroundColor(colorForCategory(tip.category))
            }
            
            // Content
            Text(tip.content)
                .font(.body)
                .foregroundColor(colorScheme == .dark ? .white.opacity(AppTheme.cardLightOpacity) : .black.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.spacing24)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.adaptiveCard(for: colorScheme))
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(colorForCategory(tip.category).opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Tags Section
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            HStack(spacing: AppTheme.spacing6) {
                Image(systemName: "tag.fill")
                    .font(.caption)
                Text("Related Topics")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
            
            FlowLayout(spacing: AppTheme.spacing8) {
                ForEach(tip.tags, id: \.self) { tag in
                    HStack(spacing: AppTheme.spacing4) {
                        Image(systemName: "number")
                            .font(.system(size: 8))
                        Text(tag)
                            .font(.caption)
                    }
                    .fontWeight(.medium)
                    .adaptiveForegroundColor()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background {
                        if cardStyle == .solid {
                            Capsule()
                                .fill(Color.white.opacity(colorScheme == .dark ? AppTheme.dividerOpacity : 0.05))
                        } else {
                            Capsule()
                                .fill(.ultraThinMaterial)
                        }
                    }
                    .overlay(
                        Capsule()
                            .stroke(colorForCategory(tip.category).opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func colorForCategory(_ category: CookingTipCategory) -> Color {
        switch category.color {
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "cyan": return .cyan
        case "indigo": return .indigo
        case "yellow": return .yellow
        case "pink": return .pink
        case "mint": return .mint
        default: return AppTheme.accentColor(for: selectedTheme)
        }
    }
}

#Preview {
    CookingTipDetailView(
        tip: CookingTipModel.samples[0],
        onToggleFavorite: {}
    )
    .environment(\.appTheme, .teal)
}
