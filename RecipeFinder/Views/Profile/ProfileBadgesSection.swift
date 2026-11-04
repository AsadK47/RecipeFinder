import SwiftUI

/// Collapsible "Achievements" badges grid on the Profile screen.
struct ProfileBadgesSection: View {
    let badgeManager: any BadgeManaging
    @Binding var isExpanded: Bool
    let colorScheme: ColorScheme
    let onSelectBadge: (Badge) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.appSpring) {
                    isExpanded.toggle()
                }
                HapticManager.shared.light()
            }) {
                HStack {
                    Image(systemName: "trophy.fill")
                        .adaptiveForegroundColor()
                    Text("Achievements")
                        .font(.headline)
                        .adaptiveForegroundColor()
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .adaptiveSecondaryForeground()
                        .font(.caption)
                }
                .padding(.horizontal, AppTheme.cardHorizontalPadding)
                .padding(.vertical, AppTheme.spacing12)
                .background(Color.secondary.opacity(AppTheme.shadowLightOpacity))
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                    let recipeCount = PersistenceController.shared.getRecipeCount()
                    let allBadges = badgeManager.getAllBadges(recipeCount: recipeCount)
                        .sorted { $0.isUnlocked && !$1.isUnlocked }
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.spacing12) {
                        ForEach(allBadges) { badge in
                            Button(action: {
                                onSelectBadge(badge)
                                HapticManager.shared.light()
                            }) {
                                BadgeCard(badge: badge, colorScheme: colorScheme)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .accessibilityLabel(badge.title)
                            .accessibilityHint(badge.isUnlocked ? "Unlocked badge. Double tap for details" : "Locked badge. \(badge.description)")
                            .accessibilityAddTraits(.isButton)
                        }
                    }
                }
                .padding(AppTheme.spacing24)
            }
        }
        .appCard(cornerRadius: AppTheme.cornerRadius16)
    }
}
