import SwiftUI

struct ModernCircleButton: View {
    let icon: String
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AppTheme.adaptiveEmphasis(for: colorScheme))
                .padding(AppTheme.spacing12)
                .background {
                    if cardStyle == .solid {
                        Circle()
                            .fill(AppTheme.adaptiveCardMedium(for: colorScheme))
                    } else {
                        Circle()
                            .fill(.ultraThinMaterial)
                    }
                }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    ZStack {
        Color.blue
        HStack {
            ModernCircleButton(icon: "plus.circle.fill") {}
            ModernCircleButton(icon: "ellipsis.circle.fill") {}
        }
    }
}
