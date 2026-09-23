import SwiftUI

/// The checked/total progress bar shown above the shopping list. Extracted from
/// `ShoppingListView`.
struct ShoppingProgressBar: View {
    let checkedCount: Int
    let totalCount: Int
    let selectedTheme: AppTheme.ThemeType

    var body: some View {
        VStack(spacing: AppTheme.spacing6) {
            // Clamp the denominator to ≥1: an empty list (or the transient frame
            // while the last item animates out) makes total 0, which would give
            // ProgressView a NaN fraction → "Invalid frame dimension (non-finite)".
            ProgressView(value: Double(checkedCount), total: Double(max(totalCount, 1)))
                .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.accentColor(for: selectedTheme)))
                .frame(height: AppTheme.height8)
                .accessibilityLabel("Groceries progress")
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
