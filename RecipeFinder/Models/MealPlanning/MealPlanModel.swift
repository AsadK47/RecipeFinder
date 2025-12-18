import Foundation

/// Represents a planned meal for a specific date and time
struct MealPlanModel: Identifiable, Codable, Hashable {
    var id: UUID
    var recipeId: UUID
    var recipeName: String
    var date: Date
    var mealTime: MealTime
    var servings: Int
    var notes: String?
    var isCompleted: Bool
    var createdDate: Date
    
    init(
        id: UUID = UUID(),
        recipeId: UUID,
        recipeName: String,
        date: Date,
        mealTime: MealTime,
        servings: Int = 4,
        notes: String? = nil,
        isCompleted: Bool = false,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.recipeId = recipeId
        self.recipeName = recipeName
        self.date = date
        self.mealTime = mealTime
        self.servings = servings
        self.notes = notes
        self.isCompleted = isCompleted
        self.createdDate = createdDate
    }
    
    /// Normalized date (start of day) for consistent comparisons
    var normalizedDate: Date {
        Calendar.current.startOfDay(for: date)
    }
    
    /// Whether this meal is today
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    /// Whether this meal is in the past
    var isPast: Bool {
        date < Date()
    }
    
    /// Whether this meal is upcoming (future but not today)
    var isUpcoming: Bool {
        !isToday && !isPast
    }
}

// MARK: - Meal Times

enum MealTime: String, Codable, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
    
    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "star.fill"
        }
    }
    
    /// Typical time range for this meal
    var timeRange: String {
        switch self {
        case .breakfast: return "Morning"
        case .lunch: return "Afternoon"
        case .dinner: return "Evening"
        case .snack: return "Anytime"
        }
    }
    
    /// Order for displaying meals throughout the day
    var sortOrder: Int {
        switch self {
        case .breakfast: return 0
        case .lunch: return 1
        case .dinner: return 2
        case .snack: return 3
        }
    }
}

// MARK: - Weekly Meal Plan Helper

struct WeeklyMealPlan: Identifiable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    var meals: [MealPlanModel]
    
    init(startDate: Date, meals: [MealPlanModel]) {
        self.startDate = Calendar.current.startOfDay(for: startDate)
        self.endDate = Calendar.current.date(byAdding: .day, value: 6, to: self.startDate)!
        self.meals = meals
    }
    
    /// Meals grouped by date
    var mealsByDay: [Date: [MealPlanModel]] {
        Dictionary(grouping: meals) { meal in
            Calendar.current.startOfDay(for: meal.date)
        }
    }
    
    /// Total number of planned meals this week
    var totalMealsPlanned: Int {
        meals.count
    }
    
    /// Number of completed meals this week
    var completedMealsCount: Int {
        meals.filter { $0.isCompleted }.count
    }
}

// MARK: - Sample Data

extension MealPlanModel {
    static let samples: [MealPlanModel] = [
        MealPlanModel(
            recipeId: UUID(),
            recipeName: "Pancakes",
            date: Date(),
            mealTime: .breakfast,
            servings: 2
        ),
        MealPlanModel(
            recipeId: UUID(),
            recipeName: "Caesar Salad",
            date: Date(),
            mealTime: .lunch,
            servings: 4
        ),
        MealPlanModel(
            recipeId: UUID(),
            recipeName: "Grilled Salmon",
            date: Date(),
            mealTime: .dinner,
            servings: 4
        ),
        MealPlanModel(
            recipeId: UUID(),
            recipeName: "Pasta Carbonara",
            date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
            mealTime: .dinner,
            servings: 4
        )
    ]
}
