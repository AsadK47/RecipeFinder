import SwiftUI
import LocalAuthentication

struct FaceIDOnboardingSplash: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("biometricsEnabled") private var biometricsEnabled: Bool = false
    @AppStorage("hasSeenBiometricOnboarding") private var hasSeenBiometricOnboarding: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isEnabling = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var iconScale: CGFloat = 0.8
    @State private var iconRotation: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var shimmerOffset: CGFloat = -200
    @State private var particlesOpacity: Double = 0
    @State private var glowIntensity: Double = 0.3
    
    let onComplete: () -> Void
    
    private let particleData: [(icon: String, size: CGFloat, x: CGFloat, y: CGFloat)] = {
        let icons = ["lock.fill", "key.fill", "shield.fill", "faceid", "touchid"]
        return (0..<20).map { _ in
            (
                icon: icons.randomElement() ?? "lock.fill",
                size: CGFloat.random(in: 8...20),
                x: CGFloat.random(in: 50...350),
                y: CGFloat.random(in: 100...700)
            )
        }
    }()
    
    private var biometricIcon: String {
        switch authManager.biometricType {
        case "Face ID":
            return "faceid"
        case "Touch ID":
            return "touchid"
        case "Optic ID":
            return "opticid"
        default:
            return "lock.shield.fill"
        }
    }
    
    private var biometricName: String {
        let type = authManager.biometricType
        return type == "None" ? "Biometrics" : type
    }
    
    var body: some View {
        GeometryReader { geometry in
            let spacing = AdaptiveSpacing(geometry: geometry)
            
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ForEach(Array(particleData.enumerated()), id: \.offset) { index, particle in
                    Image(systemName: particle.icon)
                        .font(.system(size: particle.size))
                        .adaptiveForegroundColor(opacity: AppTheme.tinyOpacity)
                        .position(x: particle.x, y: particle.y)
                        .opacity(particlesOpacity)
                        .animation(
                            .easeInOut(duration: Double.random(in: 3...6))
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: particlesOpacity
                        )
                }
                
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: spacing.heightPercent(0.08, min: 40))
                    
                    ZStack {
                        ForEach(0..<3) { index in
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            AppTheme.accentColor(for: selectedTheme).opacity(0.5 - Double(index) * 0.15),
                                            AppTheme.accentColor(for: selectedTheme).opacity(0.0)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 3
                                )
                                .frame(width: spacing.imageLarge + CGFloat(index * 40), height: spacing.imageLarge + CGFloat(index * 40))
                                .scaleEffect(iconScale + CGFloat(index) * 0.15)
                                .opacity(1.0 - Double(index) * 0.3)
                                .animation(
                                    .easeInOut(duration: AppTheme.animationDuration25)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.4),
                                    value: iconScale
                                )
                        }
                        
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        AppTheme.accentColor(for: selectedTheme).opacity(glowIntensity),
                                        AppTheme.accentColor(for: selectedTheme).opacity(glowIntensity * 0.6),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 120
                                )
                            )
                            .frame(width: spacing.imageHero, height: spacing.imageHero)
                            .blur(radius: AppTheme.blurRadiusHeavy)
                            .animation(
                                .easeInOut(duration: AppTheme.animationDelayFeedback)
                                .repeatForever(autoreverses: true),
                                value: glowIntensity
                            )
                        
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        AppTheme.accentColor(for: selectedTheme).opacity(0.4),
                                        AppTheme.accentColor(for: selectedTheme).opacity(0.25)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: spacing.imageLarge, height: spacing.imageLarge)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(AppTheme.glassLightOpacity),
                                                Color.white.opacity(AppTheme.softOverlayOpacity)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2.5
                                    )
                            )
                            .shadow(color: AppTheme.accentColor(for: selectedTheme).opacity(0.4), radius: 25, x: 0, y: 12)
                        
                        Image(systemName: biometricIcon)
                            .font(.system(size: AppTheme.fontSize75, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        AppTheme.accentColor(for: selectedTheme),
                                        AppTheme.accentColor(for: selectedTheme).opacity(0.85)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .black.opacity(AppTheme.softOverlayOpacity), radius: 8, x: 0, y: 3)
                            .scaleEffect(iconScale)
                            .rotationEffect(.degrees(iconRotation))
                    }
                    .frame(height: spacing.imageHero)
                    .padding(.bottom, spacing.xl + spacing.xxl + spacing.lg)
                    .opacity(contentOpacity)
                    
                    VStack(spacing: spacing.xxl) {
                        VStack(spacing: spacing.md) {
                            Text("Set Up \(biometricName)")
                                .font(.system(size: AppTheme.fontSize38, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            AppTheme.textColor(for: colorScheme),
                                            AppTheme.textColor(for: colorScheme, opacity: 0.95)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .multilineTextAlignment(.center)
                            
                            Text("Secure access in seconds")
                                .font(.system(size: AppTheme.fontSize20, weight: .medium, design: .rounded))
                                .foregroundColor(AppTheme.textColor(for: colorScheme))
                                .multilineTextAlignment(.center)
                        }
                        
                        VStack(spacing: spacing.lg) {
                            Text("Intuitive and secure authentication")
                                .font(.system(size: AppTheme.fontSize17, weight: .medium))
                                .foregroundColor(AppTheme.textColor(for: colorScheme))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, spacing.xl)
                            
                            VStack(spacing: spacing.md) {
                                BiometricBenefitRow(
                                    icon: "bolt.fill",
                                    title: "Simple Glance",
                                    description: "Securely unlock with just a look",
                                    spacing: spacing
                                )
                            }
                            .padding(.top, spacing.sm)
                        }
                    }
                    .padding(.horizontal, spacing.screenEdge + spacing.xl)
                    .opacity(contentOpacity)
                    
                    Spacer()
                        .frame(height: spacing.heightPercent(0.05, min: 25))
                    
                    VStack(spacing: spacing.md + 2) {
                        Button(action: enableBiometrics) {
                            HStack(spacing: spacing.md) {
                                if isEnabling {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: biometricIcon)
                                        .font(.system(size: AppTheme.fontSize22, weight: .semibold))
                                    Text("Enable \(biometricName)")
                                        .font(.system(size: AppTheme.fontSize20, weight: .bold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: spacing.buttonHeightLarge)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius18)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    AppTheme.accentColor(for: selectedTheme),
                                                    AppTheme.accentColor(for: selectedTheme).opacity(0.85)
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                    
                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius18)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.clear,
                                                    Color.white.opacity(AppTheme.mediumOverlayOpacity),
                                                    Color.clear
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .offset(x: shimmerOffset)
                                }
                            )
                            .shadow(color: AppTheme.accentColor(for: selectedTheme).opacity(0.6), radius: 25, x: 0, y: 12)
                        }
                        .disabled(isEnabling)
                        .opacity(isEnabling ? 0.7 : 1.0)
                        
                        Button(action: skipSetup) {
                            Text("Set Up Later")
                                .font(.system(size: AppTheme.fontSize17, weight: .semibold))
                                .foregroundColor(AppTheme.textColor(for: colorScheme))
                                .frame(maxWidth: .infinity)
                                .frame(height: spacing.buttonHeight)
                                .background(
                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius18)
                                        .fill(Color.white.opacity(AppTheme.dimGlassOpacity))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius18)
                                                .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                                        )
                                )
                        }
                    }
                    .padding(.horizontal, spacing.screenEdge + spacing.lg)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? spacing.xxl + spacing.lg : spacing.xl + spacing.xxl)
                    .opacity(contentOpacity)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                iconScale = 1.0
                contentOpacity = 1.0
            }
            
            withAnimation(.easeInOut(duration: AppTheme.animationDuration08).delay(AppTheme.animationDelayXShort)) {
                particlesOpacity = 1.0
            }
            
            withAnimation(.easeInOut(duration: AppTheme.animationDelayFeedback).repeatForever(autoreverses: true)) {
                glowIntensity = 0.6
            }
            
            withAnimation(.linear(duration: AppTheme.animationDuration25).repeatForever(autoreverses: false)) {
                shimmerOffset = 400
            }
        }
    }
    
    private func enableBiometrics() {
        isEnabling = true
        HapticManager.shared.light()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            iconScale = 1.15
            iconRotation = 360
        }
        
        Task {
            do {
                try await authManager.authenticateWithBiometrics()
                
                DispatchQueue.main.async {
                    biometricsEnabled = true
                    hasSeenBiometricOnboarding = true
                    HapticManager.shared.success()
                    
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        iconScale = 1.25
                        glowIntensity = 1.0
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.animationDelayShort) {
                        withAnimation(.easeOut(duration: AppTheme.animationDelayXShort)) {
                            contentOpacity = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.animationDelayXShort) {
                            onComplete()
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    isEnabling = false
                    errorMessage = error.localizedDescription
                    showError = true
                    HapticManager.shared.error()
                    
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        iconScale = 1.0
                        iconRotation = 0
                    }
                }
            }
        }
    }
    
    private func skipSetup() {
        HapticManager.shared.light()
        hasSeenBiometricOnboarding = true
        
        withAnimation(.easeOut(duration: AppTheme.animationDelayXShort)) {
            contentOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.animationDelayXShort) {
            onComplete()
        }
    }
}

private struct BiometricBenefitRow: View {
    let icon: String
    let title: String
    let description: String
    let spacing: AdaptiveSpacing
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: spacing.lg) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(AppTheme.softOverlayOpacity),
                                Color.white.opacity(AppTheme.cardDarkOpacity)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: spacing.touchTarget, height: spacing.touchTarget)
                
                Image(systemName: icon)
                    .font(.system(size: AppTheme.fontSize18, weight: .semibold))
                    .foregroundColor(AppTheme.textColor(for: colorScheme))
            }
            
            VStack(alignment: .leading, spacing: spacing.xxs) {
                Text(title)
                    .font(.system(size: AppTheme.fontSize16, weight: .semibold))
                    .foregroundColor(AppTheme.textColor(for: colorScheme))
                
                Text(description)
                    .font(.system(size: AppTheme.fontSize14, weight: .medium))
                    .foregroundColor(AppTheme.textColor(for: colorScheme, opacity: 0.85))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, spacing.xxs)
    }
}

#Preview {
    FaceIDOnboardingSplash(onComplete: {})
}
