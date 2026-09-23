import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted

    private enum Timing {
        static let springResponse: Double = 0.3
    }

    var body: some View {
        HStack(spacing: AppTheme.spacing12) {
            HStack(spacing: AppTheme.spacing12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppTheme.adaptiveHighEmphasis(for: colorScheme))
                    .font(.body)

                TextField(placeholder, text: $text)
                    .focused($isFocused)
                    .autocorrectionDisabled()
                    .foregroundStyle(AppTheme.adaptiveEmphasis(for: colorScheme))
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder)
                            .foregroundStyle(AppTheme.adaptiveMediumEmphasis(for: colorScheme))
                    }

                if !text.isEmpty {
                    Button(action: { text = "" }, label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppTheme.adaptiveSubtitle(for: colorScheme))
                    })
                }
            }
            .padding(AppTheme.spacing16)
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                        .fill(AppTheme.adaptiveCardMedium(for: colorScheme))
                } else {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                        .fill(.ultraThinMaterial)
                }
            }

            if isFocused {
                Button("Cancel") {
                    text = ""
                    isFocused = false
                }
                .foregroundStyle(AppTheme.adaptiveEmphasis(for: colorScheme))
                .fontWeight(.semibold)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: Timing.springResponse), value: isFocused)
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? AppTheme.fullOpacity : AppTheme.zeroOpacity)
            self
        }
    }
}
