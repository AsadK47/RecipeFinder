import Foundation

/// Features reserved for RecipeFinder+ under the power-feature cap. Deliberately NOT gated:
/// iCloud sync, unlimited URL + manual imports, and all organisation — those are free forever.
enum PremiumFeature: CaseIterable {
    case aiTextImport   // paste-text → on-device AI interpretation
    case photoImport    // photo OCR → recipe
    case mealReminders  // scheduled meal-time reminders (advanced planning)
}

/// Central paywall gate for the freemium power-feature cap.
///
/// Launch posture is **free**: `isEnabled == false`, so `isUnlocked` always returns `true` and
/// nothing is gated. Flipping `isEnabled` (or backing it with a remote flag later) enforces the
/// cap, which is how the full purchase → gate → unlock loop is proved against the local
/// `.storekit` config. The decision is a pure function so it's unit-testable without StoreKit.
enum PremiumGate {
    /// Master switch. `false` = launch free (nothing gated); `true` = enforce the Plus cap.
    static let isEnabled = false

    /// A feature is unlocked when gating is off (launch) or the user has RecipeFinder+.
    static func isUnlocked(
        _ feature: PremiumFeature,
        isSubscribed: Bool,
        gatingEnabled: Bool = isEnabled
    ) -> Bool {
        !gatingEnabled || isSubscribed
    }
}
