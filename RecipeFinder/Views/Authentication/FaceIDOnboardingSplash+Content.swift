import SwiftUI

/// View-building pieces of `FaceIDOnboardingSplash`, split out to keep the main
/// file focused on state and behavior. Reads the owning view's `@State`/helpers,
/// which are therefore internal rather than private.
extension FaceIDOnboardingSplash {

    func particleLayer() -> some View {
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
    }

    func animatedBiometricIcon(spacing: AdaptiveSpacing) -> some View {
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
    }

    func infoSection(spacing: AdaptiveSpacing) -> some View {
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
                    .foregroundStyle(AppTheme.textColor(for: colorScheme))
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: spacing.lg) {
                Text("Intuitive and secure authentication")
                    .font(.system(size: AppTheme.fontSize17, weight: .medium))
                    .foregroundStyle(AppTheme.textColor(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .lineSpacing(AppTheme.lineSpacingNormal)
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
    }

    func actionButtons(spacing: AdaptiveSpacing, geometry: GeometryProxy) -> some View {
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
                .foregroundStyle(.white)
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
                    .foregroundStyle(AppTheme.textColor(for: colorScheme))
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
