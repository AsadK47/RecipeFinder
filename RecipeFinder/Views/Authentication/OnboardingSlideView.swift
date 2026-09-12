import SwiftUI

/// One onboarding slide: icon, title, short description, and a single action
/// button. Designed to fit on any screen without scrolling.
struct OnboardingSlideView: View {
    let slide: OnboardingSlide
    let isLastSlide: Bool
    let onNext: () -> Void

    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAnimating = false
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            iconView
                .padding(.bottom, 48)

            VStack(spacing: 16) {
                Text(slide.title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .adaptiveForegroundColor()

                Text(slide.description)
                    .font(.system(size: 17, weight: .regular))
                    .multilineTextAlignment(.center)
                    .adaptiveForegroundColor(opacity: 0.75)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }

            Spacer()

            actionButton
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.96)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAnimating = true
            }
        }
        .onDisappear {
            appeared = false
            isAnimating = false
        }
    }

    private var iconView: some View {
        ZStack {
            ForEach(0..<3) { index in
                Circle()
                    .stroke(
                        slide.accentColor.opacity(0.25 - Double(index) * 0.07),
                        lineWidth: 1.5
                    )
                    .frame(
                        width: 120 + CGFloat(index * 36),
                        height: 120 + CGFloat(index * 36)
                    )
                    .scaleEffect(isAnimating ? 1.08 : 1.0)
                    .opacity(isAnimating ? 0 : 1)
                    .animation(
                        .easeOut(duration: 2.0)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.5),
                        value: isAnimating
                    )
            }

            Circle()
                .fill(slide.accentColor.opacity(0.12))
                .frame(width: 120, height: 120)

            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 104, height: 104)
                .overlay(
                    Circle().stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.12), radius: 20, y: 8)

            Image(systemName: slide.icon)
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [slide.accentColor, slide.accentColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(isAnimating ? 1.06 : 0.94)
                .animation(
                    .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                    value: isAnimating
                )
        }
    }

    private var actionButton: some View {
        Button(action: {
            HapticManager.shared.light()
            onNext()
        }) {
            Text(isLastSlide ? "Get Started" : "Next")
                .font(.system(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(slide.accentColor)
                        .shadow(color: slide.accentColor.opacity(0.4), radius: 12, y: 6)
                )
                .foregroundColor(.white)
        }
    }
}
