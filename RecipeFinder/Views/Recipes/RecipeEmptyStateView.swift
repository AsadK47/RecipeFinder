import SwiftUI

/// Shown when no recipes match the current search/filters, with a shortcut to
/// clear filters when any are active. Extracted from `RecipeSearchView`.
struct RecipeEmptyStateView: View {
    let activeFilterCount: Int
    let onClearFilters: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacing24) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: AppTheme.fontSize60))
                    .adaptiveForegroundColor(opacity: AppTheme.lowEmphasisOpacity)
                
                Text("No Recipes Found")
                    .font(.title2)
                    .fontWeight(.bold)
                    .adaptiveForegroundColor()
                
                Text("Try adjusting your filters or search")
                    .font(.subheadline)
                    .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
                
                if activeFilterCount > 0 {
                    Button(action: onClearFilters, label: {
                        HStack(spacing: AppTheme.spacing8) {
                            Image(systemName: "xmark.circle.fill")
                            Text("Clear All Filters")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .adaptiveForegroundColor()
                        .padding(.horizontal, AppTheme.spacing20)
                        .padding(.vertical, AppTheme.spacing12)
                        .background(
                            Group {
                                if cardStyle == .solid {
                                    Capsule()
                                        .fill(AppTheme.adaptiveCard(for: colorScheme))
                                } else {
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                }
                            }
                        )
                    })
                }
            }
            .padding(.top, AppTheme.spacing40)
        }
    }
}
