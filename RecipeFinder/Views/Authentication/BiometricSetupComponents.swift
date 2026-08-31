import SwiftUI

/// Supporting views for `BiometricSetupView`: floating particles, the animated
/// biometric icon (with pulsing rings), the enable button, and benefit rows.

struct ParticleView: View {
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
            .adaptiveForegroundColor(opacity: AppTheme.tinyOpacity)
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

struct BiometricIconView: View {
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
                        accentColor.opacity(AppTheme.lowEmphasisOpacity),
                        accentColor.opacity(AppTheme.overlayLightOpacity),
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
                        accentColor.opacity(AppTheme.shadowDarkOpacity),
                        accentColor.opacity(AppTheme.overlayLightOpacity)
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
            .shadow(color: accentColor.opacity(AppTheme.shadowDarkOpacity), radius: spacing.xl, x: 0, y: spacing.xs)
    }
    
    private var iconImage: some View {
        Image(systemName: icon)
            .font(.system(size: AppTheme.fontSize60, weight: .medium))
            .foregroundStyle(
                LinearGradient(
                    colors: [accentColor, accentColor.opacity(AppTheme.highEmphasisOpacity)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: .black.opacity(AppTheme.overlayLightOpacity), radius: 5, x: 0, y: 2)
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
                        accentColor.opacity(AppTheme.lowEmphasisOpacity),
                        accentColor.opacity(AppTheme.zeroOpacity)
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
                .easeInOut(duration: AppTheme.animationDelayFeedback)
                .repeatForever(autoreverses: true)
                .delay(ringDelay),
                value: iconScale
            )
    }
}

struct EnableButton: View {
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
                        .font(.system(size: AppTheme.fontSize18, weight: .bold))
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
                                colors: [accentColor, accentColor.opacity(AppTheme.nearSolidOpacity)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    RoundedRectangle(cornerRadius: spacing.lg)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(AppTheme.shadowDarkOpacity),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: shimmerOffset)
                }
            )
            .shadow(color: accentColor.opacity(AppTheme.glassLightOpacity), radius: spacing.xl, x: 0, y: spacing.xs)
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
                .adaptiveForegroundColor(opacity: AppTheme.veryHighEmphasisOpacity)
                .frame(width: spacing.md + spacing.md)
            
            Text(text)
                .font(.system(size: AppTheme.fontSize15, weight: .medium))
                .adaptiveForegroundColor(opacity: AppTheme.nearSolidOpacity)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
