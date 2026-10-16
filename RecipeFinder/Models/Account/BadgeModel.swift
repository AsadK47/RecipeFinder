import Foundation
import SwiftUI

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

    static func color(for colorName: String) -> Color {
        switch colorName {
        case "purple": return .purple
        case "green":  return .green
        case "mint":   return .mint
        case "blue":   return .blue
        case "orange": return .orange
        case "yellow", "gold": return .yellow
        case "teal":   return .teal
        case "indigo": return .indigo
        default:       return .gray
        }
    }
}

/// A single cooking metric a threshold badge is measured against. `nil` criterion metric = an event badge
/// (unlocked directly by a one-off action, e.g. first import), which no automatic check ever unlocks.
enum BadgeMetric: CaseIterable {
    case recipesCollected   // library size
    case recipesCooked      // total cooks (sum of every recipe's cookCount)
    case weeklyStreak       // consecutive cooking weeks
    case cuisinesCooked     // distinct cuisines/categories among cooked recipes
    case sameRecipeCooked   // most times a single recipe has been cooked
    case recipesRated       // recipes given a star rating
    case cookPhotos         // recipes with at least one photo
}

/// What unlocks a badge: either a one-off `event`, or crossing a `threshold` on a `metric`.
struct BadgeCriterion: Equatable {
    let metric: BadgeMetric?   // nil → event badge, unlocked manually
    let threshold: Int

    static let event = BadgeCriterion(metric: nil, threshold: 0)
    static func recipesCollected(_ n: Int) -> BadgeCriterion { .init(metric: .recipesCollected, threshold: n) }
    static func recipesCooked(_ n: Int) -> BadgeCriterion { .init(metric: .recipesCooked, threshold: n) }
    static func weeklyStreak(_ n: Int) -> BadgeCriterion { .init(metric: .weeklyStreak, threshold: n) }
    static func cuisinesCooked(_ n: Int) -> BadgeCriterion { .init(metric: .cuisinesCooked, threshold: n) }
    static func sameRecipeCooked(_ n: Int) -> BadgeCriterion { .init(metric: .sameRecipeCooked, threshold: n) }
    static func recipesRated(_ n: Int) -> BadgeCriterion { .init(metric: .recipesRated, threshold: n) }
    static func cookPhotos(_ n: Int) -> BadgeCriterion { .init(metric: .cookPhotos, threshold: n) }
}

/// A snapshot of every metric badges are measured against, derived once from the library + streak.
/// Pure value type so the unlock check and progress bars are trivially testable.
struct BadgeMetrics: Equatable {
    var recipesCollected = 0
    var recipesCooked = 0
    var weeklyStreak = 0
    var cuisinesCooked = 0
    var sameRecipeCooked = 0
    var recipesRated = 0
    var cookPhotos = 0

    func value(for metric: BadgeMetric) -> Int {
        switch metric {
        case .recipesCollected: return recipesCollected
        case .recipesCooked:    return recipesCooked
        case .weeklyStreak:     return weeklyStreak
        case .cuisinesCooked:   return cuisinesCooked
        case .sameRecipeCooked: return sameRecipeCooked
        case .recipesRated:     return recipesRated
        case .cookPhotos:       return cookPhotos
        }
    }

    /// Aggregate the whole library (+ current streak) into one metrics snapshot.
    static func from(recipes: [RecipeModel], streakWeeks: Int) -> BadgeMetrics {
        var m = BadgeMetrics()
        m.recipesCollected = recipes.count
        m.weeklyStreak = streakWeeks
        m.recipesCooked = recipes.reduce(0) { $0 + max(0, $1.cookCount) }
        m.sameRecipeCooked = recipes.map(\.cookCount).max() ?? 0
        m.recipesRated = recipes.filter { $0.rating > 0 }.count
        m.cookPhotos = recipes.filter { !$0.photoNames.isEmpty }.count
        // Count distinct cuisines (falling back to category) among recipes actually cooked.
        let cuisineKeys = recipes
            .filter { $0.cookCount > 0 }
            .compactMap { r -> String? in
                let key = (r.cuisine ?? r.category).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                return key.isEmpty ? nil : key
            }
        m.cuisinesCooked = Set(cuisineKeys).count
        return m
    }
}

