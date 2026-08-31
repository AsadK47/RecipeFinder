import SwiftUI

/// The grouped, expandable category grid of cooking tip cards. Extracted from
/// `CookingTipsView`.
struct CookingTipCategoryGrid: View {
    @ObservedObject var tipsManager: CookingTipsManager
    @Binding var expandedCategories: Set<String>
    let selectedTheme: AppTheme.ThemeType
    let colorScheme: ColorScheme
    let onSelectTip: (CookingTipModel) -> Void

    var body: some View {
        VStack(spacing: AppTheme.spacing24) {
            ForEach(CookingTipCategory.allCases) { category in
                let categoryTips = tipsManager.tipsForCategory(category)
                    .filter { tip in
                        tipsManager.searchText.isEmpty ||
                        tip.title.localizedCaseInsensitiveContains(tipsManager.searchText) ||
                        tip.content.localizedCaseInsensitiveContains(tipsManager.searchText)
                    }

                if !categoryTips.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if expandedCategories.contains(category.rawValue) {
                                    expandedCategories.remove(category.rawValue)
                                } else {
                                    expandedCategories.insert(category.rawValue)
                                }
                            }
                            HapticManager.shared.light()
                        }) {
                            HStack(spacing: AppTheme.spacing8) {
                                Image(systemName: category.icon)
                                    .font(.title3)
                                    .foregroundColor(colorForCategory(category))
                                
                                Text(category.rawValue)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .adaptiveForegroundColor()
                                
                                Spacer()
                                
                                Text("\(categoryTips.count)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, AppTheme.spacing8)
                                    .padding(.vertical, AppTheme.spacing4)
                                    .background(
                                        Capsule()
                                            .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(AppTheme.dividerOpacity))
                                    )
                                
                                Image(systemName: expandedCategories.contains(category.rawValue) ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        if expandedCategories.contains(category.rawValue) {
                            VStack(spacing: AppTheme.spacing12) {
                                ForEach(categoryTips) { tip in
                                    CookingTipCard(tip: tip, onTap: {
                                        onSelectTip(tip)
                                    }, onToggleFavorite: {
                                        tipsManager.toggleFavorite(tip)
                                    })
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }
            }
        }
    }

    private func colorForCategory(_ category: CookingTipCategory) -> Color {
        category.displayColor(for: selectedTheme)
    }
}
