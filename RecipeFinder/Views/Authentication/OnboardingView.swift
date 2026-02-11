//
//  OnboardingView.swift
//  RecipeFinder
//
//  Beautiful 3-slide onboarding with SF Symbols
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var currentPage = 0
    @State private var showGetStarted = false
    @State private var dragOffset: CGFloat = 0
    
    private let slides = [
        OnboardingSlide(
            icon: "book.fill",
            title: "Discover & Save\nRecipes",
            description: "Search thousands of recipes by ingredients you have. Save favorites, add personal notes, and build your digital cookbook. Import recipes from any website instantly.",
            accentColor: .cyan,
            features: [
                ("magnifyingglass.circle.fill", "Smart Search", "Find by ingredients"),
                ("heart.circle.fill", "Save Favorites", "Build your collection"),
                ("note.text", "Personal Notes", "Add cooking tips"),
                ("arrow.down.doc.fill", "Recipe Import", "From any website")
            ]
        ),
        OnboardingSlide(
            icon: "cart.fill",
            title: "Shop & Track\nIngredients",
            description: "Smart shopping lists that auto-categorize items. Track kitchen inventory to reduce waste. Add ingredients from recipes with one tap.",
            accentColor: .green,
            features: [
                ("list.bullet.circle.fill", "Smart Lists", "Auto-categorized"),
                ("refrigerator.fill", "Kitchen Tracker", "Know what you have"),
                ("basket.fill", "Quick Add", "From any recipe"),
                ("checkmark.circle.fill", "Easy Check-off", "Tap to mark done")
            ]
        ),
        OnboardingSlide(
            icon: "calendar.badge.plus",
            title: "Plan Meals &\nImport Recipes",
            description: "Visual weekly meal planner for all meals. Import recipes from websites instantly with our recipe parser. Plan balanced meals and never wonder what's for dinner.",
            accentColor: .purple,
            features: [
                ("calendar.circle.fill", "Weekly Planner", "See your week"),
                ("fork.knife.circle.fill", "All Meal Times", "Breakfast to dinner"),
                ("link.circle.fill", "Recipe Import", "Paste any URL"),
                ("sparkles", "Smart Parser", "Extracts ingredients")
            ]
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
            let spacing = AdaptiveSpacing(geometry: geometry)
            
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top bar with skip button
                    HStack {
                        Spacer()
                        if currentPage < slides.count - 1 {
                            Button(action: { 
                                HapticManager.shared.light()
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    currentPage = slides.count - 1
                                }
                            }) {
                                Text("Skip")
                                    .font(.system(size: AppTheme.fontSize16, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.horizontal, spacing.xl)
                                    .padding(.vertical, spacing.sm + 2)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.2))
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .frame(height: spacing.imageSmall)
                    .padding(.horizontal, spacing.xl)
                
                    // Slides with enhanced transitions
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
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        dismiss()
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
                    
                    // Enhanced page indicators
                    HStack(spacing: spacing.sm + 2) {
                        ForEach(0..<slides.count, id: \.self) { index in
                            if currentPage == index {
                                // Active indicator - elongated capsule
                                Capsule()
                                    .fill(Color.white)
                                    .frame(width: spacing.iconMedium, height: spacing.xs + 2)
                                    .shadow(color: .white.opacity(0.5), radius: 4, x: 0, y: 2)
                            } else {
                                // Inactive indicator - small circle
                                Circle()
                                    .fill(Color.white.opacity(0.4))
                                    .frame(width: spacing.xs + 2, height: spacing.xs + 2)
                            }
                        }
                    }
                    .padding(.vertical, spacing.xxl + spacing.xs)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)
                }
            }
        }
        .interactiveDismissDisabled()
    }
}

// MARK: - Onboarding Slide Model

struct OnboardingSlide {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color
    let features: [(icon: String, title: String, subtitle: String)]
}