enum BadgeType: String, CaseIterable, Identifiable {
    // Stable id (the raw value) so the badge-celebration sheet presents via `.sheet(item:)`.
    var id: String { rawValue }

    // Collection (library size)
    case welcomeAboard = "welcome_aboard"
    case firstRecipe = "first_recipe"
    case fiveRecipes = "five_recipes"
    case tenRecipes = "ten_recipes"
    case twentyFiveRecipes = "twenty_five_recipes"
    case fiftyRecipes = "fifty_recipes"
    case hundredRecipes = "hundred_recipes"
    // Cooking volume (reward using the app, not hoarding recipes)
    case headChef = "head_chef"              // first cook
    case cookedTen = "cooked_ten"
    case cookedTwentyFive = "cooked_twenty_five"
    case cookedFifty = "cooked_fifty"
    case cookedHundred = "cooked_hundred"
    // Weekly cooking streak
    case streakTwoWeeks = "streak_two_weeks"
    case streakFourWeeks = "streak_four_weeks"
    case streakTwelveWeeks = "streak_twelve_weeks"
    case streakFiftyTwoWeeks = "streak_fifty_two_weeks"
    // Breadth / depth / quality
    case cuisinesFive = "cuisines_five"
    case sameRecipeFive = "same_recipe_five"
    case ratedTen = "rated_ten"
    case firstCookPhoto = "first_cook_photo"
    // One-off feature firsts
    case mealPlanner = "meal_planner"
    case shoppingExpert = "shopping_expert"
    case firstImport = "first_import"
    case firstPhotoImport = "first_photo_import"

