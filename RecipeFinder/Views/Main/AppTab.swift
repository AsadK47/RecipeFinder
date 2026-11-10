import Foundation

/// The five main tabs (and iPad sidebar rows), in display order.
enum AppTab: String, CaseIterable, Hashable, Identifiable {
    case today, recipes, plan, groceries, me

    /// Recipes until Today has real content (Tabs 2/3), so a launch never lands on a placeholder.
    static let launchDefault: AppTab = .recipes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: "Today"
        case .recipes: "Recipes"
        case .plan: "Plan"
        case .groceries: "Groceries"
        case .me: "Me"
        }
    }

    var icon: String {
        switch self {
        case .today: "sun.max.fill"
        case .recipes: "book.fill"
        case .plan: "calendar"
        case .groceries: "cart.fill"
        case .me: "person.crop.circle.fill"
        }
    }

    /// The tab a navigation notification (notification tap, intent, imported file) opens; nil for ones that don't switch tabs.
    static func destination(for name: Notification.Name) -> AppTab? {
        switch name {
        case .openRecipes, .openRecipe: .recipes
        case .openGroceries: .groceries
        case .openMealPlan: .plan
        default: nil
        }
    }
}