// MARK: - Individual Slide View

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
                    // Main Icon with Enhanced Animation
                    ZStack {
                    // Animated glow rings
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        slide.accentColor.opacity(0.3),
                                        slide.accentColor.opacity(0.0)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: spacing.imageLarge + spacing.xl + CGFloat(index * 40), height: spacing.imageLarge + spacing.xl + CGFloat(index * 40))
                            .scaleEffect(isAnimating ? 1.3 : 1.0)
                            .opacity(isAnimating ? 0 : 0.6)
                            .animation(
                                .easeOut(duration: 2.5)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.4),
                                value: isAnimating
                            )
                    }
                    
                    // Gradient background with glow
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    slide.accentColor.opacity(0.4),
                                    slide.accentColor.opacity(0.2),
                                    slide.accentColor.opacity(0.0)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: spacing.imageXLarge, height: spacing.imageXLarge)
                        .blur(radius: 2)
                    
                    // Icon background circle
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.25),
                                    Color.white.opacity(0.15)
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
                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                    
                    // Main icon with breathing animation
                    Image(systemName: slide.icon)
                        .font(.system(size: AppTheme.fontSize80, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .white,
                                    Color.white.opacity(0.9)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(isAnimating ? 1.05 : 0.95)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        .animation(
                            .easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
                .frame(height: spacing.heightPercent(0.32, min: 260))
                .padding(.top, spacing.xl)
                .scaleEffect(contentScale)
                .opacity(contentOpacity)
                
                // Title and Description
                VStack(spacing: spacing.xl) {
                    Text(slide.title)
                        .font(.system(size: AppTheme.fontSize38, weight: .bold, design: .rounded))
                        .adaptiveForegroundColor()
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .shadow(color: colorScheme == .dark ? .black.opacity(0.2) : .clear, radius: 10, x: 0, y: 5)
                    
                    Text(slide.description)
                        .font(.system(size: AppTheme.fontSize17, weight: .regular))
                        .adaptiveForegroundColor(opacity: 0.85)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, spacing.screenEdge + spacing.lg)
                }
                .padding(.bottom, spacing.xxl + spacing.lg)
                .scaleEffect(contentScale)
                .opacity(contentOpacity)
                
                // Enhanced Features Grid with cards
                VStack(spacing: spacing.lg) {
                    ForEach(Array(slide.features.enumerated()), id: \.offset) { index, feature in
                        HStack(spacing: spacing.lg) {
                            // Icon container
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                slide.accentColor.opacity(0.3),
                                                slide.accentColor.opacity(0.2)
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
                                                slide.accentColor.opacity(0.8)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            
                            // Text content
                            VStack(alignment: .leading, spacing: spacing.xxs) {
                                Text(feature.title)
                                    .font(.system(size: AppTheme.fontSize17, weight: .semibold))
                                    .adaptiveForegroundColor()
                                
                                Text(feature.subtitle)
                                    .font(.system(size: AppTheme.fontSize14, weight: .regular))
                                    .adaptiveForegroundColor(opacity: 0.7)
                            }
                            
                            Spacer()
                        }
                        .padding(spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: spacing.lg)
                                .fill(Color.white.opacity(0.12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: spacing.lg)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        .scaleEffect(contentScale)
                        .opacity(contentOpacity)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: contentOpacity)
                    }
                }
                .padding(.horizontal, spacing.screenEdge + spacing.lg)
                .padding(.bottom, spacing.xxl + spacing.xl)
                
                // Action button area
                if isLastSlide {
                    // Get Started Button - Enhanced
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
                    .padding(.bottom, spacing.xl)
                    .scaleEffect(contentScale)
                    .opacity(contentOpacity)
                } else {
                    // Swipe hint - More prominent
                    HStack(spacing: spacing.sm + 2) {
                        Text("Swipe to continue")
                            .font(.system(size: AppTheme.fontSize15, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        HStack(spacing: spacing.xxs) {
                            Circle()
                                .fill(Color.white.opacity(0.7))
                                .frame(width: spacing.xs, height: spacing.xs)
                                .offset(x: isAnimating ? 8 : 0)
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: AppTheme.fontSize14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .offset(x: isAnimating ? 8 : 0)
                        }
                        .animation(
                            .easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                    }
                    .padding(.bottom, spacing.xl)
                    .opacity(contentOpacity)
                }
            }
            .padding(.vertical, spacing.xl)
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            scrollOffset = value
            // Hide scroll indicator when user starts scrolling
            if scrollOffset < -10 && showScrollIndicator {
                withAnimation(.easeOut(duration: 0.3)) {
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
            
            // Start continuous animations
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    OnboardingView()
}
