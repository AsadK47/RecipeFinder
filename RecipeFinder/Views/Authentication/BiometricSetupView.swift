import SwiftUI
import LocalAuthentication

struct BiometricSetupView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("biometricsEnabled") private var biometricsEnabled: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isEnabling = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var iconScale: CGFloat = 0.8
    @State private var iconRotation: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var shimmerOffset: CGFloat = -200
    @State private var particlesOpacity: Double = 0
    
    private let particleData: [(icon: String, size: CGFloat, x: CGFloat, y: CGFloat)] = {
        (0..<15).map { _ in
            (
                icon: ["lock.fill", "key.fill", "shield.fill"].randomElement()!,
                size: CGFloat.random(in: 8...16),
                x: CGFloat.random(in: 50...350),
                y: CGFloat.random(in: 100...700)
            )
        }
    }()
    
    private var biometricIcon: String {
        switch authManager.biometricType {
        case "Face ID": return "faceid"
        case "Touch ID": return "touchid"
        default: return "lock.shield.fill"
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let spacing = AdaptiveSpacing(geometry: geometry)
            
            ZStack {
                backgroundView
                particlesView
                contentView(spacing: spacing)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear(perform: setupAnimations)
    }
    
    private var backgroundView: some View {
        AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
            .ignoresSafeArea()
    }
    
    private var particlesView: some View {
        ForEach(Array(particleData.enumerated()), id: \.offset) { index, particle in
            ParticleView(
                particle: particle,
                index: index,
                opacity: particlesOpacity
            )
        }
    }
    
    private func contentView(spacing: AdaptiveSpacing) -> some View {
        VStack(spacing: 0) {
            Spacer()
            
            BiometricIconView(
                icon: biometricIcon,
                selectedTheme: selectedTheme,
                spacing: spacing,
                iconScale: iconScale,
                iconRotation: iconRotation
            )
            .opacity(contentOpacity)
            
            titleAndBenefits(spacing: spacing)
            
            Spacer()
            
            actionButtons(spacing: spacing)
        }
    }
    
    private func titleAndBenefits(spacing: AdaptiveSpacing) -> some View {
        VStack(spacing: spacing.md + spacing.md) {
            Text("Secure Your Account")
                .font(.system(size: AppTheme.fontSize38 - 2, weight: .bold, design: .rounded))
                .adaptiveForegroundColor()
                .multilineTextAlignment(.center)
                .shadow(color: colorScheme == .dark ? .black.opacity(0.2) : .clear, radius: spacing.xs, x: 0, y: 5)
            
            VStack(spacing: spacing.lg) {
                Text("Enable \(authManager.biometricType) for quick and secure access")
                    .font(.system(size: AppTheme.fontSize16 + 2, weight: .medium))
                    .adaptiveForegroundColor(opacity: 0.9)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                VStack(spacing: spacing.md) {
                    BenefitRow(icon: "bolt.fill", text: "Sign in instantly", spacing: spacing)
                    BenefitRow(icon: "lock.shield.fill", text: "Enhanced security", spacing: spacing)
                    BenefitRow(icon: "hand.raised.fill", text: "No passwords needed", spacing: spacing)
                }
                .padding(.top, spacing.sm)
            }
        }
        .padding(.horizontal, spacing.screenEdge + spacing.xl)
        .opacity(contentOpacity)
    }
    
    private func actionButtons(spacing: AdaptiveSpacing) -> some View {
        VStack(spacing: spacing.lg) {
            EnableButton(
                biometricType: authManager.biometricType,
                biometricIcon: biometricIcon,
                selectedTheme: selectedTheme,
                spacing: spacing,
                isEnabling: isEnabling,
                shimmerOffset: shimmerOffset,
                action: enableBiometrics
            )
            
            Button(action: skipSetup) {
                Text("Maybe Later")
                    .font(.system(size: AppTheme.fontSize16, weight: .semibold))
                    .adaptiveForegroundColor(opacity: 0.85)
                    .frame(maxWidth: .infinity)
                    .frame(height: spacing.buttonHeight)
                    .background(
                        RoundedRectangle(cornerRadius: spacing.lg)
                            .fill(Color.white.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: spacing.lg)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
            }
        }
        .padding(.horizontal, spacing.screenEdge + spacing.lg)
        .padding(.bottom, spacing.xxl + spacing.xxl + spacing.xs)
        .opacity(contentOpacity)
    }
    
    private func setupAnimations() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            iconScale = 1.0
            contentOpacity = 1.0
        }
        
        withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
            particlesOpacity = 1.0
        }
        
        withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
            shimmerOffset = 400
        }
    }
    
    private func enableBiometrics() {
        isEnabling = true
        HapticManager.shared.light()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            iconScale = 1.1
            iconRotation = 360
        }
        
        Task {
            do {
                try await authManager.authenticateWithBiometrics()
                
                DispatchQueue.main.async {
                    biometricsEnabled = true
                    HapticManager.shared.success()
                    
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        iconScale = 1.2
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        dismiss()
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
        withAnimation(.easeOut(duration: 0.3)) {
            contentOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            dismiss()
        }
    }
}

private struct ParticleView: View {
    let particle: (icon: String, size: CGFloat, x: CGFloat, y: CGFloat)
    let index: Int
    let opacity: Double
    
    private var animationDuration: Double {
        3.0 + Double(index % 3)
    }
    
    private var animationDelay: Double {
        Double(index) * 0.2
    }
    
    var body: some View {
        Image(systemName: particle.icon)
            .font(.system(size: particle.size))
            .adaptiveForegroundColor(opacity: 0.08)
            .position(x: particle.x, y: particle.y)
            .opacity(opacity)
            .animation(
                .easeInOut(duration: animationDuration)
                .repeatForever(autoreverses: true)
                .delay(animationDelay),
                value: opacity
            )
    }
}

private struct BiometricIconView: View {
    let icon: String
    let selectedTheme: AppTheme.ThemeType
    let spacing: AdaptiveSpacing
    let iconScale: CGFloat
    let iconRotation: Double
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var accentColor: Color {
        AppTheme.accentColor(for: selectedTheme)
    }
    
    var body: some View {
        ZStack {
            pulsingRings
            backgroundGlow
            mainCircle
            iconImage
        }
        .frame(height: spacing.imageXLarge)
        .padding(.bottom, spacing.xxl + spacing.xxl + spacing.xs)
    }
    
    private var pulsingRings: some View {
        ForEach(0..<3) { index in
            PulsingRing(
                accentColor: accentColor,
                spacing: spacing,
                index: index,
                iconScale: iconScale
            )
        }
    }
    
    private var backgroundGlow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        accentColor.opacity(0.4),
                        accentColor.opacity(0.2),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 100
                )
            )
            .frame(width: spacing.imageXLarge, height: spacing.imageXLarge)
            .blur(radius: spacing.xl)
    }
    
    private var mainCircle: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        accentColor.opacity(0.3),
                        accentColor.opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: spacing.imageLarge, height: spacing.imageLarge)
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                AppTheme.textColor(for: colorScheme, opacity: 0.4),
                                AppTheme.textColor(for: colorScheme, opacity: 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: accentColor.opacity(0.3), radius: spacing.xl, x: 0, y: spacing.xs)
    }
    
    private var iconImage: some View {
        Image(systemName: icon)
            .font(.system(size: AppTheme.fontSize60, weight: .medium))
            .foregroundStyle(
                LinearGradient(
                    colors: [accentColor, accentColor.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
            .scaleEffect(iconScale)
            .rotationEffect(.degrees(iconRotation))
    }
}

private struct PulsingRing: View {
    let accentColor: Color
    let spacing: AdaptiveSpacing
    let index: Int
    let iconScale: CGFloat
    
    private var ringSize: CGFloat {
        spacing.imageLarge + CGFloat(index * 30)
    }
    
    private var ringOpacity: Double {
        1.0 - Double(index) * 0.3
    }
    
    private var ringScale: CGFloat {
        iconScale + CGFloat(index) * 0.1
    }
    
    private var ringDelay: Double {
        Double(index) * 0.3
    }
    
    var body: some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [
                        accentColor.opacity(0.4),
                        accentColor.opacity(0.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 2
            )
            .frame(width: ringSize, height: ringSize)
            .scaleEffect(ringScale)
            .opacity(ringOpacity)
            .animation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
                .delay(ringDelay),
                value: iconScale
            )
    }
}

private struct EnableButton: View {
    let biometricType: String
    let biometricIcon: String
    let selectedTheme: AppTheme.ThemeType
    let spacing: AdaptiveSpacing
    let isEnabling: Bool
    let shimmerOffset: CGFloat
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    private var accentColor: Color {
        AppTheme.accentColor(for: selectedTheme)
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: spacing.md) {
                if isEnabling {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.textColor(for: colorScheme)))
                } else {
                    Image(systemName: biometricIcon)
                        .font(.system(size: AppTheme.fontSize20, weight: .semibold))
                    Text("Enable \(biometricType)")
                        .font(.system(size: AppTheme.fontSize16 + 2, weight: .bold))
                }
            }
            .adaptiveForegroundColor()
            .frame(maxWidth: .infinity)
            .frame(height: spacing.buttonHeightLarge)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: spacing.lg)
                        .fill(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    RoundedRectangle(cornerRadius: spacing.lg)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: shimmerOffset)
                }
            )
            .shadow(color: accentColor.opacity(0.5), radius: spacing.xl, x: 0, y: spacing.xs)
        }
        .disabled(isEnabling)
        .opacity(isEnabling ? 0.7 : 1.0)
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    let spacing: AdaptiveSpacing
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: spacing.md) {
            Image(systemName: icon)
                .font(.system(size: AppTheme.fontSize16, weight: .semibold))
                .adaptiveForegroundColor(opacity: 0.9)
                .frame(width: spacing.md + spacing.md)
            
            Text(text)
                .font(.system(size: AppTheme.fontSize15, weight: .medium))
                .adaptiveForegroundColor(opacity: 0.85)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    BiometricSetupView()
}
