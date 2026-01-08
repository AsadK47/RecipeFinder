import SwiftUI

/// Modern circular button that adapts to color scheme
/// Uses material background in dark mode, solid white in light mode
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
                .padding(12)
                .background {
                    if cardStyle == .solid {
                        Circle()
                            .fill(colorScheme == .dark ? Color(white: AppTheme.cardDarkMediumOpacity) : Color.white.opacity(AppTheme.cardLightOpacity))
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
