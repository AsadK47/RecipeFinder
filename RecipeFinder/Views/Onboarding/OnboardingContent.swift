import SwiftUI

/// Canonical onboarding slide data, extracted so `OnboardingContentTests` can verify the content contract independently of the view.
enum OnboardingContent {
    static let slides: [OnboardingSlide] = [
        OnboardingSlide(
            icon: "tray.and.arrow.down.fill",
            title: "Get your first recipe in",
            description: "Tap + on Recipes — paste a recipe link, scan a cookbook photo, or type it yourself. All free, all on device.",
            accentColor: .orange
        ),
        OnboardingSlide(
            icon: "cart.badge.plus",
            title: "Your grocery list writes itself",
            description: "Open any recipe and tap the cart icon beside an ingredient to add it to Groceries — already sorted by category.",
            accentColor: .green
        ),
        OnboardingSlide(
            icon: "calendar",
            title: "Plan what you're cooking",
            description: "In Planning, tap any day to assign a recipe and see the whole week's meals at a glance.",
            accentColor: .purple
        )
    ]
}
