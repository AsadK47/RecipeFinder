import SwiftUI
import ConfettiSwiftUI

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
            ZStack {
                backgroundLayer
                particleLayer
                contentLayer
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
    private var contentLayer: some View {
        VStack(spacing: 0) {
            Spacer()
            successIconSection
            welcomeMessageSection
            featureHighlightsSection
            Spacer()
            continueButton
        }
    }
    
    // MARK: - Success Icon Section
    private var successIconSection: some View {
        ZStack {
            pulsingRings
            gradientBackgroundCircle
            mainSuccessCircle
            checkmarkIcon
        }
        .frame(height: 200)
        .padding(.bottom, 50)
        .confettiCannon(trigger: $confettiCounter, num: 50, radius: 400)
    }
    
    private var pulsingRings: some View {
        ForEach(0..<3) { index in
            Circle()
                .stroke(Color.white.opacity(0.2 - Double(index) * 0.05), lineWidth: 2)
                .frame(width: 140 + CGFloat(index * 30), height: 140 + CGFloat(index * 30))
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
    
    private var gradientBackgroundCircle: some View {
        Circle()
            .fill(radialGradient)
            .frame(width: 140, height: 140)
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
    
    private var mainSuccessCircle: some View {
        Circle()
            .fill(successCircleGradient)
            .frame(width: 120, height: 120)
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
    private var welcomeMessageSection: some View {
        VStack(spacing: 20) {
            titleText
            subtitleText
            successMessageCard
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 40)
    }
    
    private var titleText: some View {
        Text("Welcome Aboard!")
            .font(.system(size: 40, weight: .bold, design: .rounded))
            .foregroundStyle(titleGradient)
            .multilineTextAlignment(.center)
            .opacity(contentOpacity)
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    private var titleGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [.white, .white.opacity(0.95)]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var subtitleText: some View {
        Text("Your culinary journey begins now")
            .font(.system(size: 20, weight: .medium, design: .rounded))
            .foregroundColor(.white.opacity(0.9))
            .multilineTextAlignment(.center)
            .opacity(contentOpacity)
    }
    
    private var successMessageCard: some View {
        VStack(spacing: 12) {
            successMessageRow
            emailConfirmationRow
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(cardBackground)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .opacity(contentOpacity)
    }
    
    private var successMessageRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(AppTheme.accentColor(for: appTheme))
            Text("Account created successfully")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
    }
    
    private var emailConfirmationRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "envelope.fill")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
            Text(email)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
    
    // MARK: - Feature Highlights Section
    private var featureHighlightsSection: some View {
        VStack(spacing: 16) {
            FeatureRow(icon: "fork.knife.circle.fill", text: "Discover amazing recipes")
            FeatureRow(icon: "calendar.badge.plus", text: "Plan your weekly meals")
            FeatureRow(icon: "cart.fill", text: "Smart shopping lists")
        }
        .opacity(contentOpacity)
        .padding(.horizontal, 40)
    }
    
    // MARK: - Continue Button
    private var continueButton: some View {
        Button(action: handleContinueAction) {
            buttonContent
        }
        .buttonStyle(.plain) // Ensure button responds to taps
        .scaleEffect(buttonScale)
        .padding(.horizontal, 32)
        .padding(.bottom, 50)
        .opacity(contentOpacity)
        .allowsHitTesting(true) // Explicitly allow hit testing
    }
    
    private var buttonContent: some View {
        HStack(spacing: 12) {
            Text("Continue to Sign In")
                .font(.system(size: 18, weight: .semibold))
            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 20))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 58)
        .background(buttonBackground)
    }
    
    private var buttonBackground: some View {
        RoundedRectangle(cornerRadius: 16)
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
        debugLog("🔘 WelcomeSplash: Continue button tapped")
        HapticManager.shared.success()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            buttonScale = 0.95
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                buttonScale = 1.0
            }
            debugLog("🔘 WelcomeSplash: Calling onContinue callback")
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
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    WelcomeSplashView(email: "user@example.com", onContinue: {})
        .environment(\.appTheme, .teal)
}