    /// What unlocks this badge. The single source of truth both the unlock check and progress bars read.
    var criterion: BadgeCriterion {
        switch self {
        case .welcomeAboard:       return .recipesCollected(0)   // unlocks on join (≥0 recipes)
        case .firstRecipe:         return .recipesCollected(1)
        case .fiveRecipes:         return .recipesCollected(5)
        case .tenRecipes:          return .recipesCollected(10)
        case .twentyFiveRecipes:   return .recipesCollected(25)
        case .fiftyRecipes:        return .recipesCollected(50)
        case .hundredRecipes:      return .recipesCollected(100)
        case .headChef:            return .recipesCooked(1)
        case .cookedTen:           return .recipesCooked(10)
        case .cookedTwentyFive:    return .recipesCooked(25)
        case .cookedFifty:         return .recipesCooked(50)
        case .cookedHundred:       return .recipesCooked(100)
        case .streakTwoWeeks:      return .weeklyStreak(2)
        case .streakFourWeeks:     return .weeklyStreak(4)
        case .streakTwelveWeeks:   return .weeklyStreak(12)
        case .streakFiftyTwoWeeks: return .weeklyStreak(52)
        case .cuisinesFive:        return .cuisinesCooked(5)
        case .sameRecipeFive:      return .sameRecipeCooked(5)
        case .ratedTen:            return .recipesRated(10)
        case .firstCookPhoto:      return .cookPhotos(1)
        case .mealPlanner, .shoppingExpert, .firstImport, .firstPhotoImport:
            return .event
        }
    }

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
        case .headChef:
            return Badge(
                id: rawValue,
                title: "Head Chef",
                description: "Cooked your first recipe",
                icon: "frying.pan.fill",
                color: "orange",
                howToEarn: "Open any recipe and tap Mark as Cooked (or finish cooking mode)."
            )
        case .cookedTen:
            return Badge(
                id: rawValue,
                title: "Home Cook",
                description: "Cooked 10 times",
                icon: "fork.knife.circle.fill",
                color: "green",
                howToEarn: "Cook recipes 10 times in total — every Mark as Cooked counts."
            )
        case .cookedTwentyFive:
            return Badge(
                id: rawValue,
                title: "Seasoned",
                description: "Cooked 25 times",
                icon: "flame.fill",
                color: "orange",
                howToEarn: "Cook recipes 25 times in total. You're finding your rhythm."
            )
        case .cookedFifty:
            return Badge(
                id: rawValue,
                title: "Kitchen Veteran",
                description: "Cooked 50 times",
                icon: "medal.fill",
                color: "yellow",
                howToEarn: "Cook recipes 50 times in total. The kitchen is your home."
            )
        case .cookedHundred:
            return Badge(
                id: rawValue,
                title: "Iron Chef",
                description: "Cooked 100 times",
                icon: "trophy.fill",
                color: "gold",
                howToEarn: "Cook recipes 100 times in total. Legendary dedication."
            )
        case .streakTwoWeeks:
            return Badge(
                id: rawValue,
                title: "On a Roll",
                description: "2-week cooking streak",
                icon: "flame.fill",
                color: "orange",
                howToEarn: "Cook at least once a week for 2 weeks in a row."
            )
        case .streakFourWeeks:
            return Badge(
                id: rawValue,
                title: "Hot Streak",
                description: "4-week cooking streak",
                icon: "flame.circle.fill",
                color: "orange",
                howToEarn: "Cook at least once a week for 4 weeks in a row."
            )
        case .streakTwelveWeeks:
            return Badge(
                id: rawValue,
                title: "Unstoppable",
                description: "12-week cooking streak",
                icon: "bolt.fill",
                color: "yellow",
                howToEarn: "Keep a weekly cooking streak alive for 12 weeks — a full season."
            )
        case .streakFiftyTwoWeeks:
            return Badge(
                id: rawValue,
                title: "Year of Cooking",
                description: "52-week cooking streak",
                icon: "crown.fill",
                color: "gold",
                howToEarn: "Cook every week for a whole year. The rarest badge of all."
            )
        case .cuisinesFive:
            return Badge(
                id: rawValue,
                title: "Globetrotter",
                description: "Cooked 5 different cuisines",
                icon: "globe",
                color: "teal",
                howToEarn: "Cook recipes from 5 different cuisines. Taste the world."
            )
        case .sameRecipeFive:
            return Badge(
                id: rawValue,
                title: "Signature Dish",
                description: "Cooked one recipe 5 times",
                icon: "star.circle.fill",
                color: "purple",
                howToEarn: "Cook the same recipe 5 times — you've mastered it."
            )
        case .ratedTen:
            return Badge(
                id: rawValue,
                title: "Critic",
                description: "Rated 10 recipes",
                icon: "star.bubble.fill",
                color: "blue",
                howToEarn: "Give a star rating to 10 recipes you've cooked."
            )
        case .firstCookPhoto:
            return Badge(
                id: rawValue,
                title: "Food Stylist",
                description: "Added a cook photo",
                icon: "camera.fill",
                color: "purple",
                howToEarn: "Snap a photo of something you cooked."
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
                description: "Used the groceries feature",
                icon: "cart.circle.fill",
                color: "indigo",
                howToEarn: "Add items to your groceries and check them off as you shop."
            )
        case .firstImport:
            return Badge(
                id: rawValue,
                title: "Link Master",
                description: "Imported your first recipe from the web",
                icon: "link.circle.fill",
                color: "blue",
                howToEarn: "Import a recipe by pasting a URL in the Import tab."
            )
        case .firstPhotoImport:
            return Badge(
                id: rawValue,
                title: "Snap Chef",
                description: "Imported a recipe from a photo",
                icon: "camera.circle.fill",
                color: "purple",
                howToEarn: "Take a photo of a recipe and let the app extract it for you."
            )
        }
    }

    /// Library-size threshold for the legacy recipe-count unlock path; 0 for every non-collection badge.
    var requiredCount: Int {
        criterion.metric == .recipesCollected ? criterion.threshold : 0
    }

    /// Current/target toward this badge for a progress bar, or nil for event badges (nothing to count).
    func progress(for metrics: BadgeMetrics) -> (current: Int, target: Int)? {
        guard let metric = criterion.metric, criterion.threshold > 0 else { return nil }
        return (min(metrics.value(for: metric), criterion.threshold), criterion.threshold)
    }
}
