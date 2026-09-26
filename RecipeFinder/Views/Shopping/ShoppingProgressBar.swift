import SwiftUI

/// Checked/total progress bar shown above the shopping list.
struct ShoppingProgressBar: View {
    let checkedCount: Int
    let totalCount: Int
    let selectedTheme: AppTheme.ThemeType

    var body: some View {
        VStack(spacing: AppTheme.spacing6) {
            // Clamp denominator to ≥1: total 0 gives ProgressView a NaN fraction → "Invalid frame dimension (non-finite)".
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
