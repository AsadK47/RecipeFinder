import Foundation

/// Every in-app `NotificationCenter` name in one place, so a post and its observer can't drift apart as strings
/// (a mistyped or orphaned name silently does nothing — "OpenTimer" was posted for months with no observer).
extension Notification.Name {
    // Notification taps / intents → navigation (observed by ContentView).
    static let openRecipes  = Notification.Name("OpenRecipes")
    static let openRecipe   = Notification.Name("OpenRecipe")
    static let openGroceries = Notification.Name("OpenGroceries")
    static let openMealPlan = Notification.Name("OpenMealPlan")
    static let openTimer    = Notification.Name("OpenTimer")

    // Voice intents → cooking mode.
    static let cookingModeNextStep     = Notification.Name("CookingMode.nextStep")
    static let cookingModePreviousStep = Notification.Name("CookingMode.previousStep")
}
