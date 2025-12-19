import Foundation

// MARK: - Badge Model

struct Badge: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let color: String
    let dateEarned: Date?
    let isUnlocked: Bool
    
    init(id: String, title: String, description: String, icon: String, color: String, dateEarned: Date? = nil, isUnlocked: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.color = color
        self.dateEarned = dateEarned
        self.isUnlocked = isUnlocked
    }
}

// MARK: - Badge Types

enum BadgeType: String, CaseIterable {
    case welcomeAboard = "welcome_aboard"
    case firstRecipe = "first_recipe"
    case fiveRecipes = "five_recipes"
    case tenRecipes = "ten_recipes"
    case twentyFiveRecipes = "twenty_five_recipes"
    case fiftyRecipes = "fifty_recipes"
    case hundredRecipes = "hundred_recipes"
    
    var badge: Badge {
        switch self {
        case .welcomeAboard:
            return Badge(
                id: rawValue,
                title: "Welcome Aboard! 🎉",
                description: "Joined Recipe Finder",
                icon: "star.circle.fill",
                color: "purple"
            )
        case .firstRecipe:
            return Badge(
                id: rawValue,
                title: "First Recipe! 👨‍🍳",
                description: "Added your first recipe",
                icon: "fork.knife.circle.fill",
                color: "green"
            )
        case .fiveRecipes:
            return Badge(
                id: rawValue,
                title: "Getting Started 🌱",
                description: "Collected 5 recipes",
                icon: "leaf.circle.fill",
                color: "mint"
            )
        case .tenRecipes:
            return Badge(
                id: rawValue,
                title: "Recipe Collector 📚",
                description: "Collected 10 recipes",
                icon: "books.vertical.circle.fill",
                color: "blue"
            )
        case .twentyFiveRecipes:
            return Badge(
                id: rawValue,
                title: "Home Chef 🔥",
                description: "Collected 25 recipes",
                icon: "flame.circle.fill",
                color: "orange"
            )
        case .fiftyRecipes:
            return Badge(
                id: rawValue,
                title: "Master Chef 👑",
                description: "Collected 50 recipes",
                icon: "crown.fill",
                color: "yellow"
            )
        case .hundredRecipes:
            return Badge(
                id: rawValue,
                title: "Recipe Legend 🏆",
                description: "Collected 100+ recipes",
                icon: "trophy.fill",
                color: "gold"
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
        }
    }
}

// MARK: - Badge Manager

class BadgeManager: ObservableObject {
    nonisolated(unsafe) static let shared = BadgeManager()
    
    @Published var unlockedBadges: [String: Badge] = [:]
    
    private let userDefaults = UserDefaults.standard
    private let badgesKey = "unlockedBadges"
    
    private init() {
        loadBadges()
    }
    
    func checkAndUnlockBadges(recipeCount: Int) {
        for badgeType in BadgeType.allCases {
            if recipeCount >= badgeType.requiredCount && !isBadgeUnlocked(badgeType.rawValue) {
                unlockBadge(badgeType)
            }
        }
    }
    
    func unlockBadge(_ badgeType: BadgeType, customDate: Date? = nil) {
        let badge = badgeType.badge
        let unlockedBadge = Badge(
            id: badge.id,
            title: badge.title,
            description: badge.description,
            icon: badge.icon,
            color: badge.color,
            dateEarned: customDate ?? Date(),
            isUnlocked: true
        )
        unlockedBadges[badge.id] = unlockedBadge
        saveBadges()
    }
    
    func isBadgeUnlocked(_ badgeId: String) -> Bool {
        unlockedBadges[badgeId] != nil
    }
    
    func getAllBadges(recipeCount: Int) -> [Badge] {
        return BadgeType.allCases.map { badgeType in
            if let unlocked = unlockedBadges[badgeType.rawValue] {
                return unlocked
            } else {
                let badge = badgeType.badge
                return Badge(
                    id: badge.id,
                    title: badge.title,
                    description: badge.description,
                    icon: badge.icon,
                    color: badge.color,
                    dateEarned: nil,
                    isUnlocked: false
                )
            }
        }
    }
    
    private func saveBadges() {
        if let encoded = try? JSONEncoder().encode(unlockedBadges) {
            userDefaults.set(encoded, forKey: badgesKey)
        }
    }
    
    private func loadBadges() {
        if let data = userDefaults.data(forKey: badgesKey),
           let decoded = try? JSONDecoder().decode([String: Badge].self, from: data) {
            unlockedBadges = decoded
        }
    }
}
