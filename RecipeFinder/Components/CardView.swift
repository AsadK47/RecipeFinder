import SwiftUI

struct CardView<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? AppTheme.cardBackgroundDark : AppTheme.cardBackground)
                        .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                } else {
                    ZStack {
                        // Base layer for better contrast - lighter in light mode, darker in dark mode
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.5))
                        
                        // Frosted glass layer on top
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    }
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.15), radius: 10, x: 0, y: 4)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? AppTheme.cardBackgroundDark : AppTheme.cardBackground)
                        .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                } else {
                    ZStack {
                        // Base layer for better contrast - lighter in light mode, darker in dark mode
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.5))
                        
                        // Frosted glass layer on top
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    }
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.15), radius: 10, x: 0, y: 4)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
