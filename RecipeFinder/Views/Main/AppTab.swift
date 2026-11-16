import Foundation

/// The five main tabs (and iPad sidebar rows), in display order.
enum AppTab: String, CaseIterable, Hashable, Identifiable {
    case today, recipes, plan, groceries, me

    /// Today is the daily reason to open the app: tonight's meal and what to cook next.
    static let launchDefault: AppTab = .today

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
        case .openToday: .today
        case .openRecipes, .openRecipe: .recipes
        case .openGroceries: .groceries
        case .openMealPlan: .plan
        default: nil
        }
    }
}

/// "More recipes like this": a filter Recipes applies when `.openRecipes` carries one (tapping a recipe's cuisine).
struct RecipeBrowseRequest: Equatable {
    static let cuisineKey = "cuisine"
    let cuisine: String

    init?(cuisine: String?) {
        guard let trimmed = cuisine?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else { return nil }
        self.cuisine = trimmed
    }

    init?(userInfo: [AnyHashable: Any]?) {
        self.init(cuisine: userInfo?[Self.cuisineKey] as? String)
    }

    var userInfo: [String: String] { [Self.cuisineKey: cuisine] }

    /// Filters showing every recipe of this cuisine: search and other filters cleared so none hides a match; the
    /// chosen sort stays.
    func criteria(keepingSort sortOrder: SortOrder) -> RecipeFilterCriteria {
        var criteria = RecipeFilterCriteria()
        criteria.selectedCuisines = [cuisine]
        criteria.sortOrder = sortOrder
        return criteria
    }
}
