
import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    var onComplete: (() -> Void)? = nil
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var currentPage = 0
    @State private var showGetStarted = false
    @State private var dragOffset: CGFloat = 0
    
    private let slides = [
        OnboardingSlide(
            icon: "square.and.arrow.down.on.square",
            title: "Import Your First\nRecipe",
            description: "From Recipes, open the menu and paste any recipe URL. RecipeFinder parses ingredients and steps for you in seconds.",
            accentColor: .blue,
            features: [
                ("line.3.horizontal", "Open Recipes Menu", "Tap the top-right menu"),
                ("link.circle.fill", "Paste Recipe URL", "Import from most sites"),
                ("sparkles", "Auto Parse", "Ingredients and steps extracted"),
                ("checkmark.circle.fill", "Save Recipe", "Add it to your cookbook")
            ]
        ),
        OnboardingSlide(
            icon: "calendar.badge.plus",
            title: "Plan One Meal\nThis Week",
            description: "Go to Planning, pick a day, and assign a recipe to breakfast, lunch, or dinner so your week starts organized.",
            accentColor: .orange,
            features: [
                ("calendar.circle.fill", "Open Planning", "View your week at a glance"),
                ("plus.circle.fill", "Tap a Meal Slot", "Pick breakfast, lunch, or dinner"),
                ("book.fill", "Select Recipe", "Use saved or imported recipes"),
                ("checkmark.circle.fill", "Save Plan", "Your week updates instantly")
            ]
        ),
        OnboardingSlide(
            icon: "cart.badge.plus",
            title: "Build Shopping List\nFrom Recipes",
            description: "From your recipe or plan, add ingredients to Shopping. Items stay organized and easy to check off in-store.",
            accentColor: .green,
            features: [
                ("basket.fill", "Add Ingredients", "Pull from selected recipes"),
                ("list.bullet.circle.fill", "Auto Grouping", "Organized by category"),
                ("checkmark.circle.fill", "Check Off While Shopping", "Tap items as you buy"),
                ("arrow.clockwise.circle.fill", "Stay Synced", "Always up to date")
            ]
        ),
        OnboardingSlide(
            icon: "timer",
            title: "Cook With Timers\nAnd Notes",
            description: "While cooking, run timers and capture quick notes so your next attempt is even better.",
            accentColor: .pink,
            features: [
                ("timer", "Start a Timer", "Set one or multiple timers"),
                ("bell.fill", "Get Alerts", "Know exactly when to check food"),
                ("note.text", "Save Notes", "Record tweaks and tips"),
                ("heart.fill", "Favorite Winners", "Find your best recipes fast")
            ]
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
            let spacing = AdaptiveSpacing(geometry: geometry)
            
            ZStack {
                onboardingBackdrop
                
                VStack(spacing: 0) {
                    TabView(selection: $currentPage) {
                        ForEach(0..<slides.count, id: \.self) { index in
                            OnboardingSlideView(
                                slide: slides[index],
                                isLastSlide: index == slides.count - 1,
                                spacing: spacing,
                                onGetStarted: {
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        showGetStarted = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.animationDelayXShort) {
                                        if let onComplete {
                                            onComplete()
                                        } else {
                                            dismiss()
                                        }
                                    }
                                }
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)
                    .onChange(of: currentPage) { _, _ in
                        HapticManager.shared.light()
                    }
                    
                    HStack(spacing: spacing.sm + 2) {
                        ForEach(0..<slides.count, id: \.self) { index in
                            if currentPage == index {
                                Capsule()
                                    .fill(Color.white)
                                    .frame(width: spacing.iconMedium, height: spacing.xs + 2)
                                    .shadow(color: .white.opacity(AppTheme.glassLightOpacity), radius: 4, x: 0, y: 2)
                            } else {
                                Circle()
                                    .fill(Color.white.opacity(AppTheme.lowEmphasisOpacity))
                                    .frame(width: spacing.xs + 2, height: spacing.xs + 2)
                            }
                        }
                    }
                    .padding(.vertical, spacing.lg)
                    .padding(.bottom, spacing.xl)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)
                }
                
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                HStack {
                    if currentPage < slides.count - 1 {
                        Button(action: {
                            HapticManager.shared.light()
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentPage = slides.count - 1
                            }
                        }) {
                            Text("Skip")
                                .font(.system(size: AppTheme.fontSize16, weight: .semibold))
                                .adaptiveForegroundColor(opacity: AppTheme.veryHighEmphasisOpacity)
                                .padding(.horizontal, spacing.lg)
                                .padding(.vertical, spacing.xs + 1)
                                .background(
                                    Capsule()
                                        .fill(AppTheme.textColor(for: colorScheme).opacity(0.2))
                                        .overlay(
                                            Capsule()
                                                .stroke(AppTheme.textColor(for: colorScheme).opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                        .transition(.scale.combined(with: .opacity))
                    }

                    Spacer()
                }
                .padding(.horizontal, spacing.xl)
                .padding(.top, spacing.xs)
                .padding(.bottom, spacing.sm)
                .frame(height: spacing.heightPercent(0.06, min: 56))
            }
        }
        .interactiveDismissDisabled()
    }

    private var onboardingBackdrop: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            Circle()
                .fill(AppTheme.accentColor(for: selectedTheme).opacity(0.28))
                .frame(width: 320, height: 320)
                .blur(radius: 70)
                .offset(x: -140, y: -220)
            
            Circle()
                .fill(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.18))
                .frame(width: 240, height: 240)
                .blur(radius: 60)
                .offset(x: 150, y: -160)
            
            Circle()
                .fill(AppTheme.accentColor(for: selectedTheme).opacity(0.18))
                .frame(width: 280, height: 280)
                .blur(radius: 80)
                .offset(x: 120, y: 300)
            
            LinearGradient(
                colors: [
                    Color.black.opacity(colorScheme == .dark ? 0.18 : 0.08),
                    Color.black.opacity(colorScheme == .dark ? 0.32 : 0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}

struct OnboardingSlide {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color
    let features: [(icon: String, title: String, subtitle: String)]
}

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

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    OnboardingView()
}
