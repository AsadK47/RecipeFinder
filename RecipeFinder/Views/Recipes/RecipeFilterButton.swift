import SwiftUI

struct RecipeFilterButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action, label: {
            Text(label)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .adaptiveForegroundColor()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.height44)
                .background(
                    Capsule()
                        .fill(isSelected ? AppTheme.accentColor : Color.white.opacity(0.15))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
                )
        })
        .buttonStyle(.plain)
    }
}
