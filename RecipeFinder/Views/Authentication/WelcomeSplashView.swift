import SwiftUI
import ConfettiSwiftUI

private let logger = AppLogger.logger(category: "WelcomeSplash")


struct WelcomeSplashView: View {
    @Environment(\.appTheme) var appTheme
    @Environment(\.colorScheme) var colorScheme
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0
    @State private var checkmarkScale: CGFloat = 0
    @State private var contentOpacity: Double = 0
    @State private var confettiCounter: Int = 0
    @State private var ringScale: CGFloat = 0.8
    @State private var ringOpacity: Double = 0
    @State private var buttonScale: CGFloat = 0.9
    @State private var particlesOpacity: Double = 0
    let email: String
    let onContinue: () -> Void
    
    // Pre-computed particle positions for performance
    private let particlePositions: [(x: CGFloat, y: CGFloat, size: CGFloat)] = {
        (0..<20).map { _ in
            (
                x: CGFloat.random(in: 50...350),
                y: CGFloat.random(in: 100...700),
                size: CGFloat.random(in: 4...12)
            )
        }
    }()
    
    var body: some View {
        GeometryReader { geometry in
            let spacing = AdaptiveSpacing(geometry: geometry)
            
            ZStack {
                backgroundLayer
                particleLayer
                contentLayer(spacing: spacing)
            }
        }
        .onAppear(perform: startAnimations)
    }
    
    // MARK: - Background Layer
    private var backgroundLayer: some View {
        AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
            .ignoresSafeArea()
    }
    
