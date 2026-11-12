import Testing
import Foundation
@testable import RecipeFinder

/// Today's "This week" strip (next seven days, planned or not) and the one-tap "Plan tomorrow" pick.
@Suite struct TodayWeekTests {

    private let cal: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_GB")
        cal.timeZone = TimeZone(identifier: "Europe/London") ?? .current
        return cal
    }()

    /// Thursday 12 Nov 2026, 15:00 London.
    private var now: Date {
        cal.date(from: DateComponents(year: 2026, month: 11, day: 12, hour: 15)) ?? Date()
    }

    private func day(_ offset: Int, hour: Int = 18) -> Date {
        let start = cal.startOfDay(for: now)
        let date = cal.date(byAdding: .day, value: offset, to: start) ?? start
        return cal.date(bySettingHour: hour, minute: 0, second: 0, of: date) ?? date
    }

    private func recipe(
        _ name: String, favourite: Bool = false, sample: Bool = false, cookCount: Int = 0, lastCooked: Date? = nil
    ) -> RecipeModel {
        RecipeModel(
            name: name, category: "Main", difficulty: "Basic", prepTime: "5 min", cookingTime: "10 min",
            baseServings: 2, ingredients: [Ingredient(baseQuantity: 1, unit: "", name: "egg")],
            prePrepInstructions: [], instructions: ["Cook"], notes: "",
            isFavorite: favourite, isSampleRecipe: sample, cookCount: cookCount, lastCookedAt: lastCooked
        )
    }

    private func plan(_ recipe: RecipeModel, _ time: MealTime, on offset: Int, completed: Bool = false) -> MealPlanModel {
        MealPlanModel(
            recipeId: recipe.id, recipeName: recipe.name, date: day(offset), mealTime: time, isCompleted: completed
        )
    }

    private func week(
        _ recipes: [RecipeModel], plans: [MealPlanModel] = [], tonight: Set<UUID> = []
    ) -> TodayWeek {
        TodayWeek.make(recipes: recipes, plans: plans, tonightIDs: tonight, now: now, calendar: cal)
    }

    // MARK: Strip

    @Test func stripIsTheNextSevenDaysStartingToday() {
        let result = week([])
        #expect(result.days.count == 7)
        #expect(result.days.map(\.date) == (0..<7).map { cal.startOfDay(for: day($0)) })
        #expect(result.days.map(\.isToday) == [true, false, false, false, false, false, false])
    }

    @Test func plannedDayListsItsMealsInMealOrder() {
        let curry = recipe("Curry"), porridge = recipe("Porridge")
        let result = week([curry, porridge], plans: [plan(curry, .dinner, on: 2), plan(porridge, .breakfast, on: 2)])
        #expect(result.days[2].mealTimes == [.breakfast, .dinner])
        #expect(result.days[2].dinnerName == "Curry")
        #expect(result.days[2].isPlanned)
        #expect(!result.days[1].isPlanned)
        #expect(result.days[1].dinnerName == nil)
    }

    @Test func cookedPlansStillMarkTheDayPlanned() {
        let curry = recipe("Curry")
        let result = week([curry], plans: [plan(curry, .dinner, on: 0, completed: true)])
        #expect(result.days[0].isPlanned)
    }

    @Test func plansOutsideTheSevenDaysAreLeftOut() {
        let curry = recipe("Curry")
        let result = week([curry], plans: [plan(curry, .dinner, on: -1), plan(curry, .dinner, on: 7)])
        #expect(result.days.allSatisfy { !$0.isPlanned })
    }

    @Test func lateNightPlanCountsForItsOwnDay() {
        let curry = recipe("Curry")
        let late = MealPlanModel(
            recipeId: curry.id, recipeName: curry.name, date: day(3, hour: 23), mealTime: .snack
        )
        let result = week([curry], plans: [late])
        #expect(result.days[3].mealTimes == [.snack])
        #expect(!result.days[4].isPlanned)
    }

    // MARK: Plan tomorrow

    @Test func planTomorrowPlansForTheDayAfterToday() {
        #expect(week([]).tomorrow == cal.startOfDay(for: day(1)))
    }

    @Test func tomorrowWithADinnerNeedsNoSuggestion() {
        let curry = recipe("Curry"), pasta = recipe("Pasta")
        let result = week([curry, pasta], plans: [plan(curry, .dinner, on: 1)])
        #expect(result.planTomorrow == nil)
    }

    @Test func tomorrowWithOnlyLunchStillGetsADinnerPick() {
        let salad = recipe("Salad"), pasta = recipe("Pasta")
        let result = week([salad, pasta], plans: [plan(salad, .lunch, on: 1)])
        #expect(result.planTomorrow?.name == "Pasta")
    }

    @Test func favouritesComeFirst() {
        let result = week([recipe("Apple pie", cookCount: 9), recipe("Zesty fish", favourite: true)])
        #expect(result.planTomorrow?.name == "Zesty fish")
    }

    @Test func ownRecipesBeatSamples() {
        let result = week([recipe("Apple pie", sample: true, cookCount: 9), recipe("Zesty fish")])
        #expect(result.planTomorrow?.name == "Zesty fish")
    }

    @Test func mostCookedThenNameBreaksTies() {
        let result = week([recipe("Apple pie"), recipe("Beef stew", cookCount: 2), recipe("Chilli", cookCount: 2)])
        #expect(result.planTomorrow?.name == "Beef stew")
    }

    @Test func pickSkipsTonightsOptionsAndThisWeeksPlans() {
        let tonight = recipe("Apple pie", favourite: true)
        let planned = recipe("Beef stew", favourite: true)
        let free = recipe("Chilli")
        let result = week([tonight, planned, free], plans: [plan(planned, .dinner, on: 4)], tonight: [tonight.id])
        #expect(result.planTomorrow?.name == "Chilli")
    }

    @Test func pickSkipsRecipesCookedInThePastWeek() {
        let recent = recipe("Apple pie", favourite: true, lastCooked: day(-6))
        let older = recipe("Beef stew", lastCooked: day(-8))
        let result = week([recent, older])
        #expect(result.planTomorrow?.name == "Beef stew")
    }

    @Test func noPickWhenEveryRecipeIsTaken() {
        let only = recipe("Apple pie")
        #expect(week([only], tonight: [only.id]).planTomorrow == nil)
        #expect(week([]).planTomorrow == nil)
    }
}
