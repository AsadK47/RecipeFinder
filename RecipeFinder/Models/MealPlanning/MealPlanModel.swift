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
    case brunch = "Brunch"
    case lunch = "Lunch"
    case snack = "Snack"
    case dinner = "Dinner"
    case lateNight = "Late Night"
    
    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .brunch: return "sun.max.fill"
        case .lunch: return "sun.min.fill"
        case .snack: return "star.fill"
        case .dinner: return "moon.stars.fill"
        case .lateNight: return "moon.fill"
        }
    }
    
    /// Typical time range for this meal
    var timeRange: String {
        switch self {
        case .breakfast: return "6:00 AM - 10:00 AM"
        case .brunch: return "10:00 AM - 12:00 PM"
        case .lunch: return "12:00 PM - 2:00 PM"
        case .snack: return "2:00 PM - 5:00 PM"
        case .dinner: return "5:00 PM - 9:00 PM"
        case .lateNight: return "9:00 PM - 12:00 AM"
        }
    }
    
    /// Order for displaying meals throughout the day
    var sortOrder: Int {
        switch self {
        case .breakfast: return 0
        case .brunch: return 1
        case .lunch: return 2
        case .snack: return 3
        case .dinner: return 4
        case .lateNight: return 5
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
