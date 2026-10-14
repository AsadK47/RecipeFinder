import Foundation

/// Decides when to ask for an App Store review: after a genuine moment of value, exactly once, never cold.
/// Pure so the threshold is unit-tested rather than a magic number inlined in a view.
enum ReviewPrompt {
    /// The cook count at which we prompt — the 3rd cook of a recipe signals a real fan.
    static let cookThreshold = 3

    /// Ask for a review only on the exact threshold cook, so it fires once (not every cook ≥ 3).
    static func shouldRequestReview(afterCookCount cookCount: Int) -> Bool {
        cookCount == cookThreshold
    }
}
