import Foundation

struct MealPlanModel: Identifiable, Codable, Hashable {
    var id: UUID
    var recipeId: UUID
    var recipeName: String
    var date: Date
    var mealTime: MealTime
    var servings: Int
    var notes: String?
    var isCompleted: Bool
    var isRecurring: Bool
    var createdDate: Date

    // Explicit keys so isRecurring is encoded and decodes to false for JSON predating the field.
    private enum CodingKeys: String, CodingKey {
        case id, recipeId, recipeName, date, mealTime, servings, notes,
             isCompleted, isRecurring, createdDate
    }

    init(
        id: UUID = UUID(),
        recipeId: UUID,
        recipeName: String,
        date: Date,
        mealTime: MealTime,
        servings: Int = 4,
        notes: String? = nil,
        isCompleted: Bool = false,
        isRecurring: Bool = false,
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
        self.isRecurring = isRecurring
        self.createdDate = createdDate
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(UUID.self,     forKey: .id)
        recipeId    = try c.decode(UUID.self,     forKey: .recipeId)
        recipeName  = try c.decode(String.self,   forKey: .recipeName)
        date        = try c.decode(Date.self,     forKey: .date)
        mealTime    = try c.decode(MealTime.self, forKey: .mealTime)
        servings    = try c.decode(Int.self,      forKey: .servings)
        notes       = try c.decodeIfPresent(String.self, forKey: .notes)
        isCompleted = try c.decode(Bool.self,     forKey: .isCompleted)
        isRecurring = try c.decodeIfPresent(Bool.self, forKey: .isRecurring) ?? false
        createdDate = try c.decode(Date.self,     forKey: .createdDate)
    }
    
    var normalizedDate: Date {
        Calendar.current.startOfDay(for: date)
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var isPast: Bool {
        date < Date()
    }
    
    var isUpcoming: Bool {
        !isToday && !isPast
    }
}

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
    
    var timeRange: String {
        switch self {
        case .breakfast: return "Morning"
        case .lunch: return "Afternoon"
        case .dinner: return "Evening"
        case .snack: return "Anytime"
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .breakfast: return 0
        case .lunch: return 1
        case .dinner: return 2
        case .snack: return 3
        }
    }
}

struct WeeklyMealPlan: Identifiable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    var meals: [MealPlanModel]
    
    init(startDate: Date, meals: [MealPlanModel]) {
        self.startDate = Calendar.current.startOfDay(for: startDate)
        self.endDate = Calendar.current.date(byAdding: .day, value: 6, to: self.startDate) ?? self.startDate
        self.meals = meals
    }
    
    var mealsByDay: [Date: [MealPlanModel]] {
        Dictionary(grouping: meals) { meal in
            Calendar.current.startOfDay(for: meal.date)
        }
    }
    
    var totalMealsPlanned: Int {
        meals.count
    }
    
    var completedMealsCount: Int {
        meals.filter { $0.isCompleted }.count
    }
}

/// Aggregated weekly shopping needs; ingredient names are normalized and merged, quantity = planned meals using each.
struct WeekShoppingSummary: Equatable {
    struct Item: Equatable {
        let name: String
        let quantity: Int
    }

    let items: [Item]
    /// Planned meals whose recipe was found and contributed ingredients.
    let mealsCovered: Int
    /// Recipe names planned this week that no longer exist in the collection.
    let missingRecipeNames: [String]

    var isEmpty: Bool {
        items.isEmpty && missingRecipeNames.isEmpty
    }
}

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
