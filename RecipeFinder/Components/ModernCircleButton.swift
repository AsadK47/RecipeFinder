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
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .padding(12)
                .background {
                    if cardStyle == .solid {
                        Circle()
                            .fill(colorScheme == .dark ? Color(white: 0.2) : Color.white.opacity(0.9))
                    } else {
                        Circle()
                            .fill(.regularMaterial)
                    }
                }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ZStack {
        Color.blue
        HStack {
            ModernCircleButton(icon: "plus.circle.fill") {
                print("Tapped")
            }
            
            ModernCircleButton(icon: "ellipsis.circle.fill") {
                print("Tapped")
            }
        }
    }
}
