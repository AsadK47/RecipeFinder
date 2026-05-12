import Foundation

struct Badge: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let color: String
    let dateEarned: Date?
    let isUnlocked: Bool
    let howToEarn: String
    
    init(id: String, title: String, description: String, icon: String, color: String, dateEarned: Date? = nil, isUnlocked: Bool = false, howToEarn: String = "") {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.color = color
        self.dateEarned = dateEarned
        self.isUnlocked = isUnlocked
        self.howToEarn = howToEarn
    }
}

enum BadgeType: String, CaseIterable {
    case welcomeAboard = "welcome_aboard"
    case firstRecipe = "first_recipe"
    case fiveRecipes = "five_recipes"
    case tenRecipes = "ten_recipes"
    case twentyFiveRecipes = "twenty_five_recipes"
    case fiftyRecipes = "fifty_recipes"
    case hundredRecipes = "hundred_recipes"
    case mealPlanner = "meal_planner"
    case shoppingExpert = "shopping_expert"
    
    var badge: Badge {
        switch self {
        case .welcomeAboard:
            return Badge(
                id: rawValue,
                title: "Welcome Aboard!",
                description: "Joined RecipeFinder",
                icon: "star.circle.fill",
                color: "purple",
                howToEarn: "Create your account and start your culinary journey!"
            )
        case .firstRecipe:
            return Badge(
                id: rawValue,
                title: "First Bite",
                description: "Added your first recipe",
                icon: "fork.knife.circle.fill",
                color: "green",
                howToEarn: "Add or import your first recipe to unlock this achievement."
            )
        case .fiveRecipes:
            return Badge(
                id: rawValue,
                title: "Getting Hungry",
                description: "Collected 5 recipes",
                icon: "leaf.circle.fill",
                color: "mint",
                howToEarn: "Build your collection by adding or importing 5 recipes."
            )
        case .tenRecipes:
            return Badge(
                id: rawValue,
                title: "Cookbook Rookie",
                description: "Collected 10 recipes",
                icon: "books.vertical.circle.fill",
                color: "blue",
                howToEarn: "Grow your recipe library to 10 delicious recipes."
            )
        case .twentyFiveRecipes:
            return Badge(
                id: rawValue,
                title: "Cooking With Fire",
                description: "Collected 25 recipes",
                icon: "flame.circle.fill",
                color: "orange",
                howToEarn: "Expand your culinary repertoire to 25 recipes."
            )
        case .fiftyRecipes:
            return Badge(
                id: rawValue,
                title: "Master Chef",
                description: "Collected 50 recipes",
                icon: "crown.fill",
                color: "yellow",
                howToEarn: "Become a master by collecting 50 amazing recipes."
            )
        case .hundredRecipes:
            return Badge(
                id: rawValue,
                title: "Legendary Feast",
                description: "Collected 100+ recipes",
                icon: "trophy.fill",
                color: "gold",
                howToEarn: "Achieve legendary status with 100 or more recipes in your collection."
            )
        case .mealPlanner:
            return Badge(
                id: rawValue,
                title: "Time Traveler",
                description: "Created your first meal plan",
                icon: "calendar.circle.fill",
                color: "teal",
                howToEarn: "Go to the Planning tab and create your first meal plan for the week."
            )
        case .shoppingExpert:
            return Badge(
                id: rawValue,
                title: "Grocery Ninja",
                description: "Used the shopping list feature",
                icon: "cart.circle.fill",
                color: "indigo",
                howToEarn: "Add items to your shopping list and check them off as you shop."
            )
        }
    }
    
    var requiredCount: Int {
        switch self {
        case .welcomeAboard: return 0
        case .firstRecipe: return 1
        case .fiveRecipes: return 5
        case .tenRecipes: return 10
        case .twentyFiveRecipes: return 25
        case .fiftyRecipes: return 50
        case .hundredRecipes: return 100
        case .mealPlanner: return 0
        case .shoppingExpert: return 0
        }
    }
}
