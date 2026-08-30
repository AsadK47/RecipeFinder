import SwiftUI

/// The checked/total progress bar shown above the shopping list. Extracted from
/// `ShoppingListView`.
struct ShoppingProgressBar: View {
    let checkedCount: Int
    let totalCount: Int
    let selectedTheme: AppTheme.ThemeType

    var body: some View {
        VStack(spacing: AppTheme.spacing6) {
            ProgressView(value: Double(checkedCount), total: Double(totalCount))
                .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.accentColor(for: selectedTheme)))
                .frame(height: AppTheme.height8)
                .accessibilityLabel("Shopping progress")
                .accessibilityValue("\(checkedCount) of \(totalCount) items checked")

            HStack {
                Text("\(checkedCount)/\(totalCount) completed")
                    .font(.caption2)
                    .adaptiveForegroundColor(opacity: AppTheme.highEmphasisOpacity)
                    .accessibilityHidden(true)
                Spacer()
            }
        }
        .padding(.horizontal, AppTheme.spacing20)
        .padding(.bottom, AppTheme.spacing2)
    }
}
