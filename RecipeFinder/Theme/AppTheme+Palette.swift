import SwiftUI

/// Raw theme color palette and semantic surface/text colors; consumed by `AppTheme+Colors` and `AppTheme+Gradients`.
extension AppTheme {

    // Theme accents and gradients live in `ThemePalette.swift` (OKLCH). These few fixed tones colour taste and meal
    // categories, independent of the chosen theme.
    static let redOrange = Color(red: 230/255, green: 81/255, blue: 0/255)
    static let orangeWarm = Color(red: 255/255, green: 127/255, blue: 80/255)
    static let yellowGold = Color(red: 255/255, green: 193/255, blue: 7/255)
    static let yellowAmber = Color(red: 255/255, green: 160/255, blue: 0/255)
    static let greenVibrant = Color(red: 16/255, green: 185/255, blue: 129/255)
    static let pinkHot = Color(red: 236/255, green: 72/255, blue: 153/255)

    static let secondaryBackgroundLight = Color(red: 242/255, green: 242/255, blue: 247/255)
    static let secondaryBackgroundDark = Color(red: 18/255, green: 18/255, blue: 20/255)
    
    static let primaryText = Color.primary
    static let secondaryText = Color(red: 142/255, green: 142/255, blue: 147/255)
    static let tertiaryText = Color(red: 99/255, green: 99/255, blue: 102/255)
    
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    /// Fixed deep red behind white text for destructive buttons; `.red`/`.orange` drop white text below 4.5:1 in Dark mode.
    static let destructiveFill = Color(red: 196/255, green: 40/255, blue: 40/255)
    /// Me hero avatar backdrops, one per chef type. Deep tones: white initials measure 4.6–6.7:1 on each, both modes.
    static let chefHomeCook = Color(red: 0.75, green: 0.33, blue: 0.10)
    static let chefFoodie = Color(red: 0.72, green: 0.16, blue: 0.38)
    static let chefBaker = Color(red: 0.55, green: 0.33, blue: 0.20)
    static let chefGrillMaster = Color(red: 0.70, green: 0.15, blue: 0.12)
    static let chefHealthNut = Color(red: 0.13, green: 0.48, blue: 0.25)
    static let chefAdventurousEater = Color(red: 0.12, green: 0.35, blue: 0.70)
    
    static let dividerColor = Color(red: 60/255, green: 60/255, blue: 67/255).opacity(0.36)
    static let borderColor = Color(red: 72/255, green: 72/255, blue: 74/255)
    
    static let shadowColor = Color.black.opacity(0.08)
    static let overlayColor = Color.black.opacity(0.4)
}
