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
    
    private let slides = [
        OnboardingSlide(
            icon: "book.pages.fill",
            title: "Discover & Save Recipes",
            description: "Browse our curated collection of recipes. Search by name, ingredient, or cuisine. Save your favorites with a simple tap for quick access anytime.",
            accentColor: .blue,
            features: [
                ("magnifyingglass", "Smart Search"),
                ("heart.fill", "Save Favorites"),
                ("tag.fill", "Filter & Sort")
            ]
        ),
        OnboardingSlide(
            icon: "calendar.badge.clock",
            title: "Plan Your Week",
            description: "Organize meals ahead of time with the weekly meal planner. Assign recipes to any day and meal time. Get reminders so nothing gets forgotten.",
            accentColor: .green,
            features: [
                ("calendar.circle.fill", "Weekly View"),
                ("fork.knife", "Meal Times"),
                ("bell.fill", "Reminders")
            ]
        ),
        OnboardingSlide(
            icon: "timer",
            title: "Cook with Confidence",
            description: "Set multiple cooking timers to keep track of everything on the stove. Name each timer and get notifications when they're done.",
            accentColor: .orange,
            features: [
                ("timer.circle.fill", "Multiple Timers"),
                ("speaker.wave.2.fill", "Sound Alerts"),
                ("chart.bar.fill", "Track Progress")
            ]
        )
    ]
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Text("Skip")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.15))
                            )
                    }
                    .padding()
                    .opacity(currentPage < slides.count - 1 ? 1 : 0)
                }
                
                // Slides
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
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)
                
                // Page indicators
                HStack(spacing: 12) {
                    ForEach(0..<slides.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                            .frame(width: currentPage == index ? 10 : 8, height: currentPage == index ? 10 : 8)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.bottom, 50)
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
    let features: [(icon: String, label: String)]
}

// MARK: - Individual Slide View

struct OnboardingSlideView: View {
    let slide: OnboardingSlide
    let isLastSlide: Bool
    let onGetStarted: () -> Void
    
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Main Icon with Pulse Animation
            ZStack {
                // Outer glow rings
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 2)
                        .frame(width: 160 + CGFloat(index * 40), height: 160 + CGFloat(index * 40))
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .opacity(isAnimating ? 0 : 0.5)
                        .animation(
                            .easeOut(duration: 2.0)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.3),
                            value: isAnimating
                        )
                }
                
                // Icon background
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                slide.accentColor.opacity(0.3),
                                slide.accentColor.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    )
                
                // Main icon
                Image(systemName: slide.icon)
                    .font(.system(size: 70, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .white,
                                Color.white.opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(isAnimating ? 1.0 : 0.9)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.6)
                        .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            .frame(height: 240)
            
            // Title and Description
            VStack(spacing: 16) {
                Text(slide.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(slide.description)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
            }
            
            // Features Grid
            HStack(spacing: 24) {
                ForEach(slide.features, id: \.icon) { feature in
                    VStack(spacing: 8) {
                        Image(systemName: feature.icon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(slide.accentColor)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.15))
                            )
                        
                        Text(feature.label)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .frame(width: 80)
                    }
                }
            }
            .padding(.top, 20)
            
            Spacer()
            
            // Get Started Button (only on last slide)
            if isLastSlide {
                Button(action: {
                    HapticManager.shared.success()
                    onGetStarted()
                }) {
                    HStack(spacing: 12) {
                        Text("Get Started")
                            .font(.system(size: 18, weight: .semibold))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 20))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        AppTheme.accentColor(for: selectedTheme),
                                        AppTheme.accentColor(for: selectedTheme).opacity(0.8)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: AppTheme.accentColor(for: selectedTheme).opacity(0.4), radius: 20, x: 0, y: 10)
                    )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            } else {
                // Swipe hint
                HStack(spacing: 8) {
                    Text("Swipe to continue")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .offset(x: isAnimating ? 5 : 0)
                        .animation(
                            .easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
                .padding(.bottom, 20)
            }
        }
        .padding(.vertical, 20)
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    OnboardingView()
}
