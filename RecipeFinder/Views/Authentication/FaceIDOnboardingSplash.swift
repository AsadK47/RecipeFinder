import SwiftUI
import LocalAuthentication

struct FaceIDOnboardingSplash: View {
    @Environment(\.auth) private var authManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appTheme") var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("biometricsEnabled") private var biometricsEnabled: Bool = false
    @AppStorage("hasSeenBiometricOnboarding") private var hasSeenBiometricOnboarding: Bool = false
    @Environment(\.colorScheme) var colorScheme

    @State var isEnabling = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State var iconScale: CGFloat = 0.8
    @State var iconRotation: Double = 0
    @State var contentOpacity: Double = 0
    @State var shimmerOffset: CGFloat = -200
    @State var particlesOpacity: Double = 0
    @State var glowIntensity: Double = 0.3

    let onComplete: () -> Void

    let particleData: [(icon: String, size: CGFloat, x: CGFloat, y: CGFloat)] = {
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

    var biometricIcon: String {
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

    var biometricName: String {
        let type = authManager.biometricType
        return type == "None" ? "Biometrics" : type
    }

    var body: some View {
        GeometryReader { geometry in
            let spacing = AdaptiveSpacing(geometry: geometry)

            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()

                particleLayer()

                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: spacing.heightPercent(0.08, min: 40))

                    animatedBiometricIcon(spacing: spacing)

                    infoSection(spacing: spacing)

                    Spacer()
                        .frame(height: spacing.heightPercent(0.05, min: 25))

                    actionButtons(spacing: spacing, geometry: geometry)
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

    func enableBiometrics() {
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

    func skipSetup() {
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

#Preview {
    FaceIDOnboardingSplash(onComplete: {})
}
