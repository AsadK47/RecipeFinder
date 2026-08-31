import SwiftUI

/// A removable filter chip used in the cooking tips active-filters row.
struct FilterPill: View {
    let text: String
    let color: Color
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: AppTheme.spacing4) {
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
            
            Button(action: {
                onRemove()
                HapticManager.shared.light()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .adaptiveForegroundColor()
        .padding(.horizontal, AppTheme.spacing12)
        .padding(.vertical, AppTheme.spacing6)
        .background(
            Capsule()
                .fill(color)
        )
    }
}
