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

#Preview {
    OnboardingView()
}