    // MARK: - Particle Layer
    private var particleLayer: some View {
        ForEach(Array(particlePositions.enumerated()), id: \.offset) { index, particle in
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: particle.size, height: particle.size)
                .position(x: particle.x, y: particle.y)
                .opacity(particlesOpacity)
                .allowsHitTesting(false) // Particles should not block touches
                .animation(
                    .easeInOut(duration: Double.random(in: 2...4))
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.1),
                    value: particlesOpacity
                )
        }
    }
    
    // MARK: - Content Layer
    private func contentLayer(spacing: AdaptiveSpacing) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: spacing.xl + spacing.xxl)
                successIconSection(spacing: spacing)
                welcomeMessageSection(spacing: spacing)
                featureHighlightsSection(spacing: spacing)
                Spacer()
                    .frame(height: spacing.xl + spacing.xxl)
                continueButton(spacing: spacing)
            }
        }
        .scrollDisabled(true)
    }
    
    // MARK: - Success Icon Section
    private func successIconSection(spacing: AdaptiveSpacing) -> some View {
        ZStack {
            pulsingRings(spacing: spacing)
            gradientBackgroundCircle(spacing: spacing)
            mainSuccessCircle(spacing: spacing)
            checkmarkIcon
        }
        .frame(height: spacing.imageXLarge)
        .padding(.bottom, spacing.xl + spacing.xxl)
        .confettiCannon(trigger: $confettiCounter, num: 50, radius: 400)
    }
    
    private func pulsingRings(spacing: AdaptiveSpacing) -> some View {
        ForEach(0..<3) { index in
            Circle()
                .stroke(Color.white.opacity(0.2 - Double(index) * 0.05), lineWidth: 2)
                .frame(width: spacing.imageMedium + spacing.xxl + CGFloat(index * 30), height: spacing.imageMedium + spacing.xxl + CGFloat(index * 30))
                .scaleEffect(ringScale)
                .opacity(ringOpacity)
                .animation(
                    .easeOut(duration: 1.5)
                    .repeatForever(autoreverses: false)
                    .delay(Double(index) * 0.2),
                    value: ringScale
                )
        }
    }
    
    private func gradientBackgroundCircle(spacing: AdaptiveSpacing) -> some View {
        Circle()
            .fill(radialGradient)
            .frame(width: spacing.imageMedium + spacing.xxl, height: spacing.imageMedium + spacing.xxl)
            .scaleEffect(scale)
            .blur(radius: 1)
    }
    
    private var radialGradient: RadialGradient {
        RadialGradient(
            gradient: Gradient(colors: [
                AppTheme.accentColor(for: appTheme).opacity(0.3),
                AppTheme.accentColor(for: appTheme).opacity(0.1),
                Color.clear
            ]),
            center: .center,
            startRadius: 0,
            endRadius: 80
        )
    }
    
    private func mainSuccessCircle(spacing: AdaptiveSpacing) -> some View {
        Circle()
            .fill(successCircleGradient)
            .frame(width: spacing.imageMedium + spacing.xl, height: spacing.imageMedium + spacing.xl)
            .scaleEffect(scale)
            .shadow(color: AppTheme.accentColor(for: appTheme).opacity(0.5), radius: 20, x: 0, y: 10)
    }
    
    private var successCircleGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                AppTheme.accentColor(for: appTheme),
                AppTheme.accentColor(for: appTheme).opacity(0.8)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var checkmarkIcon: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 55, weight: .bold))
            .foregroundStyle(checkmarkGradient)
            .scaleEffect(checkmarkScale)
            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
    
    private var checkmarkGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [.white, .white.opacity(0.9)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Welcome Message Section
    private func welcomeMessageSection(spacing: AdaptiveSpacing) -> some View {
        VStack(spacing: spacing.xl) {
            titleText
            subtitleText
            successMessageCard(spacing: spacing)
        }
        .padding(.horizontal, spacing.xxl + spacing.lg)
        .padding(.bottom, spacing.xxl + spacing.xl)
    }
    
    private var titleText: some View {
        Text("Welcome to RecipeFinder")
            .font(.system(size: AppTheme.fontSize38, weight: .bold, design: .rounded))
            .foregroundStyle(titleGradient)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .opacity(contentOpacity)
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    private var titleGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                AppTheme.textColor(for: colorScheme),
                AppTheme.textColor(for: colorScheme, opacity: 0.95)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var subtitleText: some View {
        Text("Find, save, and share recipes you love")
            .font(.system(size: AppTheme.fontSize17, weight: .medium, design: .rounded))
            .foregroundColor(AppTheme.textColor(for: colorScheme))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .opacity(contentOpacity)
    }
    
    private func successMessageCard(spacing: AdaptiveSpacing) -> some View {
        VStack(spacing: spacing.md) {
            successMessageRow
            emailConfirmationRow
        }
        .padding(.horizontal, spacing.iconMedium)
        .padding(.vertical, spacing.xl)
        .background(cardBackground(spacing: spacing))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .opacity(contentOpacity)
    }
    
    private var successMessageRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(AppTheme.accentColor(for: appTheme))
            Text("Account created successfully")
                .font(.system(size: AppTheme.fontSize16, weight: .semibold))
                .adaptiveForegroundColor()
        }
    }
    
    private var emailConfirmationRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "at")
                .font(.system(size: AppTheme.fontSize14))
                .adaptiveForegroundColor(opacity: 0.6)
            Text(email)
                .font(.system(size: AppTheme.fontSize15, weight: .medium))
                .adaptiveForegroundColor(opacity: 0.8)
        }
    }
    
    private func cardBackground(spacing: AdaptiveSpacing) -> some View {
        RoundedRectangle(cornerRadius: spacing.lg)
            .fill(Color.white.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: spacing.lg)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
    
    // MARK: - Feature Highlights Section
    private func featureHighlightsSection(spacing: AdaptiveSpacing) -> some View {
        VStack(spacing: spacing.lg) {
            FeatureRow(icon: "fork.knife.circle.fill", text: "Explore thousands of recipes", spacing: spacing)
            FeatureRow(icon: "calendar.badge.plus", text: "Plan meals for the week", spacing: spacing)
            FeatureRow(icon: "cart.fill", text: "Create smart shopping lists", spacing: spacing)
        }
        .opacity(contentOpacity)
        .padding(.horizontal, spacing.xxl + spacing.lg)
    }
    
    // MARK: - Continue Button
    private func continueButton(spacing: AdaptiveSpacing) -> some View {
        Button(action: handleContinueAction) {
            buttonContent(spacing: spacing)
        }
        .buttonStyle(.plain)
        .scaleEffect(buttonScale)
        .padding(.horizontal, spacing.screenEdge + spacing.lg)
        .padding(.bottom, spacing.md)
        .opacity(contentOpacity)
        .allowsHitTesting(true)
    }
    
    private func buttonContent(spacing: AdaptiveSpacing) -> some View {
        HStack(spacing: spacing.md) {
            Text("Get Started")
                .font(.system(size: 18, weight: .semibold))
            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: AppTheme.fontSize20))
        }
        .adaptiveForegroundColor()
        .frame(maxWidth: .infinity)
        .frame(height: spacing.buttonHeight + spacing.md)
        .background(buttonBackground(spacing: spacing))
    }
    
    private func buttonBackground(spacing: AdaptiveSpacing) -> some View {
        RoundedRectangle(cornerRadius: spacing.lg)
            .fill(buttonGradient)
            .shadow(color: AppTheme.accentColor(for: appTheme).opacity(0.4), radius: 20, x: 0, y: 10)
    }
    
    private var buttonGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                AppTheme.accentColor(for: appTheme),
                AppTheme.accentColor(for: appTheme).opacity(0.8)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Actions
    private func handleContinueAction() {
        logger.debug("🔘 WelcomeSplash: Continue button tapped")
        HapticManager.shared.success()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            buttonScale = 0.95
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                buttonScale = 1.0
            }
            logger.debug("🔘 WelcomeSplash: Calling onContinue callback")
            onContinue()
        }
    }
    
    private func startAnimations() {
        // Orchestrated animation sequence
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            scale = 1.0
            ringOpacity = 0.5
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
            checkmarkScale = 1.0
            ringScale = 1.2
        }
        
        // Trigger confetti
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            confettiCounter += 1
            HapticManager.shared.success()
        }
        
        withAnimation(.easeOut(duration: 0.7).delay(0.4)) {
            contentOpacity = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            particlesOpacity = 1.0
        }
        
        // Continuous ring animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                ringScale = 1.5
                ringOpacity = 0
            }
        }
    }
}

// Helper view for feature rows
struct FeatureRow: View {
    let icon: String
    let text: String
    let spacing: AdaptiveSpacing
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: spacing.md) {
            Image(systemName: icon)
                .font(.system(size: AppTheme.fontSize16, weight: .semibold))
                .foregroundColor(AppTheme.textColor(for: colorScheme))
                .frame(width: spacing.iconMedium)
            
            Text(text)
                .font(.system(size: AppTheme.fontSize15, weight: .medium))
                .foregroundColor(AppTheme.textColor(for: colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    WelcomeSplashView(email: "user@example.com", onContinue: {})
        .environment(\.appTheme, .teal)
}
