import SwiftUI

// Empty state for no search/filter matches, with a clear search/filters shortcut.
struct RecipeEmptyStateView: View {
    /// From `RecipeFilterCriteria.clearActionTitle`; nil hides the button.
    let clearActionTitle: String?
    let onClearFilters: () -> Void

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
                
                if let clearActionTitle {
                    PrimaryButton(clearActionTitle, systemImage: "xmark.circle.fill", variant: .secondary, action: onClearFilters)
                }
            }
            .padding(.top, AppTheme.spacing40)
        }
    }
}
