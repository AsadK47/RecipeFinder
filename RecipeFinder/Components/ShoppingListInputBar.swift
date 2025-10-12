import SwiftUI

struct ShoppingListInputBar: View {
    @Binding var text: String
    var onAdd: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(AppTheme.accentColor)
                
                TextField("Add item...", text: $text)
                    .focused($isFocused)
                    .autocorrectionDisabled()
                    .onSubmit {
                        onAdd()
                    }
                
                if !text.isEmpty {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            
            if !text.isEmpty {
                Button(action: onAdd) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(AppTheme.accentColor)
                        )
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: text.isEmpty)
    }
}
