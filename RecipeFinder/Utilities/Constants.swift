import Foundation

// App Constants
enum Constants {
    
    // UserDefaults Keys
    enum UserDefaultsKeys {
        static let hasPopulatedDatabase = "hasPopulatedDatabase"
        static let shoppingListItems = "ShoppingListItems"
        static let kitchenItems = "KitchenItems"
    }
    
    // UI Constants
    enum UI {
        static let cornerRadius: CGFloat = 12
        static let largeShadowRadius: CGFloat = 10
        static let smallShadowRadius: CGFloat = 8
        static let standardPadding: CGFloat = 20
        static let cardPadding: CGFloat = 16
        static let smallSpacing: CGFloat = 8
        static let mediumSpacing: CGFloat = 12
        static let largeSpacing: CGFloat = 20
    }
    
    // Animation Constants
    enum Animation {
        static let springResponse: Double = 0.3
        static let springDamping: Double = 0.8
        static let feedbackDuration: Double = 1.5
    }
    
    // Size Constants
    enum Sizes {
        static let iconSmall: CGFloat = 10
        static let iconMedium: CGFloat = 18
        static let iconLarge: CGFloat = 32
        static let checkboxSize: CGFloat = 24
        static let buttonHeight: CGFloat = 44
        static let recipeImageSize: CGFloat = 70
    }
}
