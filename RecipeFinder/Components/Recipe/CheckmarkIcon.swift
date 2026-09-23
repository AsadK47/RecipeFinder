import SwiftUI

/// The check-it-off indicator used by recipe ingredient and step rows — a green
/// filled circle when done, a faint hollow circle when not. Defined once so the
/// two rows can't drift apart again (they previously hand-rolled the same image).
struct CheckmarkIcon: View {
    let isChecked: Bool

    var body: some View {
        Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
            .font(.system(size: AppTheme.fontSize22))
            .foregroundStyle(isChecked ? .green : .gray.opacity(AppTheme.lowEmphasisOpacity))
    }
}
