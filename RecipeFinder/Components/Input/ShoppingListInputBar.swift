import SwiftUI

struct ShoppingListInputBar: View {
    @Binding var text: String
    var onAdd: () -> Void
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: AppTheme.spacingMD) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(AppTheme.adaptiveEmphasis(for: colorScheme))
                
                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text("Add item...")
                            .foregroundColor(AppTheme.adaptiveMediumEmphasis(for: colorScheme))
                    }
                    TextField("", text: $text)
                        .focused($isFocused)
                        .autocorrectionDisabled()
                        .foregroundColor(AppTheme.adaptiveEmphasis(for: colorScheme))
                        .onSubmit {
                            onAdd()
                        }
                }
                
                if !text.isEmpty {
                    Button(action: { text = "" }, label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    })
                }
            }
            .padding(AppTheme.spacingMD)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            
            if !text.isEmpty {
                Button(action: onAdd, label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(AppTheme.accentColor)
                        )
                })
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: text.isEmpty)
    }
}
