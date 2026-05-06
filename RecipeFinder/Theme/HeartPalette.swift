import SwiftUI

enum HeartPalette {
    static let coralRed   = Color(red: 1.00, green: 0.20, blue: 0.40)
    static let tomato     = Color(red: 0.96, green: 0.26, blue: 0.21)
    static let salmon     = Color(red: 1.00, green: 0.38, blue: 0.27)
    static let deepOrange = Color(red: 1.00, green: 0.50, blue: 0.00)
    static let amber      = Color(red: 1.00, green: 0.65, blue: 0.00)
    static let blush      = Color(red: 1.00, green: 0.75, blue: 0.80)
    static let magenta    = Color(red: 0.80, green: 0.20, blue: 0.60)
    static let rose       = Color(red: 1.00, green: 0.40, blue: 0.50)

    static let gradientColors: [Color] = [coralRed, tomato, salmon, deepOrange]
    static let particleColors: [Color] = [coralRed, tomato, salmon, deepOrange, amber, blush, magenta, rose]

    static let gradient = LinearGradient(
        gradient: Gradient(colors: gradientColors),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
