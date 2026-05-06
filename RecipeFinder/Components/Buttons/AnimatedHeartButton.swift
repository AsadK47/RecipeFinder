import SwiftUI

private let logger = AppLogger.logger(category: "AnimatedHeartButton")

struct AnimatedHeartButton: View {
    @Binding var isFavorite: Bool
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @State private var isAnimating = false
    @State private var scale: CGFloat = Timing.scaleReset
    @State private var particlesVisible = false

    // MARK: - Constants

    enum Layout {
        static let particleCount: Int = 8
        static let particleSize: CGFloat = 4
        static let particleRadius: CGFloat = 25
        static let particleAngleStep: Double = .pi / 4
        static let particleScaleCollapsed: CGFloat = 0.5
        static let particleScaleExpanded: CGFloat = 1.5
        static let particleOpacityHidden: Double = 0
    }

    enum Timing {
        static let scaleUp: CGFloat = 1.4
        static let scaleReset: CGFloat = 1.0
        static let springResponseUp: Double = 0.3
        static let dampingUp: Double = 0.5
        static let springResponseReset: Double = 0.4
        static let dampingReset: Double = 0.7
        static let particleDuration: Double = 0.6
        static let particleDelay: Double = 0.1
        static let scaleResetDelay: Double = 0.2
        static let particleHideDelay: Double = 0.7
    }

    private let heartGradient = HeartPalette.gradient

    // MARK: - Body

    var body: some View {
        Button(action: handleTap) {
            ZStack {
                if particlesVisible && isFavorite {
                    ForEach(0..<Layout.particleCount, id: \.self) { index in
                        Circle()
                            .fill(particleColor(for: index))
                            .frame(width: Layout.particleSize, height: Layout.particleSize)
                            .offset(particleOffset(for: index))
                            .opacity(particlesVisible ? Layout.particleOpacityHidden : 1)
                            .scaleEffect(particlesVisible ? Layout.particleScaleCollapsed : Layout.particleScaleExpanded)
                    }
                }

                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundStyle(
                        isFavorite
                            ? heartGradient
                            : LinearGradient(
                                gradient: Gradient(colors: [AppTheme.textColor(for: colorScheme)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                    )
                    .scaleEffect(scale)
                    .animation(.spring(response: Timing.springResponseUp, dampingFraction: Timing.dampingUp), value: scale)
            }
        }
        .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
        .accessibilityHint(isFavorite ? "Double tap to unfavorite" : "Double tap to mark as favorite")
        .accessibilityAddTraits(.isButton)
        .onChange(of: isFavorite) { _, newValue in
            if newValue { animateHeart() }
        }
    }

    // MARK: - Actions

    private func handleTap() {
        HapticManager.shared.light()
        action()
    }

    private func animateHeart() {
        withAnimation(.spring(response: Timing.springResponseUp, dampingFraction: Timing.dampingUp)) {
            scale = Timing.scaleUp
        }

        withAnimation(.easeOut(duration: Timing.particleDuration).delay(Timing.particleDelay)) {
            particlesVisible = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Timing.scaleResetDelay) {
            withAnimation(.spring(response: Timing.springResponseReset, dampingFraction: Timing.dampingReset)) {
                scale = Timing.scaleReset
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Timing.particleHideDelay) {
            particlesVisible = false
        }
    }

    // MARK: - Helpers (internal for testability)

    func particleColor(for index: Int) -> Color {
        HeartPalette.particleColors[index % HeartPalette.particleColors.count]
    }

    func particleOffset(for index: Int) -> CGSize {
        let angle = Double(index) * Layout.particleAngleStep
        return CGSize(
            width: Foundation.cos(angle) * Layout.particleRadius,
            height: Foundation.sin(angle) * Layout.particleRadius
        )
    }
}

#Preview {
    ZStack {
        AppTheme.backgroundGradient(for: AppTheme.ThemeType.teal, colorScheme: .dark)
            .ignoresSafeArea()

        VStack(spacing: AppTheme.spacing48) {
            Text("Tap the heart!")
                .adaptiveForegroundColor()
                .font(.title2)

            AnimatedHeartButton(isFavorite: .constant(false)) {
                logger.debug("Heart tapped!")
            }

            AnimatedHeartButton(isFavorite: .constant(true)) {
                logger.debug("Already favorited!")
            }
        }
    }
}
