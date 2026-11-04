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

    // Trait-resolved colours rather than @Environment(\.colorScheme), which warns when evaluated outside a hosted view.
    @ViewBuilder
    private var cardBackground: some View {
        if cardStyle == .solid {
            RoundedRectangle(cornerRadius: CardViewLayout.cornerRadius)
                .fill(AppTheme.adaptive(
                    light: AppTheme.cardBackground(for: .light),
                    dark: AppTheme.cardBackground(for: .dark)
                ))
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
                    color: AppTheme.adaptive(
                        light: Color.black.opacity(frostedShadowOpacity(for: .light)),
                        dark: Color.black.opacity(frostedShadowOpacity(for: .dark))
                    ),
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

// Alias kept for call-site compatibility — identical behaviour.
typealias GlassCard = CardView
