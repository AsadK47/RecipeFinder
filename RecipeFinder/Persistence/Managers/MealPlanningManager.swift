import Combine
import Foundation

@MainActor
final class MealPlanningManager: ObservableObject {
    static let shared = MealPlanningManager()

    @Published private(set) var mealPlans: [MealPlanModel] = []
    
    private let saveKey = "mealPlansStorage"
    private let storage = UserScopedStorage.shared
    
    private init() {
        loadMealPlans()
    }

    func reloadForCurrentUser() {
        loadMealPlans()
    }
    
    func addMealPlan(_ mealPlan: MealPlanModel) {
        if let existingIndex = mealPlans.firstIndex(where: {
            Calendar.current.isDate($0.date, inSameDayAs: mealPlan.date) &&
            $0.mealTime == mealPlan.mealTime
        }) {
            mealPlans[existingIndex] = mealPlan
        } else {
            mealPlans.append(mealPlan)
        }
        
        HapticManager.shared.medium()
        saveMealPlans()
    }
    
    func updateMealPlan(_ mealPlan: MealPlanModel) {
        if let index = mealPlans.firstIndex(where: { $0.id == mealPlan.id }) {
            mealPlans[index] = mealPlan
            HapticManager.shared.light()
            saveMealPlans()
        }
    }
    
    func removeMealPlan(_ mealPlan: MealPlanModel) {
        mealPlans.removeAll { $0.id == mealPlan.id }
        HapticManager.shared.light()
        saveMealPlans()
    }
    
    func removeMealPlan(for date: Date, mealTime: MealTime) {
        mealPlans.removeAll {
            Calendar.current.isDate($0.date, inSameDayAs: date) &&
            $0.mealTime == mealTime
        }
        HapticManager.shared.light()
        saveMealPlans()
    }
    
    func toggleCompletion(_ mealPlan: MealPlanModel) {
        if let index = mealPlans.firstIndex(where: { $0.id == mealPlan.id }) {
            mealPlans[index].isCompleted.toggle()
            HapticManager.shared.light()
            saveMealPlans()
        }
    }
    
    func clearOldMealPlans() {
        guard let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) else {
            return
        }
        mealPlans.removeAll { $0.date < oneWeekAgo }
        saveMealPlans()
    }
    
    func mealPlan(for date: Date, mealTime: MealTime) -> MealPlanModel? {
        mealPlans.first {
            Calendar.current.isDate($0.date, inSameDayAs: date) &&
            $0.mealTime == mealTime
        }
    }
    
    func mealPlans(for date: Date) -> [MealPlanModel] {
        mealPlans.filter {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }.sorted { $0.mealTime.sortOrder < $1.mealTime.sortOrder }
    }
    
    func hasMealPlans(for date: Date) -> Bool {
        mealPlans.contains {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }
    }
    
    func mealPlansForWeek(starting startDate: Date) -> WeeklyMealPlan {
        let start = Calendar.current.startOfDay(for: startDate)
        guard let end = Calendar.current.date(byAdding: .day, value: 7, to: start) else {
            return WeeklyMealPlan(startDate: start, meals: [])
        }
        
        let weekMeals = mealPlans.filter { meal in
            meal.date >= start && meal.date < end
        }
        
        return WeeklyMealPlan(startDate: start, meals: weekMeals)
    }
    
    var todaysMealPlans: [MealPlanModel] {
        mealPlans(for: Date())
    }
    
    var upcomingMealPlans: [MealPlanModel] {
        mealPlans.filter { $0.isUpcoming }
            .sorted { $0.date < $1.date }
    }
    
    var incompleteMealPlans: [MealPlanModel] {
        mealPlans.filter { !$0.isCompleted }
    }
    
    var mealPlansByDate: [(date: Date, meals: [MealPlanModel])] {
        let grouped = Dictionary(grouping: mealPlans) { meal in
            Calendar.current.startOfDay(for: meal.date)
        }
        
        return grouped.sorted { $0.key < $1.key }
            .map { (date: $0.key, meals: $0.value.sorted { $0.mealTime.sortOrder < $1.mealTime.sortOrder }) }
    }
    
    private func saveMealPlans() {
        if let encoded = try? JSONEncoder().encode(mealPlans) {
            storage.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadMealPlans() {
        if let data = storage.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([MealPlanModel].self, from: data) {
            mealPlans = decoded
        } else {
            mealPlans = []
        }
    }
}
