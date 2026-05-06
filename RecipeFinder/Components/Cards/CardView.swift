import SwiftUI

enum CardViewLayout {
    static let cornerRadius: CGFloat = 16
    static let shadowRadius: CGFloat = 8
    static let shadowRadiusFrosted: CGFloat = 10
    static let shadowY: CGFloat = 4
    static let shadowOpacitySolid: Double = 0.25
    static let shadowOpacityFrostedDark: Double = 0.3
    static let shadowOpacityFrostedLight: Double = 0.15
}

struct CardView<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background { cardBackground }
            .clipShape(RoundedRectangle(cornerRadius: CardViewLayout.cornerRadius))
    }

    @ViewBuilder
    private var cardBackground: some View {
        if cardStyle == .solid {
            RoundedRectangle(cornerRadius: CardViewLayout.cornerRadius)
                .fill(AppTheme.cardBackground(for: colorScheme))
                .shadow(
                    color: Color.black.opacity(CardViewLayout.shadowOpacitySolid),
                    radius: CardViewLayout.shadowRadius,
                    x: 0,
                    y: CardViewLayout.shadowY
                )
        } else {
            RoundedRectangle(cornerRadius: CardViewLayout.cornerRadius)
                .fill(.ultraThinMaterial)
                .shadow(
                    color: Color.black.opacity(frostedShadowOpacity(for: colorScheme)),
                    radius: CardViewLayout.shadowRadiusFrosted,
                    x: 0,
                    y: CardViewLayout.shadowY
                )
        }
    }

    func frostedShadowOpacity(for colorScheme: ColorScheme) -> Double {
        colorScheme == .dark ? CardViewLayout.shadowOpacityFrostedDark : CardViewLayout.shadowOpacityFrostedLight
    }
}

// GlassCard is an alias — identical behaviour, kept for call-site compatibility
typealias GlassCard = CardView
