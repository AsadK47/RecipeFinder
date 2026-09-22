import SwiftUI
import LocalAuthentication

struct BiometricSetupView: View {
    @Environment(\.auth) private var authManager
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
                .font(.system(size: AppTheme.fontSize36, weight: .bold, design: .rounded))
                .adaptiveForegroundColor()
                .multilineTextAlignment(.center)
                .shadow(color: colorScheme == .dark ? .black.opacity(AppTheme.overlayLightOpacity) : .clear, radius: spacing.xs, x: 0, y: 5)

            VStack(spacing: spacing.lg) {
                Text("Enable \(authManager.biometricType) for quick and secure access")
                    .font(.system(size: AppTheme.fontSize18, weight: .medium))
                    .adaptiveForegroundColor(opacity: AppTheme.veryHighEmphasisOpacity)
                    .multilineTextAlignment(.center)
                    .lineSpacing(AppTheme.lineSpacingNormal)

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
                    .adaptiveForegroundColor(opacity: AppTheme.nearSolidOpacity)
                    .frame(maxWidth: .infinity)
                    .frame(height: spacing.buttonHeight)
                    .background(
                        RoundedRectangle(cornerRadius: spacing.lg)
                            .fill(Color.white.opacity(AppTheme.cardDarkOpacity))
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

        withAnimation(.easeInOut(duration: AppTheme.animationDuration08).delay(AppTheme.animationDelayXShort)) {
            particlesOpacity = 1.0
        }

        withAnimation(.linear(duration: AppTheme.animationDuration25).repeatForever(autoreverses: false)) {
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

                    DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.animationDelayXShort) {
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
        withAnimation(.easeOut(duration: AppTheme.animationDelayXShort)) {
            contentOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            dismiss()
        }
    }
}

#Preview {
    BiometricSetupView()
}
