import SwiftUI

struct ModernSearchBar: View {
    @Binding var text: String
    var placeholder: String
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.adaptiveHighEmphasis(for: colorScheme))
                    .font(.body)
                
                TextField(placeholder, text: $text)
                    .focused($isFocused)
                    .autocorrectionDisabled()
                    .foregroundColor(AppTheme.adaptiveEmphasis(for: colorScheme))
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(AppTheme.mediumEmphasisOpacity) : .black.opacity(AppTheme.mediumEmphasisOpacity))
                    }
                
                if !text.isEmpty {
                    Button(action: { text = "" }, label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.5))
                    })
                }
            }
            .padding(14)
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color(white: AppTheme.cardDarkMediumOpacity) : Color.white.opacity(AppTheme.cardLightOpacity))
                } else {
                    // Pure frosted glass - exactly like Settings
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                }
            }
            
            if isFocused {
                Button("Cancel") {
                    text = ""
                    isFocused = false
                }
                .foregroundColor(AppTheme.adaptiveEmphasis(for: colorScheme))
                .fontWeight(.semibold)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: isFocused)
    }
}

// Extension to add placeholder modifier
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
