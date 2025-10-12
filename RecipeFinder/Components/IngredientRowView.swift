import SwiftUI

struct IngredientRowView: View {
    let ingredient: Ingredient
    let isChecked: Bool
    let toggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { withAnimation(.spring(response: 0.3)) { toggle() } }) {
                ZStack {
                    Circle()
                        .strokeBorder(isChecked ? AppTheme.accentColor : Color.gray, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(AppTheme.accentColor))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(ingredient.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(isChecked)
                    .foregroundColor(isChecked ? .gray : .primary)
                
                Text("\(ingredient.formattedQuantity) \(ingredient.unit)")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
