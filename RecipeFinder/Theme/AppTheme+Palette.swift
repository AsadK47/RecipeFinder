import SwiftUI

/// Raw theme color palette and semantic surface/text colors; consumed by `AppTheme+Colors` and `AppTheme+Gradients`.
extension AppTheme {

    static let tealBrightLight = Color(red: 20/255, green: 184/255, blue: 166/255)
    static let tealMediumLight = Color(red: 45/255, green: 155/255, blue: 180/255)
    static let tealDeepLight = Color(red: 59/255, green: 130/255, blue: 246/255)
    static let tealRichLight = Color(red: 67/255, green: 97/255, blue: 238/255)
    
    static let tealBrightDark = Color(red: 15/255, green: 120/255, blue: 110/255)
    static let tealMediumDark = Color(red: 25/255, green: 95/255, blue: 120/255)
    static let tealDeepDark = Color(red: 30/255, green: 70/255, blue: 150/255)
    static let tealRichDark = Color(red: 35/255, green: 50/255, blue: 130/255)
    
    static let purpleRich = Color(red: 131/255, green: 58/255, blue: 180/255)
    static let purpleVibrant = Color(red: 108/255, green: 75/255, blue: 210/255)
    static let purpleDeep = Color(red: 88/255, green: 86/255, blue: 214/255)
    static let purpleTeal = Color(red: 64/255, green: 224/255, blue: 208/255)
    
    static let redCrimson = Color(red: 139/255, green: 0/255, blue: 0/255)
    static let redWarm = Color(red: 178/255, green: 34/255, blue: 34/255)
    static let redBurnt = Color(red: 204/255, green: 85/255, blue: 0/255)
    static let redOrange = Color(red: 230/255, green: 81/255, blue: 0/255)
    
    static let orangeBright = Color(red: 251/255, green: 146/255, blue: 60/255)
    static let orangeWarm = Color(red: 255/255, green: 127/255, blue: 80/255)
    static let coralDeep = Color(red: 220/255, green: 94/255, blue: 75/255)
    static let coralRich = Color(red: 183/255, green: 65/255, blue: 84/255)
    
    static let yellowBright = Color(red: 255/255, green: 214/255, blue: 10/255)
    static let yellowGold = Color(red: 255/255, green: 193/255, blue: 7/255)
    static let yellowAmber = Color(red: 255/255, green: 160/255, blue: 0/255)
    static let yellowDeep = Color(red: 230/255, green: 126/255, blue: 34/255)
    
    static let greenVibrant = Color(red: 16/255, green: 185/255, blue: 129/255)
    static let greenMedium = Color(red: 34/255, green: 197/255, blue: 94/255)
    static let greenTeal = Color(red: 20/255, green: 184/255, blue: 166/255)
    static let greenDeep = Color(red: 59/255, green: 130/255, blue: 246/255)
    
    static let pinkHot = Color(red: 236/255, green: 72/255, blue: 153/255)
    static let pinkVibrant = Color(red: 219/255, green: 39/255, blue: 119/255)
    static let pinkPurple = Color(red: 168/255, green: 85/255, blue: 247/255)
    static let pinkBlue = Color(red: 96/255, green: 165/255, blue: 250/255)
    
    static let goldBrilliant = Color(red: 255/255, green: 223/255, blue: 0/255)
    static let goldShiny = Color(red: 255/255, green: 215/255, blue: 77/255)
    static let goldRich = Color(red: 212/255, green: 175/255, blue: 55/255)
    static let silverCool = Color(red: 192/255, green: 192/255, blue: 192/255)
    static let goldBronze = Color(red: 139/255, green: 90/255, blue: 43/255)
    static let goldCharcoal = Color(red: 45/255, green: 45/255, blue: 45/255)
    static let goldBlack = Color(red: 15/255, green: 15/255, blue: 15/255)
    
    
    static let secondaryBackgroundLight = Color(red: 242/255, green: 242/255, blue: 247/255)
    static let secondaryBackgroundDark = Color(red: 18/255, green: 18/255, blue: 20/255)
    
    static let primaryText = Color.primary
    static let secondaryText = Color(red: 142/255, green: 142/255, blue: 147/255)
    static let tertiaryText = Color(red: 99/255, green: 99/255, blue: 102/255)
    
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    
    static let dividerColor = Color(red: 60/255, green: 60/255, blue: 67/255).opacity(0.36)
    static let borderColor = Color(red: 72/255, green: 72/255, blue: 74/255)
    
    static let shadowColor = Color.black.opacity(0.08)
    static let overlayColor = Color.black.opacity(0.4)
}
