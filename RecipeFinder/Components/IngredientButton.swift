import SwiftUI

struct IngredientButton: View {
    let ingredient: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.light()
            action()
        }) {
            HStack {
                Text(ingredient)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppTheme.accentColor.opacity(0.6))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
