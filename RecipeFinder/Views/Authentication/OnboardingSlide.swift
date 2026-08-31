import SwiftUI

/// A single onboarding slide's content.
struct OnboardingSlide {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color
    let features: [(icon: String, title: String, subtitle: String)]
}

/// Tracks vertical scroll offset within an onboarding slide (used to hide the
/// scroll hint once the user scrolls).
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
