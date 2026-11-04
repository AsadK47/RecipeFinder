import SwiftUI
import Foundation

/// Built-in recipe group defined by a matching rule; membership computed at read time, nothing stored.
enum SmartCollection: String, CaseIterable, Identifiable {
    case quickMeals
    case easyRecipes
    case vegetarian
    case highRated
    case recentlyCooked
    case fewIngredients

    var id: String { rawValue }

    var name: String {
        switch self {
        case .quickMeals:     return "Quick Meals"
        case .easyRecipes:    return "Easy Recipes"
        case .vegetarian:     return "Vegetarian"
        case .highRated:      return "Highly Rated"
        case .recentlyCooked: return "Recently Cooked"
        case .fewIngredients: return "5 Ingredients or Less"
        }
    }

    var systemImage: String {
        switch self {
        case .quickMeals:     return "timer"
        case .easyRecipes:    return "hand.thumbsup.fill"
        case .vegetarian:     return "leaf.fill"
        case .highRated:      return "star.fill"
        case .recentlyCooked: return "clock.arrow.circlepath"
        case .fewIngredients: return "list.number"
        }
    }

    var color: Color {
        switch self {
        case .quickMeals:     return .orange
        case .easyRecipes:    return .green
        case .vegetarian:     return Color(red: 0.18, green: 0.72, blue: 0.42)
        case .highRated:      return .yellow
        case .recentlyCooked: return .blue
        case .fewIngredients: return .purple
        }
    }

    /// True when `recipe` satisfies this collection's rule.
    func matches(_ recipe: RecipeModel) -> Bool {
        switch self {
        case .quickMeals:
            let minutes = TimeExtractor.extractMinutes(from: recipe.prepTime)
                        + TimeExtractor.extractMinutes(from: recipe.cookingTime)
            return minutes > 0 && minutes <= 30
        case .easyRecipes:
            return RecipeWizardBuilder.normalizeDifficulty(recipe.difficulty) == "Basic"
        case .vegetarian:
            return recipe.dietaryInfo.isVegetarian
        case .highRated:
            return recipe.rating >= 4
        case .recentlyCooked:
            guard let last = recipe.lastCookedAt else { return false }
            let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? Int.max
            return days <= 30
        case .fewIngredients:
            return !recipe.ingredients.isEmpty && recipe.ingredients.count <= 5
        }
    }

    /// Recipes from `all` that satisfy this collection's rule.
    func recipes(from all: [RecipeModel]) -> [RecipeModel] {
        all.filter { matches($0) }
    }
}
