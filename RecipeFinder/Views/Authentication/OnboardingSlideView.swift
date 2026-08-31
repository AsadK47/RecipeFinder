import SwiftUI

/// Renders one onboarding slide: animated icon, title/description, feature rows,
/// and either a "Get Started" button (last slide) or a swipe hint.
struct OnboardingSlideView: View {
    let slide: OnboardingSlide
    let isLastSlide: Bool
    let spacing: AdaptiveSpacing
    let onGetStarted: () -> Void
    
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAnimating = false
    @State private var contentScale: CGFloat = 0.8
    @State private var contentOpacity: Double = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var showScrollIndicator = true
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                GeometryReader { scrollGeometry in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: scrollGeometry.frame(in: .named("scroll")).minY
                    )
                }
                .frame(height: 0)
                
                VStack(spacing: 0) {
                    ZStack {
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        slide.accentColor.opacity(AppTheme.shadowDarkOpacity),
                                        slide.accentColor.opacity(AppTheme.zeroOpacity)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: spacing.imageLarge + spacing.xl + CGFloat(index * 40), height: spacing.imageLarge + spacing.xl + CGFloat(index * 40))
                            .scaleEffect(isAnimating ? AppTheme.scaleEffectBounce : AppTheme.scaleNeutral)
                            .opacity(isAnimating ? AppTheme.zeroOpacity : AppTheme.mediumEmphasisOpacity)
                            .animation(
                                .easeOut(duration: AppTheme.animationDuration25)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.4),
                                value: isAnimating
                            )
                    }
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    slide.accentColor.opacity(AppTheme.lowEmphasisOpacity),
                                    slide.accentColor.opacity(AppTheme.overlayLightOpacity),
                                    slide.accentColor.opacity(AppTheme.zeroOpacity)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: spacing.imageXLarge, height: spacing.imageXLarge)
                        .blur(radius: AppTheme.blurRadiusTiny)
                    
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
                        .frame(width: spacing.imageLarge + spacing.xl, height: spacing.imageLarge + spacing.xl)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                        )
                        .shadow(color: .black.opacity(AppTheme.shadowLightOpacity), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: slide.icon)
                        .font(.system(size: AppTheme.fontSize80, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    AppTheme.textColor(for: colorScheme),
                                    AppTheme.textColor(for: colorScheme).opacity(0.9)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(isAnimating ? 1.05 : 0.95)
                        .shadow(color: colorScheme == .dark ? .black.opacity(AppTheme.overlayLightOpacity) : .clear, radius: 10, x: 0, y: 5)
                        .animation(
                            .easeInOut(duration: AppTheme.animationDelayFeedback)
                            .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
                .frame(height: spacing.heightPercent(0.32, min: 260))
                .padding(.top, spacing.lg)
                .scaleEffect(contentScale)
                .opacity(contentOpacity)
                
                VStack(spacing: spacing.xl) {
                    Text(slide.title)
                        .font(.system(size: AppTheme.fontSize38, weight: .bold, design: .rounded))
                        .adaptiveForegroundColor()
                        .multilineTextAlignment(.center)
                        .lineSpacing(AppTheme.lineSpacingNormal)
                        .shadow(color: colorScheme == .dark ? .black.opacity(AppTheme.overlayLightOpacity) : .clear, radius: 10, x: 0, y: 5)
                    
                    Text(slide.description)
                        .font(.system(size: AppTheme.fontSize17, weight: .regular))
                        .adaptiveForegroundColor(opacity: AppTheme.nearSolidOpacity)
                        .multilineTextAlignment(.center)
                        .lineSpacing(AppTheme.lineSpacingRelaxed)
                        .padding(.horizontal, spacing.screenEdge + spacing.lg)
                }
                .padding(.bottom, spacing.xxl + spacing.lg)
                .scaleEffect(contentScale)
                .opacity(contentOpacity)
                
                VStack(spacing: spacing.lg) {
                    ForEach(Array(slide.features.enumerated()), id: \.offset) { index, feature in
                        HStack(spacing: spacing.lg) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                slide.accentColor.opacity(AppTheme.shadowDarkOpacity),
                                                slide.accentColor.opacity(AppTheme.overlayLightOpacity)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: spacing.touchTarget + spacing.xs, height: spacing.touchTarget + spacing.xs)
                                
                                Image(systemName: feature.icon)
                                    .font(.system(size: AppTheme.fontSize24, weight: .semibold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                slide.accentColor,
                                                slide.accentColor.opacity(AppTheme.highEmphasisOpacity)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: spacing.xxs) {
                                Text(feature.title)
                                    .font(.system(size: AppTheme.fontSize17, weight: .semibold))
                                    .adaptiveForegroundColor()
                                
                                Text(feature.subtitle)
                                    .font(.system(size: AppTheme.fontSize14, weight: .regular))
                                    .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
                            }
                            
                            Spacer()
                        }
                        .padding(spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: spacing.lg)
                                .fill(colorScheme == .dark ? Color.black.opacity(0.28) : Color.white.opacity(0.22))
                                .overlay(
                                    RoundedRectangle(cornerRadius: spacing.lg)
                                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.18 : 0.28), lineWidth: 1)
                                )
                        )
                        .shadow(color: .black.opacity(AppTheme.shadowLightOpacity), radius: 10, x: 0, y: 5)
                        .scaleEffect(contentScale)
                        .opacity(contentOpacity)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: contentOpacity)
                    }
                }
                .padding(.horizontal, spacing.screenEdge + spacing.lg)
                .padding(.bottom, spacing.xxl + spacing.xl)
                
                if isLastSlide {
                    Button(action: {
                        HapticManager.shared.success()
                        onGetStarted()
                    }) {
                        HStack(spacing: spacing.md) {
                            Text("Get Started")
                                .font(.system(size: AppTheme.fontSize20, weight: .bold))
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: AppTheme.fontSize22))
                        }
                        .adaptiveForegroundColor()
                        .frame(maxWidth: .infinity)
                        .frame(height: spacing.buttonHeight + spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: spacing.lg)
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
                                .shadow(color: AppTheme.accentColor(for: selectedTheme).opacity(0.5), radius: 20, x: 0, y: 10)
                        )
                    }
                    .padding(.horizontal, spacing.screenEdge + spacing.lg)
                    .padding(.bottom, spacing.lg)
                    .scaleEffect(contentScale)
                    .opacity(contentOpacity)
                } else {
                    HStack(spacing: spacing.sm + 2) {
                        Text("Swipe to continue")
                            .font(.system(size: AppTheme.fontSize15, weight: .medium))
                            .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
                        
                        HStack(spacing: spacing.xxs) {
                            Circle()
                                .fill(AppTheme.textColor(for: colorScheme).opacity(0.7))
                                .frame(width: spacing.xs, height: spacing.xs)
                                .offset(x: isAnimating ? 8 : 0)
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: AppTheme.fontSize14, weight: .semibold))
                                .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
                                .offset(x: isAnimating ? 8 : 0)
                        }
                        .animation(
                            .easeInOut(duration: AppTheme.animationDelayLong)
                            .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                    }
                    .padding(.bottom, spacing.lg)
                    .opacity(contentOpacity)
                }
            }
            .padding(.vertical, spacing.lg)
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            scrollOffset = value
            if scrollOffset < -10 && showScrollIndicator {
                withAnimation(.easeOut(duration: AppTheme.animationDelayXShort)) {
                    showScrollIndicator = false
                }
            }
        }
        
    }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                contentScale = 1.0
                contentOpacity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.animationDelayXShort) {
                isAnimating = true
            }
        }
    }
}
