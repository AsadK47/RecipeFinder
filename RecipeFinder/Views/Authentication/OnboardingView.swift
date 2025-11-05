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
            icon: "book.pages.fill",
            title: "Discover Delicious\nRecipes",
            description: "Browse hundreds of curated recipes from around the world. Search by name, ingredient, or cuisine type. Save your favorites and build your personal cookbook.",
            accentColor: .blue,
            features: [
                ("magnifyingglass.circle.fill", "Smart Search", "Find recipes instantly"),
                ("heart.circle.fill", "Save Favorites", "Build your collection"),
                ("tag.circle.fill", "Smart Filters", "Sort by any criteria")
            ]
        ),
        OnboardingSlide(
            icon: "calendar.badge.clock",
            title: "Plan Your Meals\nEffortlessly",
            description: "Organize your week with the intuitive meal planner. Drag recipes to any day and meal slot. Get timely reminders so you never miss a meal prep.",
            accentColor: .green,
            features: [
                ("calendar.circle.fill", "Weekly Calendar", "Visual meal planning"),
                ("fork.knife.circle.fill", "Meal Slots", "Breakfast, lunch, dinner"),
                ("bell.badge.fill", "Smart Reminders", "Never forget to prep")
            ]
        ),
        OnboardingSlide(
            icon: "timer",
            title: "Cook Like a\nPro Chef",
            description: "Master your timing with multiple concurrent timers. Name each one for different dishes. Get notifications with haptic feedback when time's up.",
            accentColor: .orange,
            features: [
                ("timer.circle.fill", "Multi-Timers", "Track all your dishes"),
                ("speaker.wave.2.circle.fill", "Audio Alerts", "Never miss a ding"),
                ("chart.bar.circle.fill", "Progress Tracking", "Visual countdown")
            ]
        )
    ]
    
    var body: some View {
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
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
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
                .frame(height: 60)
                .padding(.horizontal, 20)
                
                // Slides with enhanced transitions
                TabView(selection: $currentPage) {
                    ForEach(0..<slides.count, id: \.self) { index in
                        OnboardingSlideView(
                            slide: slides[index],
                            isLastSlide: index == slides.count - 1,
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
                HStack(spacing: 10) {
                    ForEach(0..<slides.count, id: \.self) { index in
                        if currentPage == index {
                            // Active indicator - elongated capsule
                            Capsule()
                                .fill(Color.white)
                                .frame(width: 24, height: 8)
                                .shadow(color: .white.opacity(0.5), radius: 4, x: 0, y: 2)
                        } else {
                            // Inactive indicator - small circle
                            Circle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                .padding(.vertical, 30)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)
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
    let onGetStarted: () -> Void
    
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAnimating = false
    @State private var contentScale: CGFloat = 0.8
    @State private var contentOpacity: Double = 0
    
    var body: some View {
        ScrollView(showsIndicators: false) {
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
                            .frame(width: 180 + CGFloat(index * 40), height: 180 + CGFloat(index * 40))
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
                        .frame(width: 200, height: 200)
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
                        .frame(width: 180, height: 180)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                    
                    // Main icon with breathing animation
                    Image(systemName: slide.icon)
                        .font(.system(size: 80, weight: .semibold))
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
                .frame(height: 260)
                .padding(.top, 20)
                .scaleEffect(contentScale)
                .opacity(contentOpacity)
                
                // Title and Description
                VStack(spacing: 20) {
                    Text(slide.title)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .white,
                                    .white.opacity(0.95)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    
                    Text(slide.description)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 40)
                .scaleEffect(contentScale)
                .opacity(contentOpacity)
                
                // Enhanced Features Grid with cards
                VStack(spacing: 16) {
                    ForEach(Array(slide.features.enumerated()), id: \.offset) { index, feature in
                        HStack(spacing: 16) {
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
                                    .frame(width: 52, height: 52)
                                
                                Image(systemName: feature.icon)
                                    .font(.system(size: 24, weight: .semibold))
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
                            VStack(alignment: .leading, spacing: 4) {
                                Text(feature.title)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text(feature.subtitle)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        .scaleEffect(contentScale)
                        .opacity(contentOpacity)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: contentOpacity)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                
                // Action button area
                if isLastSlide {
                    // Get Started Button - Enhanced
                    Button(action: {
                        HapticManager.shared.success()
                        onGetStarted()
                    }) {
                        HStack(spacing: 12) {
                            Text("Get Started")
                                .font(.system(size: 19, weight: .bold))
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 22))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
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
                    .padding(.horizontal, 32)
                    .padding(.bottom, 20)
                    .scaleEffect(contentScale)
                    .opacity(contentOpacity)
                } else {
                    // Swipe hint - More prominent
                    HStack(spacing: 10) {
                        Text("Swipe to continue")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.white.opacity(0.7))
                                .frame(width: 6, height: 6)
                                .offset(x: isAnimating ? 8 : 0)
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .offset(x: isAnimating ? 8 : 0)
                        }
                        .animation(
                            .easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                    }
                    .padding(.bottom, 20)
                    .opacity(contentOpacity)
                }
            }
            .padding(.vertical, 20)
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

#Preview {
    OnboardingView()
}
