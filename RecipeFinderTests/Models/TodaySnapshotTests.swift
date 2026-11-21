import Testing
import Foundation
@testable import RecipeFinder

/// Characterisation of Today's refresh: the snapshot wires the stores into feed, week and progress exactly as TodayView
/// did inline.
@Suite struct TodaySnapshotTests {

    private let cal: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_GB")
        cal.firstWeekday = 2
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
        _ name: String, sample: Bool = false, cookCount: Int = 0, lastCooked: Date? = nil,
        ingredients: [String] = ["egg"], steps: [String] = ["Cook"], cookingTime: String = "10 min"
    ) -> RecipeModel {
        RecipeModel(
            name: name, category: "Main", difficulty: "Basic", prepTime: "5 min", cookingTime: cookingTime,
            baseServings: 2, ingredients: ingredients.map { Ingredient(baseQuantity: 1, unit: "", name: $0) },
            prePrepInstructions: [], instructions: steps, notes: "",
            isSampleRecipe: sample, cookCount: cookCount, lastCookedAt: lastCooked
        )
    }

    private func plan(_ recipe: RecipeModel, _ time: MealTime = .dinner, on offset: Int) -> MealPlanModel {
        MealPlanModel(recipeId: recipe.id, recipeName: recipe.name, date: day(offset), mealTime: time)
    }

    private func snapshot(
        _ recipes: [RecipeModel], plans: [MealPlanModel] = [], kitchen: [String] = [],
        streak: CookingStreak = .empty, unlocked: Set<String> = []
    ) -> TodaySnapshot {
        TodaySnapshot.make(
            recipes: recipes,
            plansOn: { date in plans.filter { $0.isOn(date, calendar: cal) } },
            kitchenItemNames: kitchen, inventoryItems: [], streak: streak, unlockedBadgeIDs: unlocked,
            now: now, calendar: cal
        )
    }

    // MARK: Snapshot

    @Test func eachPartMatchesBuildingItAlone() {
        let curry = recipe("Curry", cookCount: 2, lastCooked: day(-3))
        let stew = recipe("Stew", cookCount: 1, lastCooked: day(-40))
        let omelette = recipe("Omelette")
        let recipes = [curry, stew, omelette]
        let plans = [plan(curry, on: 0), plan(stew, .lunch, on: 3)]
        let streak = CookingStreak(currentWeeks: 2, cooksThisWeek: 1)

        let result = snapshot(recipes, plans: plans, kitchen: ["egg"], streak: streak, unlocked: ["head_chef"])

        let plansOn: (Date) -> [MealPlanModel] = { date in plans.filter { $0.isOn(date, calendar: cal) } }
        let feed = TodayFeed.make(
            recipes: recipes, todaysPlans: plansOn(now), kitchenItemNames: ["egg"],
            tomorrowsPlans: plansOn(day(1, hour: 15)), inventoryItems: [], now: now, calendar: cal
        )
        #expect(result.feed == feed)
        #expect(result.week == TodayWeek.make(
            recipes: recipes, plans: plans, tonightIDs: Set(feed.tonightOptions.map(\.recipe.id)), now: now, calendar: cal
        ))
        #expect(result.progress == TodayProgress.make(recipes: recipes, streak: streak, unlockedBadgeIDs: ["head_chef"]))
    }

    @Test func tomorrowsPlansReachPrepAhead() {
        let lamb = recipe("Lamb", steps: ["Marinate the lamb overnight.", "Roast."])
        let result = snapshot([lamb], plans: [plan(lamb, on: 1)])
        #expect(result.feed.prepAhead.map(\.recipe) == [lamb])
    }

    @Test func theWeekShowsPlansOnLaterDays() {
        let curry = recipe("Curry")
        let result = snapshot([curry], plans: [plan(curry, on: 4)])
        #expect(result.week.days.map(\.isPlanned) == [false, false, false, false, true, false, false])
        #expect(result.week.days[4].dinnerName == "Curry")
    }

    @Test func planTomorrowNeverOffersTonightsDish() {
        // Nothing planned: quick Curry is tonight's hero. Without the tonight IDs, Curry would win tomorrow by name.
        let curry = recipe("Curry"), pie = recipe("Pie", cookingTime: "2 hours")
        let result = snapshot([curry, pie])
        #expect(result.feed.hero?.recipe == curry)
        #expect(result.week.planTomorrow == pie)
    }
}
